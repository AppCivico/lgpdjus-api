package Lgpdjus::Controller::Maintenance;
use Mojo::Base 'Lgpdjus::Controller';
use Lgpdjus::Logger;
use Lgpdjus::Utils qw/is_test/;
use Scope::OnExit;

sub check_authorization {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        secret => {required => 1, type => 'Str', max_length => 100},
    );

    $c->reply_forbidden() unless $params->{secret} eq ($ENV{MAINTENANCE_SECRET} || die 'missing MAINTENANCE_SECRET');

    return 1;
}

# executa tarefas para manter o banco atualizado, mas não necessáriamente essenciais
# executar de 1 em 1 hora, por exemplo
sub housekeeping {
    my $c = shift;

    my $delete_rs = $c->schema->resultset('Cliente')->search(
        {
            status              => 'deleted_scheduled',
            deletion_started_at => undef,
            perform_delete_at   => {'<=' => \'now()'},
        },
        {
            columns => ['id'],
        }
    );
    my $minion = Lgpdjus::Minion->instance;
    while (my $r = $delete_rs->next) {

        my $job_id = $minion->enqueue(
            'delete_user',
            [
                $r->id,
            ] => {
                attempts => 5,
            }
        );

        slog_info('Adding job delete_user %s, job id %s', $r->id, $job_id);
        $r->update({deletion_started_at => \'now()'});
        $ENV{LAST_DELETE_JOB_ID} = $job_id;
    }
    if (!is_test()) {
        my $update_cep = $c->schema->resultset('Cliente')->search(
            {
                cep_estado => undef,
            },
            {
                columns => ['id'],
            }
        );
        while (my $r = $update_cep->next) {

            my $job_id = $minion->enqueue(
                'cliente_update_cep',
                [
                    $r->id,
                ] => {
                    attempts => 5,
                }
            );

            slog_info('Adding job cliente_update_cep %s, job id %s', $r->id, $job_id);
            $r->update({cep_estado => ''});
        }
    }

    return $c->render(json => {});
}

1;
