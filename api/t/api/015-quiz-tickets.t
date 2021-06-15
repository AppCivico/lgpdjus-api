use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;

my $tomorrow = DateTime->today(time_zone => 'America/Sao_Paulo')->add(days => 1)->dmy('/');
use Lgpdjus::Test;
my $t = test_instance;
my $json;

my ($session, $user_id) = get_user_session('43866555490');
my $cliente = get_schema->resultset('Cliente')->find($user_id);
on_scope_exit { user_cleanup(user_id => $cliente->id); };

is app->schema->resultset('Questionnaire')->search(
    {
        'is_test' => 1,
        'active'  => 1,
        'code'    => {'!=' => 'verify_account'},
    }
  )->count,
  2,
  '2 active questionnaires to tests';
is app->schema->resultset('Questionnaire')->search(
    {
        'is_test' => 1,
        'active'  => 1,
        'code'    => 'verify_account',
    }
  )->count,
  1,
  '1 active questionnaire to verify account';

app->schema->resultset('ClientesQuizSession')->search(
    {
        'cliente_id' => $user_id,
    }
)->delete;

$ENV{QUESTIONNAIRE_ICON_BASE_URL} = '';
my $cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->tx->res->json;
$cliente->update({account_verified => 0});

$json = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->json_hasnt('/quiz_session/session_id')->tx->res->json;

ok((grep { $_->{code} eq 'quiz' } $json->{modules}->@*)    ? 0 : 1, 'has NO quiz');
ok((grep { $_->{code} eq 'tickets' } $json->{modules}->@*) ? 1 : 0, 'has tickets');

$t->get_ok(
    '/available-tickets-timeline',
  )->status_is(200, '200 tickets timeline')    #
  ->json_is('/rows/0/id',                             '5')                                          #
  ->json_is('/rows/0/type',                           'questionnaire')                              #
  ->json_is('/rows/0/header',                         'cat short 5')                                #
  ->json_is('/rows/0/appbar_header',                  'label 5')                                    #
  ->json_is('/rows/0/body',                           'short_text 5', 'came first, order is ok')    #
  ->json_is('/rows/0/confirmation_screen/body',       'body 5')                                     #
  ->json_is('/rows/0/confirmation_screen/button',     'start button 5')                             #
  ->json_is('/rows/0/confirmation_screen/legal_info', '', 'empty, not null')                        #
  ->json_is('/rows/0/confirmation_screen/title',      'title 5')                                    #

  ->json_is('/rows/1/id',                             '4')                                          #
  ->json_is('/rows/1/type',                           'questionnaire')                              #
  ->json_is('/rows/1/header',                         'cat short 4')                                #
  ->json_is('/rows/1/appbar_header',                  'label 4')                                    #
  ->json_is('/rows/1/body',                           'short_text 4')                               #
  ->json_is('/rows/1/confirmation_screen/body',       'body 4')                                     #
  ->json_is('/rows/1/confirmation_screen/button',     'start button 4')                             #
  ->json_is('/rows/1/confirmation_screen/legal_info', 'legal info 4')                               #
  ->json_is('/rows/1/confirmation_screen/title',      'title 4')                                    #
  ->json_is('/rows/2/id',                             undef, 'id do quiz de verificar conta nao vem');

$t->post_ok(
    '/me/quiz/start',
    {'x-api-key' => $session},
    form => {id => 'verify_account'}    # iniciando form 7 via code
)->status_is(200, '200 start session verify_account')
  ->json_has('/quiz_session/current_msgs/0/content', 'verify_account question 1')    #
  ->json_is('/quiz_session/can_delete', 1, 'can delete');

is trace_grep('clientes_quiz_session:created_questionnaire_id'), 7, 'created questionnaire 7';

is $cliente->discard_changes->account_verification_pending, 1, 'account_verification_pending was updated';

$t->post_ok(
    '/me/quiz/start',
    {'x-api-key' => $session},
    form => {id => 'verify_account'}
)->status_is(400, '400 start session if account_verification_pending is true')->json_is('/error', 'quiz_in_progress');

$cliente->update({account_verified => 1, account_verification_pending => 0});
$t->post_ok(
    '/me/quiz/start',
    {'x-api-key' => $session},
    form => {id => 'verify_account'}
)->status_is(400, '400 start session verify_account when already verified')->json_is('/error', 'quiz_not_active');

$t->post_ok(
    '/me/quiz/start',
    {'x-api-key' => $session},
    form => {id => 'not_existing_code'}
)->status_is(400, '400 code does not exists')->json_is('/error', 'not_found');


ok my $session_id = trace_grep('clientes_quiz_session:created'), 'session was created';
$t->post_ok(
    '/me/quiz/cancel',
    {'x-api-key' => $session},
    form => {session_id => $session_id}    # cancelando form 7
)->status_is(204, '204 cancelled');

trace_popall;
$t->post_ok(
    '/me/quiz/start',
    {'x-api-key' => $session},
    form => {id => 4}                      # iniciando form 4
)->status_is(200, '200 start session 4')->json_has('/quiz_session/current_msgs/0/content', 'intro1');
$session_id = trace_grep('clientes_quiz_session:created');

$cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->json_is('/quiz_session/session_id', $session_id, 'session loaded')->tx->res->json;
ok((grep { $_->{code} eq 'quiz' } $cadastro->{modules}->@*)    ? 1 : 0, 'has quiz');
ok((grep { $_->{code} eq 'tickets' } $cadastro->{modules}->@*) ? 0 : 1, 'has NO tickets');

is trace_grep('clientes_quiz_session:loaded'), $session_id, 'same session was loaded';


my $first_session_id;
subtest_buffered 'Testar envio de campo boolean com valor invalido + interpolation de variaveis no intro' => sub {
    $first_session_id = $cadastro->{quiz_session}{session_id};
    my $field_ref = $cadastro->{quiz_session}{current_msgs}[-2]{ref};    # atenção, -2 por causa do appendix
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'X',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $first_msg        = $json->{quiz_session}{current_msgs}[0];
    my $second_msg       = $json->{quiz_session}{current_msgs}[1];
    my $third_msg        = $json->{quiz_session}{current_msgs}[2];
    my $before_input_msg = $json->{quiz_session}{current_msgs}[-1];
    my $input_msg        = $json->{quiz_session}{current_msgs}[-2];
    like $first_msg->{content}, qr/$field_ref.+deve ser Y ou N/, "$field_ref nao pode ser X";
    is $first_msg->{style},     'error',                         'type is error';

    is $before_input_msg->{content}, 'appendix 1',             'has appendix before message';
    is $second_msg->{content},       'intro1',                 'question intro is working';
    is $third_msg->{content},        'HELLOQuiz UserName!',    'question intro interpolation is working';
    is $input_msg->{content},        'yesno question☺️⚠️👍👭🤗🤳', 'yesno question question is present';
};

my $choose_rand = rand;
subtest_buffered 'Seguindo fluxo ate o final usando caminho Y' => sub {
    my $field_ref = $cadastro->{quiz_session}{current_msgs}[-2]{ref};    # atençaõ, -2 por causa do appendix
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'Y',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;


    my $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{content}, 'question for YES', 'flow is working!';
    is $input_msg->{type},    'text',             'flow is working!';

    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id        => $cadastro->{quiz_session}{session_id},
            $input_msg->{ref} => $choose_rand,
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $db_session = app->schema->resultset('ClientesQuizSession')->search(
        {
            'id' => $cadastro->{quiz_session}{session_id},
        }
    )->next;
    is(from_json($db_session->responses)->{freetext}, $choose_rand, 'responses is updated with random text');
};

$ENV{PUBLIC_API_URL} = '';

my $media = $t->post_ok(
    '/me/media',
    {'x-api-key' => $session},
    form => {
        intention => 'quiz',
        media     => {file => "$RealBin/../data/small.png"}
    },

)->status_is(200)->tx->res->json;

my $ticket_id;
subtest_buffered 'group de questoes boolean' => sub {

    $json = $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    my $first_msg = $json->{quiz_session}{current_msgs}[0];
    my $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{content}, 'Question A', 'NO intro text';
    is $input_msg->{type},    'yesno',      'yesno type';

    my $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'N',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;
    is $json->{quiz_session}{progress_bar}, 2, 'progress is 0 + 2 (index of yesnogroup) question';

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];
    is $first_msg, $input_msg, 'just the new message, no intro [because yes-no group has no header]';

    is $input_msg->{type},    'yesno',      'yesno type';
    is $input_msg->{content}, 'Question B', 'yesno type';

    # respondendo a segunda (e ultima) boolean do grupo
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'Y',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;
    is $json->{quiz_session}{appbar_header}, 'label 4', 'has appbar_header';

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $first_msg->{type},    'displaytext',      'just a text';
    is $first_msg->{content}, 'displaytext flow', 'expected pass';

    is $input_msg->{type},      'yesno',                'is a yesno';
    is $input_msg->{content},   'customyesno question', 'customyesno question content';
    is $input_msg->{yes_label}, 'Yup!',                 'yeslabel for no value';
    is $input_msg->{no_label},  'Nope!',                'yeslabel for yes value';
    is $input_msg->{action},    undef,                  'yesno has no action';

    # respondendo a boolean customizada
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'Y',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{type},    'multiplechoices',          'is a multiplechoices';
    is $input_msg->{content}, 'multiple choices options', 'mc has content';
    is $input_msg->{options}[0]{display}, 'opção a', 'mc has options.0.display';
    is $input_msg->{options}[2]{display}, 'opção c', 'mc has options.2.display';
    is $input_msg->{options}[1]{index},   1,         'mc has options.1.index';

    # respondendo a multipĺe choices
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => '0,2',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{type},    'onlychoice',          'is a onlychoice';
    is $input_msg->{content}, 'only choice options', 'oc has content';
    is $input_msg->{options}[0]{display}, 'opção 1', 'oc has options.0.display';
    is $input_msg->{options}[2]{display}, 'opção 3', 'oc has options.2.display';
    is $input_msg->{options}[1]{index},   1,         'oc has options.1.index';

    # respondendo a only choice
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => '2',
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{type},    'photo_attachment', 'is a photo_attachment';
    is $input_msg->{content}, 'ponha o arquivo',  'button has content';
    is $input_msg->{label},   'anexar',           'botao tem label';
    is $input_msg->{action},  undef,              'photo_attachment has no action';

    # respondendo a segunda (e ultima) boolean do grupo
    $field_ref = $input_msg->{ref};
    $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 'foobar',
        }
    )->status_is(200)->json_has('/quiz_session')
      ->json_is('/quiz_session/current_msgs/0/content', 'upload foobar não é válido');

    trace_popall;
    $json = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => $media->{id},
        }
    )->status_is(200)->json_has('/quiz_session')->tx->res->json;
    ok $ticket_id = trace_grep('generate_ticket:new'), 'got a ticket';

    $first_msg = $json->{quiz_session}{current_msgs}[0];
    $input_msg = $json->{quiz_session}{current_msgs}[-1];

    is $input_msg->{type},    'button',        'is a button';
    is $input_msg->{content}, 'final',         'button has content';
    is $input_msg->{label},   'btn label fim', 'botao tem label';
    is $input_msg->{action},  'none',          'button action is none [btn-fim]';
    is $json->{quiz_session}{progress_bar}, 99, 'progress is 99 (saved on btn_fim) question';

    my $prev_msgs = $t->get_ok(
        '/me',
        {'x-api-key' => $session},
      )->status_is(200)->json_has('/quiz_session')    #
      ->json_is('/quiz_session/can_delete', 0, 'cannot delete anymore')    #
      ->tx->res->json->{quiz_session}{prev_msgs};

    is trace_grep('generate_ticket:load'), $ticket_id, 'same ticket returning on subsequent load.';

    my $load_as_image_response;
    foreach my $prev (@$prev_msgs) {
        if ($prev->{type} eq 'displaytext') {
            ok $prev->{content}, 'has content';
        }
        else {
            ok $prev->{display_response}, 'has display_response';
        }

        $load_as_image_response = $prev->{display_response} if $prev->{content} eq 'ponha o arquivo';
    }

    like $load_as_image_response, qr/media-download\/\?m=$media->{id}/, 'media id';
    is scalar @$prev_msgs, 12, '12 prev questions';

    ok my $session_id = $json->{quiz_session}{session_id}, 'has session id';

    # apertando o botao btn_fim
    $field_ref = $json->{quiz_session}{current_msgs}[-1]{ref};
    $json      = $t->post_ok(
        '/me/quiz',
        {'x-api-key' => $session},
        form => {
            session_id => $cadastro->{quiz_session}{session_id},
            $field_ref => 1,
        }
    )->status_is(200)->json_is('/quiz_session/finished', 1)
      ->json_is('/quiz_session/end_screen', "freetext=$choose_rand")->tx->res->json;

    my $session   = get_schema->resultset('ClientesQuizSession')->find($session_id);
    my $responses = from_json($session->responses);
    is $responses->{yesno_customlabel}, 'yes',   'yes value for custom label/value';
    is $responses->{btn_fim_action},    'none',  'no action btn_fim_action';
    is $responses->{yesno1},            'Y',     'Y for yesno1';
    is $responses->{groupq_1},          'N',     'N for groupq_1';
    is $responses->{mc},                '["a","c"]', 'a and c for mc';
    is $responses->{oc},                '3',     '3 for oc';
};


subtest_buffered 'list do ticket' => sub {

    $t->get_ok(
        '/tickets-timeline',
        {'x-api-key' => $session},
      )->status_is(200)    #
      ->json_is('/rows/0/type', 'header',   'row 1 is header')        #
      ->json_is('/rows/1/type', 'ticket',   'row 2 is ticket')        #
      ->json_is('/rows/1/id',   $ticket_id, 'ticket match created')
      ->json_like('/rows/1/content', qr/$tomorrow/, 'ticket match prazo');

    # mais recente pra mais antigos
    my $p1   = create_fake_ticket($cliente, 'pending',              1);
    my $p2   = create_fake_ticket($cliente, 'pending',              2);
    my $wait = create_fake_ticket($cliente, 'wait-additional-info', 3 * 86400);
    my $done = create_fake_ticket($cliente, 'done',                 5 * 86400);

    $t->get_ok(
        '/tickets-timeline',
        {'x-api-key' => $session},
        form => {rows => 2},
      )->status_is(200)    #
      ->json_is('/rows/1/type', 'ticket',   'row 3 is ticket')        #
      ->json_is('/rows/1/id',   $ticket_id, 'ticket match created')
      ->json_is('/rows/2/type', 'ticket',   'row 3 is ticket')        #
      ->json_is('/rows/2/id',   $p1->id,    'ticket most recent');

    $t->get_ok(
        '/tickets-timeline',
        {'x-api-key' => $session},
        form => {rows => 2, next_page => last_tx_json()->{next_page}},
      )->status_is(200)->json_is('/has_more', 1, 'has more')          #
      ->json_is('/rows/0/type', 'ticket',  'row 0 is ticket')         #
      ->json_is('/rows/0/id',   $p2->id,   'ticket match pending 2')  #
      ->json_is('/rows/1/type', 'ticket',  'row 1 is ticket')         #
      ->json_is('/rows/1/id',   $wait->id, 'ticket match waiting');

    $t->get_ok(
        '/tickets-timeline',
        {'x-api-key' => $session},
        form => {rows => 2, next_page => last_tx_json()->{next_page}},
      )->status_is(200)->json_is('/has_more', 0, 'end of page')       #
      ->json_is('/rows/0/type', 'ticket',  'row 0 is ticket')         #
      ->json_is('/rows/0/id',   $done->id, 'ticket match done')       #
      ->json_is('/rows/1',      undef,     'no more tickets');

    $t->get_ok(
        '/me/tickets/' . $wait->id,
        {'x-api-key' => $session}
      )->status_is(200)->json_like('/body', qr/Categoria da/, 'body ok')    #
      ->json_has('/id',          'has id')                                  #
      ->json_has('/meta/header', 'has header')                              #
      ->json_like('/responses/0/body', qr/necessária/, 'has response body') #
      ->json_has('/responses/0/id', 'has response id')                      #
      ->json_is('/responses/0/meta/can_reply', 1, 'has response can_reply');

    my $response_id = &last_tx_json()->{responses}[0]{id};

    $t->post_ok(
        '/me/tickets/' . $wait->id . '/reply',
        {'x-api-key' => $session},
        form => {response_id => $response_id + 1},
    )->status_is(400);

    $t->post_ok(
        '/me/tickets/' . $wait->id . '/reply',
        {'x-api-key' => $session},
        form => {
            response_id => $response_id,
            media_id    => $media->{id},
            content     => 'fooba>r',
        },
      )->status_is(200)->json_is('/responses/0/meta/can_reply', 0, 'cannot reply anymore')    #
      ->json_like('/responses/0/body', qr/fooba&gt;r/, 'response ok')                         #
      ->json_like('/responses/0/body', qr/<img src/,   'response has image')                  #
      ->json_like('/body',             qr/Pendente/,   'situação Pendente');
    $wait->discard_changes;
    is $wait->status, 'pending', 'new status is pending';

    &loggin_as_admin();

    $ENV{ADMIN_FILTER_CLIENTE_ID} = $cliente->id;

    subtest_buffered 'admin ticket listing' => sub {
        $t->get_ok(
            '/admin/tickets',
            form => {rows => 3, filter => 'all'}
          )->status_is(200, '200 listing admin tickets')    #
          ->json_is('/filter',        'all',     'no filtering')                                 #
          ->json_is('/has_more',      1,         'has more')                                     #
          ->json_is('/rows/0/id',     $done->id, 'first row is most recently created')           #
          ->json_is('/rows/0/status', 'done',    'done.status is done')                          #
          ->json_is('/rows/1/id',     $wait->id, 'wait.id match')                                #
          ->json_is('/rows/1/status', 'pending', 'wait.status is pending (already answered)')    #
          ->json_is('/rows/2/id',     $p2->id,   'p2.id match')                                  #
          ->json_is('/rows/2/status', 'pending', 'p2.status is pending');

        $t->get_ok(
            '/admin/tickets',
            form => {
                filter    => 'all',
                rows      => 3,
                next_page => last_tx_json->{next_page},
            }
          )->status_is(200, '200 listing admin tickets with pagination')                         #
          ->json_is('/has_more',  0,       'has more=false')                                     #
          ->json_is('/rows/0/id', $p1->id, 'p1.id match')                                        #
          ->json_is('/next_page', undef,   'next_page null');

        $t->get_ok(
            '/admin/tickets',
            {'accept' => 'text/html'}
        )->status_is(200, '200 list tickets as html')->content_like(qr/<html /, 'has html');
    };

    subtest_buffered 'ticket details' => sub {

        $t->get_ok(
            '/admin/tickets-details',
            {'accept' => 'text/html'},
            form => {
                protocol => $p2->protocol,
            }
        )->status_is(200, '200 get ticket as html')->content_like(qr/<html /, 'has html');

        my $res = $t->get_ok(
            '/admin/tickets-details',
            form => {
                protocol => $p2->protocol,
            }
        )->status_is(200, '200 get ticket detail')->tx->res->json;
        ok(
            (scalar grep { $_ =~ /selected_action=ask_add_info/ } map { $_->{href} } $res->{actions}->@*),
            'has action selected_action=ask_add_info'
        );
        ok(
            (scalar grep { $_ =~ /selected_action=close/ } map { $_->{href} } $res->{actions}->@*),
            'has action selected_action=close'
        );

        $t->post_ok(
            '/admin/tickets-details',
            form => {
                protocol        => $p2->protocol,
                selected_action => 'close',
            }
        )->status_is(400, '400 missing param')->json_is('/field', 'response_content')
          ->json_is('/reason', 'is_required');

        $t->post_ok(
            '/admin/tickets-details',
            form => {
                protocol         => $p2->protocol,
                selected_action  => 'close',
                response_content => 'fechando..'
            }
        )->status_is(302, '302 action close');
        $p2->discard_changes;
        is $p2->status, 'done', 'status is done';

        subtest_buffered 'ticket have reopen option after close' => sub {
            $res = $t->get_ok(
                '/admin/tickets-details',
                form => {
                    protocol => $p2->protocol,
                }
            )->status_is(200, '200 get ticket detail')->tx->res->json;
            ok(
                (scalar grep { $_ =~ /selected_action=reopen/ } map { $_->{href} } $res->{actions}->@*),
                'has action selected_action=reopen'
            );

            $t->post_ok(
                '/admin/tickets-details',
                form => {
                    protocol        => $p2->protocol,
                    selected_action => 'reopen'
                }
            )->status_is(302, '302 action reopen');
            $p2->discard_changes;
            is $p2->status, 'pending', 'status is pending';
        };

        subtest_buffered 'ticket ask_add_info' => sub {

            $t->post_ok(
                '/admin/tickets-details',
                form => {
                    protocol         => $p2->protocol,
                    selected_action  => 'ask_add_info',
                    response_content => 'preciso de fuba'
                }
            )->status_is(302, '302 action reopen');
            $p2->discard_changes;
            is $p2->status, 'wait-additional-info', 'status is wait-additional-info';

            ok $p2->as_hashref(), 'has call as_hashref on ticket';
            $t->app->generate_ticket_pdf(ticket => $p2);
        }


    };

    subtest_buffered 'verify account' => sub {
        $cliente->update({account_verified => 0});

        my $fake = create_fake_ticket($cliente, 'pending', 5 * 86400, questionnaire_id => 7);
        my $res  = $t->get_ok(
            '/admin/tickets-details',
            form => {
                protocol => $fake->protocol,
            }
        )->status_is(200, '200 get ticket detail')->tx->res->json;
        ok(
            (scalar grep { $_ =~ /selected_action=verify/ } map { $_->{href} } $res->{actions}->@*),
            'has action selected_action=verify'
        );

        $t->post_ok(
            '/admin/tickets-details',
            form => {
                protocol         => $fake->protocol,
                selected_action  => 'verify',
                response_content => 'not ok',
                verified         => 0,
            }
        )->status_is(302, '302 action verify');
        is $fake->cliente->discard_changes->account_verified, 0, 'not verified';

        $t->post_ok(
            '/admin/tickets-details',
            form => {
                protocol        => $fake->protocol,
                selected_action => 'reopen',
            }
        )->status_is(302, '302 action reopen');


        $t->post_ok(
            '/admin/tickets-details',
            form => {
                protocol         => $fake->protocol,
                selected_action  => 'verify',
                response_content => 'not ok',
                verified         => 1,
            }
        )->status_is(302, '302 action verify');
        is $cliente->discard_changes->account_verified, 1, 'account is verified';
        ok $cliente->verified_account_at,   'has verified_account_at';
        ok $cliente->verified_account_info, 'has verified_account_info';


    };
};


done_testing();
