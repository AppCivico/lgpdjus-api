package Lgpdjus::Controller::Login;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use DateTime;
use Digest::SHA qw/sha256_hex/;
use Digest::MD5 qw/md5_hex/;
use Lgpdjus::Logger;
use Lgpdjus::Utils qw/random_string is_test check_password_or_die/;
use MooseX::Types::Email qw/EmailAddress/;
use Encode qw/encode_utf8/;
use DateTime::Format::Pg;
use Crypt::JWT qw();
use Digest::SHA ();
use MIME::Base64;

my $max_email_errors_before_lock   = $ENV{MAX_EMAIL_ERRORS_BEFORE_LOCK}   || 15;
my $wait_seconds_to_account_unlock = $ENV{WAIT_SECONDS_TO_ACCOUNT_UNLOCK} || 86400;
my $ok_user_status                 = ['account_disabled', 'active', 'banned'];

$ENV{GOVBR_ENDPOINT}     ||= 'https://sso.staging.acesso.gov.br';
$ENV{GOVBR_CLIENT_ID}    ||= 'homol-lgpdjus-api.tjsc.jus.br';
$ENV{GOVBR_REDIRECT_URI} ||= 'https://homol-lgpdjus-api.tjsc.jus.br/gov-br-get-token';
$ENV{GOVBR_SCOPE}        ||= 'openid+email+profile+govbr_confiabilidades';
$ENV{GOVBR_SECRET}       ||= 'secret';
$ENV{GOVBR_JWK_URI}      ||= 'https://sso.staging.acesso.gov.br/jwk';
$ENV{GOVBR_SKIP_JWK}     ||= 0;

my $govauth = encode_base64($ENV{GOVBR_CLIENT_ID} . ':' . $ENV{GOVBR_SECRET}, '');

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        email       => {max_length => 200, required => 1, type => EmailAddress},
        senha       => {max_length => 200, required => 1, type => 'Str'},
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    my $email      = lc(delete $params->{email});
    my $senha_crua = delete $params->{senha};

    my $senha     = sha256_hex(encode_utf8($senha_crua));
    my $senha_md5 = md5_hex(encode_utf8($senha_crua));

    # limite de requests por segundo no IP
    # no maximo 3 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'login' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 60);

    # procura pelo email
    my $schema    = $c->schema;
    my $found_obj = $c->schema->resultset('Cliente')->search(
        {email => $email, status => {in => $ok_user_status}},
    )->next;
    my $found         = $found_obj ? {$found_obj->get_columns()} : undef;
    my $error_code    = 'notfound';
    my $error_message = 'Você ainda não possui cadastro conosco.';

    if ($found) {
        my $directus_id = $found->{id};
        if ($found->{login_status} eq 'NOK' && $found->{login_status_last_blocked_at}) {

            my $parsed = DateTime::Format::Pg->parse_datetime($found->{login_status_last_blocked_at});

            my $delta_secs = time() - $parsed->epoch;

            if ($delta_secs <= $wait_seconds_to_account_unlock) {
                die {
                    error   => 'login_status_nok',
                    message => 'Logon para este e-mail está suspenso temporariamente.',
                };

            }
            else {
                $found_obj->update(
                    {
                        login_status                 => 'OK',
                        login_status_last_blocked_at => ''
                    }
                );
            }

        }
        elsif ($found->{login_status} eq 'BLOCK') {
            die {
                error   => 'login_status_block',
                message => 'Logon para este e-mail está suspenso interminavelmente.',
            };
        }

        # confere a senha
        if (lc($senha) eq lc($found->{senha_sha256})) {
            goto LOGON;
        }
        elsif (lc($senha_md5) eq lc($found->{senha_sha256})) {
            $found_obj->update({senha_sha256 => $senha});
            goto LOGON;
        }
        else {
            my $total_errors = 1 + $c->schema->sum_login_errors(cliente_id => $directus_id);
            my $now          = DateTime->now->datetime(' ');
            $c->schema->resultset('LoginErro')->create(
                {
                    cliente_id => $directus_id,
                    remote_ip  => $remote_ip,
                    created_at => $now,
                }
            );

            if ($total_errors >= $max_email_errors_before_lock) {
                $found_obj->update(
                    {
                        login_status                 => 'NOK',
                        login_status_last_blocked_at => $now,
                    }
                );
            }
            $error_code    = 'wrongpassword';
            $error_message = 'E-mail ou senha inválida.';
            goto WRONG_PASS;
        }
    }

  WRONG_PASS:

    die {
        error   => $error_code,
        message => $error_message,
        field   => 'password',
        reason  => 'invalid'
    };

  LOGON:

    return &_logon($c, $remote_ip, $params->{app_version}, $found_obj);
}

sub _logon {
    my ($c, $remote_ip, $app_version, $found_obj) = @_;

    my $directus_id      = $found_obj->id;
    my $account_disabled = 0;

    # acertou a senha, mas esta suspenso
    if ($found_obj->status ne 'active') {
        if ($found_obj->status eq 'account_disabled') {
            $account_disabled++;
        }
        else {
            die {
                error   => 'ban',
                message => 'A conta suspensa.',
                field   => 'email',
                reason  => 'invalid'
            };
        }
    }

    $found_obj->update({qtde_login_senha_normal => \'qtde_login_senha_normal + 1'});

    # invalida todas as outras sessions
    if ($ENV{DELETE_PREVIOUS_SESSIONS}) {
        $c->schema->resultset('ClientesActiveSession')->search(
            {cliente_id => $directus_id},
        )->delete;
    }

    my $session = $c->schema->resultset('ClientesActiveSession')->create(
        {cliente_id => $directus_id},
    );
    my $session_id = $session->id;

    $c->schema->resultset('LoginLog')->create(
        {
            remote_ip   => $remote_ip,
            cliente_id  => $directus_id,
            app_version => $app_version,
            created_at  => DateTime->now->datetime(' '),
        }
    );

    # marca que o usuário esta fazendo um login, pra ser usado no GET /me pra ignorar o quiz
    my $key = $ENV{REDIS_NS} . 'is_during_login:' . $directus_id;
    $c->kv->redis->setex($key, 120, '1');

    $c->render(
        json => {
            (
                $account_disabled
                ? (
                    account_disabled => 1,
                  )
                : ()
            ),
            session => $c->encode_jwt(
                {
                    ses => $session_id,
                    typ => 'usr'
                }
            ),
            (is_test() ? (_test_only_id => $directus_id) : ()),
        },
        status => 200,
    );
}

sub govbr_status_get {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        token => {max_length => 800, required => 1, type => 'Str', min_length => 30},
    );

    # limite de requests por segundo no IP
    # no maximo 3 request por segundo
    # 100 por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'login' . substr($remote_ip, 0, 18));
    #$c->apply_request_per_second_limit(3,   1);
    #$c->apply_request_per_second_limit(100, 60);

    my $decoded_id;

    my $state = eval { $c->decode_jwt($params->{token}); };
    if (!$state) {
        die {
            error   => 'govbr_expired_token',
            message => 'Tempo da sessão do GovBr expirado, feche o aplicativo e comece novamente o fluxo de login.',
        };
    }
    if ($state->{typ} ne 'govbr') {
        die {
            error   => 'govbr_invalid_token',
            message => 'tipo do token inválido, não é do govbr!',
        };
    }
    $decoded_id = $state->{id};

    my $session = $c->schema->resultset('GovbrSessionLog')->find($decoded_id);
    die {
        error   => 'govbr_invalid_token',
        message => 'Tempo da sessão do GovBr não encontrado no banco de dados!',
    } unless $session;


    if ($session->access_token_json && !$session->logged_as_client_id) {
        my $found_obj = &_cria_conta_pelo_govbr($c, $session);

        return &_logon($c, $remote_ip, $state->{a}, $found_obj);
    }
    elsif ($session->access_token_json && $session->logged_as_client_id) {
        my $found_obj = $c->schema->resultset('Cliente')->search(
            {id => $session->logged_as_client_id, status => {in => $ok_user_status}},
        )->next;

        return &_logon($c, $remote_ip, $state->{a}, $found_obj);
    }

    $c->render(
        json => {
            waiting_govbr_login => 1,
        },
        status => 202,
    );
}

sub _cria_conta_pelo_govbr {
    my $c       = shift;
    my $session = shift;

    my $access_token = from_json($session->access_token_json);
    my $id_token     = from_json($session->id_token_json);

    my $found_obj = $c->schema->resultset('Cliente')->search(
        {cpf => $id_token->{'sub'}, status => {in => $ok_user_status}},
    )->next;
    return $found_obj if $found_obj;

    my $row = $c->schema->resultset('Cliente')->create(
        {
            email           => $id_token->{email} || 'sem-email' . $id_token->{'sub'} . '@example.com',
            nome_completo   => $id_token->{'name'},              # deixa do jeito que o usuario digitou
            cpf             => $id_token->{'sub'},
            senha_sha256    => '',
            apelido         => $id_token->{'name'},
            status          => 'active',
            created_on      => \'NOW()',
            email_existente => $id_token->{email} ? '1' : '0',
            govbr_info      => to_json(
                {
                    govbr_session => $session->id,
                }
            ),
        }
    );

    $session->update({logged_as_client_id => $row->id});

    return $row;
}

sub govbr_post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );

    # limite de requests por segundo no IP
    # no maximo 30 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'login' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(30, 60);

    # Keep At 43 chars! PKCE (RFC 7636)!
    my $secret = random_string(43);

    my $session = $c->schema->resultset('GovbrSessionLog')->create(
        {external_secret => $secret},
    );

    my $now   = time();
    my $exp   = $now + 3600;
    my $nonce = random_string(10);
    my $state = $c->encode_jwt(
        {
            id  => $session->id,
            typ => 'govbr',
            exp => $exp,
            a   => $params->{app_version},
        }
    );

    my $url = Mojo::URL->new($ENV{GOVBR_ENDPOINT} . '/authorize');

    my $code_challenge = Digest::SHA::sha256_base64($secret);
    $code_challenge =~ tr[+/][-_];

    $url->query(
        {
            response_type         => 'code',
            client_id             => $ENV{GOVBR_CLIENT_ID},
            scope                 => $ENV{GOVBR_SCOPE},
            redirect_uri          => $ENV{GOVBR_REDIRECT_URI},
            'state'               => $state,
            code_challenge        => $code_challenge,
            code_challenge_method => 'S256',
            nonce                 => $nonce,
        }
    );

    my $response = {
        now         => $now,
        expires_at  => $exp,
        tmp_session => $state,
        link        => $url->to_string(),
    };

    $c->log->info('new session for login via govbr: ' . to_json($response));

    $c->render(
        json   => $response,
        status => 200,
    );
}

sub govbr_get_token {
    my $c = shift;

    my $params = $c->validate_request_params(
        'code'  => {max_length => 800, required => 1, type => 'Str', min_length => 1},
        'state' => {max_length => 800, required => 1, type => 'Str', min_length => 30},
    );
    use DDP;
    p $params;

    my $state = eval { $c->decode_jwt($params->{'state'}); };
    use DDP;
    p $state;
    if (!$state || $state->{typ} ne 'govbr') {
        return $c->render(
            text   => 'Erro ao validar sessão do GovBr, feche o aplicativo e comece novamente.',
            status => 400,
        );
    }
    my $session = $c->schema->resultset('GovbrSessionLog')->find($state->{id});
    die {
        error   => 'govbr_invalid_token',
        message => 'Erro ao buscar sessão, feche o aplicativo e comece novamente.',
    } unless $session;


    my $success_url = $ENV{GOVBR_SUCESS_URL} || '/?message=retorne-ao-app';

    my $url = Mojo::URL->new($ENV{GOVBR_ENDPOINT} . '/token');
    $c->render_later();
    $c->log->info('Checking token on ' . $ENV{GOVBR_ENDPOINT});
    $c->ua->post_p(
        $url->to_string() => {'Authorization' => 'Basic ' . $govauth},
        form              => {
            code          => $params->{code},
            redirect_uri  => $ENV{GOVBR_REDIRECT_URI},
            code_verifier => $session->external_secret,
            grant_type    => 'authorization_code',
        }
    )->then(
        sub {
            my $tx   = shift;
            my $json = $tx->result->json;

            if (!$json->{access_token} || !$json->{id_token}) {
                $c->log->info("Faltando campos na resposta GovBR: " . $tx->result->to_string());
                return $c->render(
                    text   => 'Erro ao consultar serviço do GovBR',
                    status => 500,
                );
            }

            my $keylist = &get_jwk_kids($c, $ENV{GOVBR_JWK_URI});
            my $access_token;
            my $id_token;

            if ($ENV{GOVBR_SKIP_JWK}) {
                eval {
                    $access_token = Crypt::JWT::decode_jwt(
                        token            => $json->{access_token}, kid_keys => $keylist,
                        ignore_signature => 1
                    );
                    $id_token
                      = Crypt::JWT::decode_jwt(token => $json->{id_token}, kid_keys => $keylist, ignore_signature => 1);
                };
                if ($@) {
                    return $c->render(text => 'Erro ' . $@, status => 500,);
                }
            }
            else {
                eval {
                    $access_token = Crypt::JWT::decode_jwt(token => $json->{access_token}, kid_keys => $keylist);
                    $id_token     = Crypt::JWT::decode_jwt(token => $json->{id_token},     kid_keys => $keylist);
                };
                if (!$access_token) {
                    &drop_cache_jwk_kids($c, $ENV{GOVBR_JWK_URI});
                    my $keylist = &get_jwk_kids($c, $ENV{GOVBR_JWK_URI});
                    eval {
                        $access_token = Crypt::JWT::decode_jwt(token => $json->{access_token}, kid_keys => $keylist);
                        $id_token     = Crypt::JWT::decode_jwt(token => $json->{id_token},     kid_keys => $keylist);
                    };
                }

            }

            if (!$access_token || !$id_token) {
                $c->log->info("JWT não bate com JWK: " . $tx->result->to_string());
                return $c->render(
                    text   => 'Erro ao consultar serviço do GovBR',
                    status => 500,
                );
            }

            my $found_obj = $c->schema->resultset('Cliente')->search(
                {cpf => $id_token->{sub}},
            )->next;

            $session->update(
                {
                    logged_as_client_id => $found_obj ? $found_obj->id : undef,
                    id_token_json       => to_json($id_token),
                    access_token_json   => to_json($access_token),
                    id_token            => $json->{id_token},
                    access_token        => $json->{access_token},
                }
            );

            $c->redirect_to($success_url);
        }
    )->catch(
        sub {
            my $err = shift;
            $c->log->info($err);
            $c->render(
                text   => 'Erro ao consultar serviço do GovBR',
                status => 500,
            );
        }
    );
}


sub get_jwk_kids {
    my ($c, $url) = @_;

    return $c->kv->redis_get_cached_or_execute(
        $url,
        86400,    # 24 hours
        sub {
            my $result = $c->ua->get($url)->result;
            my $json   = $result->json;

            die "invalid response: " . $result->to_string() if !$json || !$json->{keys} || ref $json->{keys} ne 'ARRAY';
            return $json;
        }
    );
}

sub drop_cache_jwk_kids {
    my ($c, $url) = @_;

    my $ttl = $c->kv->redis_ttl($url);

    # apaga se tiver mais de 1min apenas
    if ($ttl > 60) {
        $c->kv->redis_del($url);
    }
}

1;
