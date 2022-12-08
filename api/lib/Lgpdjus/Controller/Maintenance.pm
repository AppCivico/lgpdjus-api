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

    die {
        error   => 'permission_denied',
        message => 'Você não tem a permissão para este recurso.',
        status  => 403,
    } unless $params->{secret} eq ($ENV{MAINTENANCE_SECRET} || die 'missing MAINTENANCE_SECRET');

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

    return $c->render(json => {});
}

sub housekeepingdb {
    my $c = shift;

    my $pong = $c->kv->redis->ping();
    return $c->render(json => {error => 'redis não respondeu pong'}, status => 400) unless $pong eq 'PONG';

    my $exists = $c->schema->resultset('Configuraco')->next;
    return $c->render(json => {error => 'faltando linha na tabela de configuração'}, status => 400) unless $exists;

    my ($failed_jobs) = $c->schema->storage->dbh->selectrow_array(
        <<'SQL_QUERY', undef,
        select count(1) from minion_jobs where state='failed';
SQL_QUERY
    );
    return $c->render(json => {error => 'há jobs com erro no minion'}, status => 400) if $failed_jobs > 0;

    my ($failed_emails) = $c->schema->storage->dbh->selectrow_array(
        <<'SQL_QUERY', undef,
        select count(1) from emaildb_queue where errmsg is not null;
SQL_QUERY
    );
    return $c->render(json => {error => 'há emails com erro na tabela emaildb_queue'}, status => 400)
      if $failed_emails > 0;

    return $c->render(text => 'all-good');
}

1;
