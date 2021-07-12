package Lgpdjus::Controller::SignUp;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use Scope::OnExit;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Lgpdjus::Logger;
use Lgpdjus::Utils qw/random_string random_string_from is_test check_password_or_die/;

use Crypt::PRNG qw(random_bytes);
use Lgpdjus::Types qw/CEP CPF DateStr Genero Nome/;
use MooseX::Types::Email qw/EmailAddress/;
use Text::Unaccent::PurePerl qw(unac_string);
use Encode qw/encode_utf8/;
my $max_errors_in_24h = $ENV{MAX_CPF_ERRORS_IN_24H} || 20;


sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        dry => {required => 1, type => 'Int'},
    );
    my $dry = $params->{dry};

    $c->validate_request_params(
        nome_completo => {max_length => 200, required => 1, type => Nome, min_length => 5},
        cpf           => {required   => 1,   type     => CPF},

        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    if (!$dry) {
        $c->validate_request_params(
            email   => {max_length => 200, required => 1, type => EmailAddress},
            apelido => {max_length => 40,  required => 1, type => 'Str', min_length => 2},
            senha   => {max_length => 200, required => 1, type => 'Str'},
        );

        check_password_or_die($params->{senha});
    }

    $params->{cpf} =~ s/[^\d]//ga;

    my $cpf   = delete $params->{cpf};
    my $email = $dry ? '' : lc(delete $params->{email});

    # limite de requests por segundo no IP
    # no maximo 3 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 60);

    my $lock = "email:$email";
    $c->kv()->lock_and_wait($lock);
    on_scope_exit { $c->kv()->unlock($lock) };

    # email deve ser unico
    my $schema = $c->schema;
    my $found  = $email ? $c->schema->resultset('Cliente')->search({email => $email})->next : undef;
    if ($found) {
        die {
            error   => 'email_already_exists',
            message =>
              'E-mail já possui uma conta. Por favor, faça o o login, ou utilize a função "Esqueci minha senha".',
            field  => 'email',
            reason => 'duplicate'
        };
    }

    my $lock2 = "cpf:$cpf";
    $c->kv()->lock_and_wait($lock2);
    on_scope_exit { $c->kv()->unlock($lock2) };

    # cpf ja existe
    $found = $c->schema->resultset('Cliente')->search({cpf => $cpf})->next;
    if ($found) {
        die {
            error   => 'cpf_already_exists',
            message =>
              'Este CPF já possui uma conta. Entre em contato com o suporte caso não lembre do e-mail utilizado.',
            field  => 'cpf',
            reason => 'duplicate'
        };
    }

    if ($dry) {
        return $c->render(
            json   => {continue => 1},
            status => 200,
        );
    }

    my $row = $c->schema->resultset('Cliente')->create(
        {
            email         => $email,
            nome_completo => $params->{nome_completo},                    # deixa do jeito que o usuario digitou
            cpf           => $cpf,
            senha_sha256  => sha256_hex(encode_utf8($params->{senha})),
            (map { $_ => $params->{$_} || '' } qw/apelido/),
            status     => 'active',
            created_on => \'NOW()',
        }
    );
    my $directus_id = $row->id;
    die '$directus_id not defined' unless $directus_id;

    my $session = $c->schema->resultset('ClientesActiveSession')->create(
        {cliente_id => $directus_id},
    );
    my $session_id = $session->id;

    $c->schema->resultset('LoginLog')->create(
        {
            remote_ip   => $remote_ip,
            cliente_id  => $directus_id,
            app_version => $params->{app_version},
            created_at  => DateTime->now->datetime(' '),
        }
    );

    $c->minion->enqueue(
        'cliente_update_cep',
        [$directus_id] => {
            attempts => 5,
        }
    );
    $ENV{LAST_PDF_JOB_ID} = $c->minion->enqueue(
        'generate_pdf_and_blockchain',
        [
            'account',
            $directus_id,
            'cliente_send_email',
            {
                template => 'signup',
            }
        ] => {
            attempts => 5,
        }
    );

    $c->render(
        json => {
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

1;
