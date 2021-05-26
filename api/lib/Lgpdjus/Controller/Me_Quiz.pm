package Lgpdjus::Controller::Me_Quiz;
use Mojo::Base 'Lgpdjus::Controller';
use JSON;
use DateTime;

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

sub quiz_process_post {
    my $c = shift;

    my $user     = $c->stash('user');
    my $user_obj = $c->stash('user_obj');

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );
    my $session_id = delete $params->{session_id};

    $c->render_later, return 1 if $params->{timeout};

    my $quiz_session = $c->user_get_quiz_session(user_obj => $user_obj);

    if (!$quiz_session) {
        return $c->render(
            json => {
                error   => 'quiz_not_active',
                message => 'Nenhum quiz foi encontrado no momento. Reinicie o aplicativo.'
            },
            status => 400,
        );
    }

    if ($session_id != $quiz_session->{id}) {
        return $c->render(
            json => {
                error   => 'session_not_match',
                message => 'Sessão do quiz desta resposta não confere com a sessão atual. Reinicie o aplicativo.'
            },
            status => 400,
        );
    }

    my %return;
    $c->process_quiz_session(user => $user, user_obj => $user_obj, session => $quiz_session, params => $params);
    $return{quiz_session} = $c->stash('quiz_session');

    use JSON;
    $c->log->info(to_json($return{quiz_session}));

    return $c->render(
        json   => \%return,
        status => 200,
    );
}

sub cancel_quiz_post {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valids = $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );

    my $session = $user_obj->clientes_quiz_sessions->search(
        {
            id         => $valids->{session_id},
            can_delete => 1,
            deleted_at => undef,
        }
    )->next;
    if (!$session) {
        return $c->render(
            json => {
                error   => 'session_not_match',
                message => 'Sessão do quiz não encontrada.'
            },
            status => 400,
        );
    }

    $session->update({deleted_at => \'now()'});
    return $c->render(text => '', status => 204);
}

sub start_quiz_post {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valids = $c->validate_request_params(
        id => {required => 1, type => 'Str'},
    );

    my $questionnaire = $c->list_questionnaires(
        user_obj => $user_obj,
        id       => $valids->{id},
    );

    if (!$questionnaire) {
        return $c->render(
            json => {
                error   => 'quiz_not_active',
                message => 'Este questionário não está ativo para você neste momento.'
            },
            status => 400,
        );
    }

    my $quiz_session = $c->user_get_quiz_session(user_obj => $user_obj);

    if ($quiz_session) {
        return $c->render(
            json => {
                error   => 'session_already_exists',
                message => 'Já existe um questionário em andamento. Por favor, feche o aplicativo e abra novamente.'
            },
            status => 400,
        );
    }

    my %return;
    my $session = $c->create_quiz_session(user_obj => $user_obj, questionnaire => $questionnaire);
    use DDP;
    p $session;
    $c->load_quiz_session(session => $session, user_obj => $user_obj);

    $return{quiz_session} = $c->stash('quiz_session');

    $c->log->info(to_json($return{quiz_session}));

    return $c->render(
        json   => \%return,
        status => 200,
    );
}

1;
