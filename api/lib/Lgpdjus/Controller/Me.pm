package Lgpdjus::Controller::Me;
use Mojo::Base 'Lgpdjus::Controller';
use Carp;
use DateTime;
use JSON;
use Lgpdjus::Types qw/IntList Raca/;
use MooseX::Types::Email qw/EmailAddress/;
use Digest::SHA qw/sha256_hex/;
use Scope::OnExit;
use Lgpdjus::Controller::Logout;
use Lgpdjus::Utils qw/check_password_or_die/;

sub check_and_load {
    my $c = shift;

    die 'missing user_id' unless $c->stash('user_id');
    return 1 if $c->stash('user_obj');

    my $user = $c->schema->resultset('Cliente')->search(
        {
            'id'     => $c->stash('user_id'),
            'status' => 'active',
        },
    )->next;

    $c->reply_not_found() unless $user;
    $c->stash('user_obj' => $user);
    $c->stash('user'     => {$user->get_columns});    # nao pode ser o inflacted
                                                      # MANTER ATUALIZADO EMBAIXO EM "ATUALIZAR AQUI"

    $user->update_activity();

    return 1;
}

sub me_find {
    my $c = shift;

    my %extra;
    my $user_obj = $c->stash('user_obj');

    my $modules = $user_obj->access_modules_as_config;

    my $quiz_session = $c->user_get_quiz_session(user_obj => $user_obj);

    if ($quiz_session) {

        # remove acesso a tudo, o usuario deve completar o quiz
        $modules = [
            {
                code => 'quiz',
                meta => {}
            }
        ];

        $c->load_quiz_session(session => $quiz_session, user_obj => $user_obj);

        $extra{quiz_session} = $c->stash('quiz_session');

        $c->log->info(to_json($extra{quiz_session}));
    }

    my $user = $c->stash('user');
    return $c->render(
        json => {
            user_profile => {
                (map { $_ => $user->{$_} || '' } (qw/email apelido nome_completo cpf/)),

                nome_social => '',
                genero      => 'NaoInformado',
                dt_nasc     => '2000-01-01',
                cep         => '00000-000',

                account_verified             => $user->{account_verified}             ? 1 : 0,
                account_verification_pending => $user->{account_verification_pending} ? 1 : 0,

            },

            modules => $modules,
            %extra
        },
        status => 200,
    );
}

sub me_update {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');
    my $valid    = $c->validate_request_params(

        apelido => {max_length => 40,  required => 0, type => 'Str', min_length => 2},
        senha   => {max_length => 200, required => 0, type => 'Str'},
        email   => {max_length => 200, required => 0, type => EmailAddress},
    );

    if ((exists $valid->{email} && $valid->{email}) || (exists $valid->{senha} && $valid->{senha})) {
        my $data = $c->validate_request_params(
            senha_atual => {max_length => 200, required => 1, type => 'Str'},
        );

        my $senha = sha256_hex($data->{senha_atual});
        if (lc($senha) ne lc($user_obj->senha_sha256())) {
            $c->reply_invalid_param('Senha atual não confere.', 'form_error', 'senha_atual');
        }
    }

    if (exists $valid->{email}) {
        my $email = lc(delete $valid->{email});
        my $lock  = "email:$email";
        $c->kv()->lock_and_wait($lock);
        on_scope_exit { $c->kv()->unlock($lock) };

        my $in_use = $c->schema->resultset('Cliente')->search(
            {
                'id'    => {'!=' => $user_obj->id},
                'email' => $email,
            }
        )->count > 0;
        $c->reply_invalid_param('O e-mail já está em uso em outra conta', 'form_error', 'email', 'duplicate')
          if $in_use;
        $user_obj->update({email => $email});
    }

    if (exists $valid->{senha} && $valid->{senha}) {
        check_password_or_die($valid->{senha});
        $valid->{senha_sha256} = lc(sha256_hex(delete $valid->{senha}));
    }

    if (keys %$valid > 0) {
        $user_obj->update($valid);
    }

    $user_obj->discard_changes;
    $c->stash('user' => {$user_obj->get_columns});    # ATUALIZAR AQUI

    &me_find($c);
}

sub me_delete_text {
    my $c = shift;

    return $c->render(
        json => {
            text =>
              "<p>O seu perfil será desativado por 30 dias, após este período seus dados serão completamente excluídos.<br/></p>"
              . "<p>Caso entre novamente no aplicativo antes deste período, você ainda poderá reativar o perfil.<p>"
        },
        status => 200,
    );
}

sub me_unread_notif_count {
    my $c     = shift;
    my $count = $c->user_notifications_unread_count($c->stash('user_id'));

    return $c->render(
        json   => {count => $count},
        status => 200,
    );
}

sub me_notifications {
    my $c     = shift;
    my $valid = $c->validate_request_params(
        next_page => {max_length => 9999, required => 0, type => 'Str'},
        rows      => {required   => 0,    type     => 'Int'},
    );

    my $user_obj = $c->stash('user_obj');

    return $c->render(
        json => $c->user_notifications(
            user_obj => $user_obj,
            %$valid,
        ),
        status => 200,
    );
}

sub me_delete {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        senha_atual => {max_length => 200, required => 1, type => 'Str', min_length => 6},
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );

    my $senha = sha256_hex($valid->{senha_atual});
    if (lc($senha) ne lc($user_obj->senha_sha256())) {
        $c->reply_invalid_param('Senha atual não confere.', 'form_error', 'senha_atual');
    }

    my $remote_ip = $c->remote_addr();

    $c->schema->txn_do(
        sub {
            $user_obj->update(
                {
                    status                 => 'deleted_scheduled',
                    deleted_scheduled_meta => to_json(
                        {
                            epoch       => time(),
                            app_version => $valid->{app_version},
                            ip          => $remote_ip,
                            delete      => 1,
                            (
                                $user_obj->deleted_scheduled_meta()
                                ? (previous => from_json($user_obj->deleted_scheduled_meta() || '{}'))
                                : ()
                            ),
                        }
                    ),
                    perform_delete_at => \"NOW() + '30 DAY'"
                }
            );

            my $email_db = $c->schema->resultset('EmaildbQueue')->create(
                {
                    config_id => 1,
                    template  => 'account_deletion.html',
                    to        => $user_obj->email,
                    subject   => 'LGPDjus - Remoção de conta',
                    variables => to_json(
                        {
                            nome_completo => $user_obj->nome_completo,
                            remote_ip     => $remote_ip,
                            app_version   => $valid->{app_version},
                            email         => $user_obj->email,
                            cpf           => $user_obj->cpf,
                        }
                    ),
                }
            );
            die 'missing id' unless $email_db;

            # apaga todas as sessions ativas (pode ter mais de uma dependendo da configuracao)
            $user_obj->clientes_active_sessions->delete;
        }
    );

    # faz logout da session atual (apaga no cache, etc)
    &Lgpdjus::Controller::Logout::logout_post($c);
}

sub me_reactivate {
    my $c = shift;

    my $valid = $c->validate_request_params(
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    my $user_obj = $c->schema->resultset('Cliente')->search(
        {
            'id'           => $c->stash('user_id'),
            'status'       => 'deleted_scheduled',
            'login_status' => 'OK',
        },
    )->next;

    $c->reply_not_found() unless $user_obj;
    my $remote_ip = $c->remote_addr();

    $c->schema->txn_do(
        sub {
            $user_obj->update(
                {
                    status                 => 'active',
                    deleted_scheduled_meta => to_json(
                        {
                            epoch       => time(),
                            app_version => $valid->{app_version},
                            ip          => $remote_ip,
                            reactivate  => 1,
                            previous    => from_json($user_obj->deleted_scheduled_meta() || '{}'),
                        }
                    ),
                    perform_delete_at => undef,
                }
            );

            my $email_db = $c->schema->resultset('EmaildbQueue')->create(
                {
                    config_id => 1,
                    template  => 'account_reactivate.html',
                    to        => $user_obj->email,
                    subject   => 'LGPDjus - Reativação de conta',
                    variables => to_json(
                        {
                            nome_completo => $user_obj->nome_completo,
                            remote_ip     => $remote_ip,
                            app_version   => $valid->{app_version},
                            email         => $user_obj->email,
                            cpf           => $user_obj->cpf
                        }
                    ),
                }
            );
            die 'missing id' unless $email_db;
        }
    );

    return $c->render(text => '', status => 204,);
}


1;
