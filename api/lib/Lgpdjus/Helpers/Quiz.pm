package Lgpdjus::Helpers::Quiz;
use common::sense;
use Carp qw/croak confess/;
use Digest::MD5 qw/md5_hex/;
use Lgpdjus::Utils qw/tt_test_condition tt_render is_test/;
use JSON;
use utf8;
use warnings;
use Readonly;
use DateTime;
use Lgpdjus::Logger;
use Scope::OnExit;
use Mojo::Util qw/xml_escape/;

# a chave do cache é composta por horarios de modificações do quiz_config e questionnaires
use Lgpdjus::KeyValueStorage;

sub _new_displaytext_error {
    {
        type       => 'displaytext',
        content    => $_[0],
        style      => 'error',
        _relevance => '1',
    }
}

sub _new_displaytext_normal {
    {
        type       => 'displaytext',
        content    => $_[0],
        style      => 'normal',
        _relevance => '1',
    }
}

sub setup {
    my $self = shift;

    $self->helper('ensure_questionnaires_loaded' => sub { &ensure_questionnaires_loaded(@_) });
    $self->helper('load_quiz_config'             => sub { &load_quiz_config(@_) });
    $self->helper('user_get_quiz_session'        => sub { &user_get_quiz_session(@_) });
    $self->helper('load_quiz_session'            => sub { &load_quiz_session(@_) });
    $self->helper('process_quiz_session'         => sub { &process_quiz_session(@_) });
    $self->helper('create_quiz_session'          => sub { &create_quiz_session(@_) });
    $self->helper('list_questionnaires'          => sub { &list_questionnaires(@_) });


}

sub load_quiz_config {
    my ($c, %opts) = @_;

    my $id       = $opts{questionnaire_id};
    my $kv       = Lgpdjus::KeyValueStorage->instance;
    my $cachekey = "QuizConfig:$id:" . $opts{cachekey};

    Readonly::Array my @config => @{

        #my @config = @{
        $kv->redis_get_cached_or_execute(
            $cachekey,
            86400 * 7,    # 7 days
            sub {
                return [
                    map {
                        $_->{yesnogroup} and $_->{yesnogroup} = from_json($_->{yesnogroup});
                        $_->{intro}      and $_->{intro}      = from_json($_->{intro});
                        $_->{options}    and $_->{options}    = from_json($_->{options});
                        $_
                    } $c->schema->resultset('QuizConfig')->search(
                        {
                            'status'           => 'published',
                            'questionnaire_id' => $id,

                        },
                        {

                            order_by     => ['sort', 'id'],
                            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                        }
                    )->all
                ];

            }
        )
    };

    #use DDP;
    #p @config;
    #sleep 3;
    return \@config;
}

sub ensure_questionnaires_loaded {
    my ($c, %opts) = @_;

    return 1 if $c->stash('questionnaires');

    my $questionnaires = [
        $c->schema->resultset('Questionnaire')->search(
            {
                (
                    'me.is_test' => is_test() ? 1 : 0,
                    'me.active'  => '1',
                ),
            },
            {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                order_by     => 'me.sort',
            }
        )->all
    ];
    foreach my $q (@{$questionnaires}) {
        $q->{quiz_config}
          = $c->load_quiz_config(questionnaire_id => $q->{id}, cachekey => $q->{modified_on});
    }
    $c->stash(questionnaires => $questionnaires);
}

sub user_get_quiz_session {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    # verifica se o usuário acabou de fazer um login,
    # se sim, ignora o quiz
    my $key = $ENV{REDIS_NS} . 'is_during_login:' . $user_obj->id;
    return if $c->kv->redis->del($key) && !is_test();
    Log::Log4perl::NDC->push('user_get_quiz_session user_id:' . $user_obj->id);
    on_scope_exit { Log::Log4perl::NDC->pop };

    # procura por quiz não acabados
    my $session = $user_obj->clientes_quiz_sessions->search(
        {
            'me.deleted_at'  => undef,
            'me.finished_at' => undef,
        },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
    )->next;

    if ($session) {
        log_trace(['clientes_quiz_session:loaded', $session->{id}]);
        slog_info('Loaded session clientes_quiz_session.id:%s with stash=%s', $session->{id}, $session->{stash});
        $session->{stash}     = from_json($session->{stash});
        $session->{responses} = from_json($session->{responses});
        return $session;
    }

    return;
}

sub create_quiz_session {
    my ($c, %opts) = @_;
    my $user_obj      = $opts{user_obj}      or croak 'missing user_obj';
    my $questionnaire = $opts{questionnaire} or croak 'missing questionnaire';

    log_info('Running _init_questionnaire_stash');
    my $stash = eval { &_init_questionnaire_stash($questionnaire, $c) };
    if ($@) {
        my $err = $@;
        slog_error('Running _init_questionnaire_stash FAILED: %s', $err);
        die $@ if is_test();

        #use DDP; p $@;
        $stash = &_get_error_questionnaire_stash($err, $c);
    }

    slog_info('Create new session with stash=%s', to_json($stash));

    my $session = $c->schema->resultset('ClientesQuizSession')->create(
        {
            cliente_id       => $user_obj->id,
            questionnaire_id => $questionnaire->{id},
            stash            => to_json($stash),
            responses        => to_json({start_time => time()}),
            created_at       => DateTime->now->datetime(' '),
            can_delete       => 1,
        }
    );
    $session = {$session->get_columns};
    log_trace(['clientes_quiz_session:created',                  $session->{id}]);
    log_trace(['clientes_quiz_session:created_questionnaire_id', $questionnaire->{id}]);

    if ($questionnaire->{code} eq 'verify_account') {
        $user_obj->update(
            {
                # congela a conta para não iniciar outros questionários do
                # tipo verify_account até a conclusão da solicitação (ou cancelamento)
                account_verification_pending => 1,
            }
        );
    }

    slog_info('Created session clientes_quiz_session.id:%s', $session->{id});
    $session->{stash}     = from_json($session->{stash});
    $session->{responses} = from_json($session->{responses});

    return $session;
}

sub list_questionnaires {
    my ($c, %opts) = @_;

    my $filter_id = $opts{id};

    Log::Log4perl::NDC->push('list_questionnaires');
    on_scope_exit { Log::Log4perl::NDC->pop };

    $c->ensure_questionnaires_loaded();

    my @available_quiz;

    # if filter is number, then apply filter by ID
    # if filter is string, then apply filter by code
    # if no filter defined, only return code=unset
    my $filter_is_number = $filter_id =~ /^[0-9]+$/;

    foreach my $q ($c->stash('questionnaires')->@*) {
        next
          if $filter_id
          && (($filter_is_number && $q->{id} != $filter_id) || (!$filter_is_number && $q->{code} ne $filter_id));

        if ($filter_id || (!$filter_id && $q->{code} eq 'unset')) {
            push @available_quiz, $q;
        }
    }

    log_info('user has no questionnaires available'), return if !@available_quiz;

    my @questionnaires;
    foreach my $q (@available_quiz) {
        return $q if $filter_id;
        push @questionnaires, &_format_questionnaire($q);
    }
    return undef if $filter_id;

    return {rows => \@questionnaires};
}

sub _format_questionnaire {
    my ($r) = @_;

    my $href = $r->{icon_href};
    if ($href !~ /^https/) {
        $href = $ENV{QUESTIONNAIRE_ICON_BASE_URL} . '/' . $href;
    }

    return {
        type   => 'questionnaire',
        header => $r->{category_short},
        body   => $r->{short_text},
        icon   => $href,
        id     => $r->{id},

        appbar_header       => $r->{label} || '',
        confirmation_screen => {
            title      => $r->{title}        || 'Clique em iniciar.',
            body       => $r->{body}         || 'Clique em iniciar.',
            legal_info => $r->{legal_info}   || '',
            button     => $r->{start_button} || 'Iniciar',
        }
    };
}

sub _quiz_get_vars {
    my ($user, $responses) = @_;

    #use DDP;
    #p [$user, $responses];
    return {cliente => $user, %{$responses || {}}};
}

sub load_quiz_session {
    my ($c, %opts) = @_;

    $opts{caller_is_post} ||= 0;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $session  = $opts{session}  or confess 'missing session';

    my $update_db    = $opts{update_db} || 0;
    my @preprend_msg = $opts{preprend_msg} ? @{$opts{preprend_msg}} : ();
    my $responses    = $session->{responses};
    my $stash        = $session->{stash};

    my $vars = &_quiz_get_vars({$user_obj->get_columns()}, $responses);

    my $current_msgs = $stash->{current_msgs} || [];

    my $is_finished        = $stash->{is_finished};
    my $add_more_questions = &any_has_relevance($vars, $current_msgs) == 0;

    # se chegar em 0, estamos em loop...
    my $loop_detection = 100;
  ADD_QUESTIONS:
    log_debug("loop_detection=$loop_detection");
    if (--$loop_detection < 0) {
        $c->stash(
            quiz_session => {
                session_id   => $session->{id},
                current_msgs => [&_new_displaytext_error('Loop no quiz detectado, entre em contato com o suporte')],
                prev_msgs    => $stash->{prev_msgs}
            }
        );
        return;
    }

    my @frontend_msg;

    # nao tem nenhuma relevante pro usuario, pegar todas as pending ate um input
    if ($add_more_questions) {

        my $is_last_item = 0;
        do {
            my $item = shift $stash->{pending}->@*;
            if ($item) {
                log_info("Maybe adding question " . to_json($item));

                my $has = &has_relevance($vars, $item);
                slog_info(
                    '  Testing question relevance %s "%s" %s',
                    $has ? '✔️ True ' : '❌ False',
                    (exists $item->{_sub} && exists $item->{_sub}{ref} ? $item->{_sub}{ref} : $item->{content}),
                    $item->{_relevance},
                );

                # pegamos um item que eh input, entao vamos sair do loop nesta vez
                # create_ticket tambem nao é um input, mas tem uma ação que precisa ser executada
                $is_last_item = 1 if $item->{type} ne 'displaytext' && $item->{type} ne 'create_ticket';

                if (!$has) {
                    log_info("question is not relevant, testing next question...");
                    $is_last_item = 0;
                }

                # joga item pra lista de msg correntes
                push $current_msgs->@*, $item;

            }
            else {
                $is_last_item = 1;
            }

            log_info("LAST_ITEM=$is_last_item");

            $update_db++;
        } while !$is_last_item;

        # chegamos no final do chat
        if ($stash->{pending}->@* == 0) {
            log_info("set is_eof to 1");
            $stash->{is_eof} = 1;
            $update_db++;
        }
    }

    slog_info('vars %s', to_json($vars));

    foreach my $q ($current_msgs->@*) {
        my $has = &has_relevance($vars, $q);
        $q->{_currently_has_relevance} = $has;
        slog_info(
            'Rendering: question relevance %s "%s" %s',
            $has ? '✔️ True' : '❌ False',
            (exists $q->{_sub} && exists $q->{_sub}{ref} ? $q->{_sub}{ref} : $q->{content}),
            $q->{_relevance},
        );

        if ($has) {
            push @frontend_msg, &_render_question($q, $vars, $user_obj, $session, $c);
        }
    }

    # nao teve nenhuma relevante, adiciona mais questoes,
    # mesmo se tiver um botao agora que nao esta visivel
    # isso faz com que seja possível desenhar um fluxo onde uma pergunta no futuro
    # muda reativa a visibilidade de uma pergunta do passado
    # embora isso possa ser uma bad-pratice, pois isso pode fazer com que
    # a pergunta atual do 'nada' fique com dois inputs, caso mal feita a logica
    # ja que essa situacao nao esta testada no app.
    if (!@frontend_msg) {
        log_info("⚠️ No frontend questions found... current_msgs is " . to_json($current_msgs));

        if (!$stash->{is_eof}) {
            log_info("🔁 is_eof=0, GOTO ADD_QUESTIONS ");
            $add_more_questions = 1;

            goto ADD_QUESTIONS;
        }
        else {
            log_info("is_eof=1  caller_is_post=" . $opts{caller_is_post});
            if (!$opts{caller_is_post}) {

              ADD_BTN_FIM:
                log_info("🔴 Adding generic END button");

                # acabou sem um input [pois isso aqui eh chamado no GET],
                # vou colocar um input padrao de finalizar
                $current_msgs = [
                    {
                        type       => 'button',
                        content    => 'Tudo certo por aqui! Recado para administrador: quiz acabou sem botão fim!',
                        action     => '',
                        ref        => 'BT_END_' . int(rand(100000)),
                        label      => 'Finalizar',
                        _relevance => '1',
                        _code      => 'FORCED_END_CHAT',
                        _end_chat  => 1,
                        _currently_has_relevance => 1,
                    }
                ];
                $stash->{is_eof}++;
                $update_db++;
            }
            else {
                if (!$stash->{is_finished}) {
                    log_info("😟 forcing add-button");
                    goto ADD_BTN_FIM;
                }
                else {
                    log_info("🉑 quiz finished, bye bye!");
                }
            }
        }

    }

    $stash->{current_msgs} = $current_msgs;

    # se teve modificações, entamos vamos escrever a stash de volta no banco
    # isso eh necessario pois o metodo que o metodo que receba as respostas nao precise "renderizar" o chat
    # [chamar propria rotina]
    # e tambem para evitar que ele avance o chat ou receber uma resposta sem sentido mas avançar o chat
    if ($update_db) {

        slog_info("updating stash to %s",     to_json($stash));
        slog_info("updating responses to %s", to_json($responses));

        my $rs = $c->schema->resultset('ClientesQuizSession');
        $rs->search({id => $session->{id}})->update(
            {
                stash     => to_json($stash),
                responses => to_json($responses),
                (
                    $stash->{is_finished}
                    ? (finished_at => DateTime->now->datetime(' '))
                    : ()
                )
            }
        );
    }

    if (exists $stash->{is_finished} && $stash->{is_finished}) {

        my $end_screen = '';
        $c->ensure_questionnaires_loaded();
        foreach my $q ($c->stash('questionnaires')->@*) {
            next unless $q->{id} == $session->{questionnaire_id};
            $end_screen = $q->{end_screen};
            last;
        }

        $c->stash(
            'quiz_session' => {
                finished   => 1,
                end_screen => tt_render($end_screen, $vars),
            }
        );
    }
    else {
        # importante só processar o create_ticket no render após o update do banco,
        # então ele é gerado imediatamente antes do retorno para o frotnend

        foreach my $q (@frontend_msg) {
            if ($q->{type} eq 'create_ticket') {
                my $session_obj = $user_obj->clientes_quiz_sessions->find($session->{id}) or confess 'missing session';
                my $ticket      = $session_obj->generate_ticket($c)                       or confess 'missing ticket';

                $vars->{'ticket_protocol'} = $ticket->protocol;
                $vars->{'ticket_id'}       = $ticket->id;
                $q->{type}                 = 'displaytext';
                my $render = &_render_question($q, $vars, $user_obj, $session, $c);
                $q->{$_} = $render->{$_} for keys %$render;
            }
        }

        $c->stash(
            'quiz_session' => {
                current_msgs => [grep { &_skip_empty_msg($_) } @preprend_msg, @frontend_msg],
                session_id   => $session->{id},
                can_delete   => $session->{can_delete} ? 1 : 0,
                prev_msgs    => $opts{caller_is_post}
                ? undef
                : [
                    grep { &_skip_empty_msg($_) }
                    map  { &_render_question($_, $vars, $user_obj, $session, $c) } $stash->{prev_msgs}->@*
                ],
            }
        );
    }

}

sub _skip_empty_msg {
    my ($question) = @_;
    return exists $question->{content} ? $question->{content} ? 1 : 0 : 1;
}

sub _render_question {
    my ($q, $vars, $user_obj, $session, $c) = @_;

    my $public = {};

    if (exists $q->{_load_as_image}) {
        confess 'cannot load image without user' unless $user_obj;
        confess 'cannot load image without $c'   unless $c;
        my $media = $user_obj->cliente_get_media_by_id($q->{display_response});
        $public->{image_link} = $media->media_generate_download_url($c);
    }

    while (my ($k, $v) = each $q->%*) {

        # ignora as chaves privatas
        next if $k =~ /^_/;

        if ($k eq 'options' && ref $v eq 'ARRAY') {

            my @new_options;

            # tomar cuidado pra nunca sobreescrever o valor na referencia original
            foreach my $option ($v->@*) {
                push @new_options, {
                    %$option,
                    display => tt_render($option->{display}, $vars),
                };
            }

            $public->{$k} = \@new_options;

        }
        else {

            # create_ticket precisa manter o conteudo original da template até
            # ser chamado novamente com o type displaytext
            $public->{$k} = $k =~ /content/ && $q->{type} ne 'create_ticket' ? tt_render($v, $vars) : $v;

        }

    }

    # retorna pro valor da imagem, pois o display_response é substituído durante o loop anterior
    $public->{display_response} = '<img src="' . xml_escape(delete $public->{image_link}) . '">'
      if exists $public->{image_link};

    return $public;
}

sub process_quiz_session {
    my ($c, %opts) = @_;

    my $user     = $opts{user}          or confess 'missing user';
    my $user_obj = $opts{user_obj}      or confess 'missing user_obj';
    my $session  = $opts{session}       or confess 'missing session';
    my $params   = delete $opts{params} or confess 'missing params';

    log_info("process_quiz_session " . to_json($params));

    my $stash        = $session->{stash};
    my $current_msgs = $stash->{current_msgs} || [];
    my $responses    = $session->{responses};

    my @preprend_msg;

    my $have_new_responses;
    log_info("testing reverse... order of messages.." . to_json($current_msgs));
  QUESTIONS:
    foreach my $msg (reverse $current_msgs->@*) {

        # se ela nao tava na tela, nao podemos processar as respostas
        next unless $msg->{_currently_has_relevance};

        my $ref = $msg->{ref};
        next unless $ref;

        log_info("ref=$ref?");
        if (exists $params->{$ref}) {
            my $val = defined $params->{$ref} ? $params->{$ref} : '';
            log_info("Found, $ref=$val");
            my $code = $msg->{_code};
            die sprintf "missing `_code` on message %s", to_json($msg) unless $code;

            log_info("msg type " . $msg->{type});

            if ($msg->{type} eq 'yesno') {

                if ($val =~ /^(Y|N)$/) {

                    # processa a questao que o cadastro (code) eh unico
                    # mas esta espalhada em varias mensagens
                    if (exists $msg->{_sub}) {
                        $responses->{$msg->{_sub}{ref}} = $val;

                        if (exists $responses->{$code}) {
                            if ($responses->{$code} !~ /^\d+/) {
                                push @preprend_msg,
                                  &_new_displaytext_error(
                                    sprintf(
                                        'Erro na configuração do quiz! code `%s` já tem um valor não númerico, logo não pode-se somar uma resposta de power2',
                                        $code
                                    )
                                  );
                                last QUESTIONS;
                            }

                            $responses->{$code} += $msg->{_sub}{p2a} if $val eq 'Y';
                        }
                        else {
                            if ($val eq 'Y') {
                                $responses->{$code} = $msg->{_sub}{p2a};
                            }
                            else {
                                # inicia como '0'
                                $responses->{$code} = 0;
                            }

                        }

                        $code = $msg->{_sub}{code} . '_' . $msg->{_sub}{p2a};
                    }

                    $responses->{$code} = $val eq 'Y' ? $msg->{_yes_value} : $msg->{_no_value};
                    $msg->{display_response} = $val eq 'Y' ? $msg->{yes_label} : $msg->{no_label};

                    $have_new_responses++;
                }
                else {
                    push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s deve ser Y ou N', $ref));
                }
            }
            elsif ($msg->{type} eq 'text') {

                $responses->{$code} = $val;
                $msg->{display_response} = $val;
                $have_new_responses++;

            }
            elsif ($msg->{type} eq 'photo_attachment') {
                my $media = $user_obj->cliente_get_media_by_id($val);
                if (!$media) {
                    push @preprend_msg, &_new_displaytext_error(sprintf('upload %s não é válido', $val));
                }
                else {
                    $responses->{$code}      = $media->id;
                    $msg->{display_response} = $media->id;
                    $msg->{_load_as_image}   = 1;
                    $have_new_responses++;
                }
            }
            elsif ($msg->{type} eq 'multiplechoices') {

                # lista de ate 999 numeros
                if (defined $val && length $val <= 6000 && $val =~ /^[0-9]{1,6}(?>,[0-9]{1,6})*$/a) {

                    my $reverse_index = {map { $_->{index} => $_->{display} } $msg->{options}->@*};
                    my $output        = '';
                    my $output_human  = '';
                    foreach my $index (split /,/, $val) {

                        # pula caso venha opcoes invalidas
                        next unless defined $reverse_index->{$index};

                        $output_human .= $reverse_index->{$index} . ', ';
                        $output       .= $msg->{_db_option}[$index] . ',';
                    }

                    chop($output_human);    # rm espaco
                    chop($output_human);    # rm virgula
                    chop($output);          # rm virgula

                    $responses->{$code} = '[' . $output . ']';
                    $msg->{display_response} = $output_human;
                    $have_new_responses++;

                }
                else {
                    push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s deve uma lista de números', $ref));
                }

            }
            elsif ($msg->{type} eq 'onlychoice') {

                # index de ate 999999
                if (defined $val && length $val <= 6 && $val =~ /^[0-9]+$/a && defined $msg->{_db_option}[$val]) {

                    my $reverse_index = {map { $_->{index} => $_->{display} } $msg->{options}->@*};

                    my $output_human = $reverse_index->{$val};
                    my $output       = $msg->{_db_option}[$val];

                    $responses->{$code} = $output;
                    $msg->{display_response} = $output_human;
                    $have_new_responses++;

                }
                else {
                    push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s deve um número', $ref));
                }

            }
            elsif ($msg->{type} eq 'button') {

                log_info("msg type button");

                # reiniciar o fluxo
                if ($msg->{_reset}) {
                    $c->ensure_questionnaires_loaded();
                    foreach my $q ($c->stash('questionnaires')->@*) {
                        next unless $q->{id} == $session->{questionnaire_id};
                        $stash     = &_init_questionnaire_stash($q, $c);
                        $responses = {start_time => time()};
                        $have_new_responses++;
                        last;
                    }
                }
                else {
                    $responses->{$code}             = $val;
                    $responses->{$code . '_action'} = $msg->{action};
                    $msg->{display_response}        = $msg->{label};
                    $have_new_responses++;


                    if ($stash->{is_eof} || $msg->{_end_chat}) {
                        $stash->{is_finished} = 1;
                    }
                }

            }
            else {
                push @preprend_msg, &_new_displaytext_error(sprintf('tipo %s não foi programado!', $msg->{type}));
            }

        }
        else {
            push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s nao foi enviado', $ref));
        }

        # vai embora, pois so devemos ter 1 resposta por vez
        # pelo menos eh assim que eu imagino o uso por enquanto
        last QUESTIONS if $have_new_responses;
    }

    log_info("have_new_responses=$have_new_responses");

    # teve respostas, na teoria seria mover as atuais para o "prev_msgs",
    # mas só devemos movimentar o que estava relevante momento anteriores as respostas
    if ($have_new_responses) {

        my @kept;

        for my $msg ($current_msgs->@*) {
            if (!$msg->{_currently_has_relevance}) {
                push @kept, $msg;
                next;
            }
            else {
                push $stash->{prev_msgs}->@*, $msg;
            }
        }

        $stash->{current_msgs} = $current_msgs = \@kept;
        $session->{responses}  = $responses;

        # salva as respostas (vai ser chamado no load_quiz_session)
        $opts{update_db} = 1;
    }

    $c->load_quiz_session(
        %opts,
        preprend_msg   => \@preprend_msg,
        caller_is_post => 1,
    );

}

sub has_relevance {
    my ($vars, $msg) = @_;

    return 1 if $msg->{_relevance} eq '1';
    return 1 if tt_test_condition($msg->{_relevance}, $vars);
    return 0;
}

sub any_has_relevance {
    my ($vars, $msgs) = @_;

    foreach my $q ($msgs->@*) {
        return 1 if $q->{_relevance} eq '1';
        return 1 if has_relevance($vars, $q);
    }

    return 0;
}

sub _init_questionnaire_stash {
    my $questionnaire = shift;
    my $c             = shift;

    die "AnError\n" if exists $ENV{DIE_ON_QUIZ};

    my @questions;
    foreach my $qc ($questionnaire->{quiz_config}->@*) {

        my $relevance = $qc->{relevance};
        if (exists $qc->{intro} && $qc->{intro}) {
            foreach my $intro ($qc->{intro}->@*) {
                push @questions, {
                    type       => 'displaytext',
                    style      => 'normal',
                    content    => $intro->{text},
                    _relevance => $relevance,
                };
            }
        }

        if ($qc->{type} eq 'yesno') {
            push @questions, {
                type       => 'yesno',
                content    => $qc->{question},
                ref        => 'YN' . $qc->{id},
                yes_label  => $qc->{yesno_yes_label} || 'SIM',
                _yes_value => $qc->{yesno_yes_value} || 'Y',
                no_label   => $qc->{yesno_no_label}  || 'NÂO',
                _no_value  => $qc->{yesno_no_value}  || 'N',
                _relevance => $relevance,
                _code      => $qc->{code},
            };
        }
        elsif ($qc->{type} eq 'text') {
            push @questions, {
                type       => 'text',
                content    => $qc->{question},
                ref        => 'FT' . $qc->{id},
                _relevance => $relevance,
                _code      => $qc->{code},
            };
        }
        elsif ($qc->{type} eq 'yesnogroup') {

            my $counter = 1;
            foreach my $subq ($qc->{yesnogroup}->@*) {
                next unless $subq->{Status};
                $counter++;

                push @questions, {
                    type       => 'yesno',
                    content    => $subq->{question},
                    ref        => 'YN' . $qc->{id} . '_' . $counter,
                    yes_label  => $qc->{yesno_yes_label} || 'SIM',
                    _yes_value => $qc->{yesno_yes_value} || 'Y',
                    no_label   => $qc->{yesno_no_label}  || 'NÂO',
                    _no_value  => $qc->{yesno_no_value}  || 'N',
                    _code      => $qc->{code},
                    _relevance => $relevance,
                    _sub       => {
                        ref  => $qc->{code} . '_' . $subq->{referencia},
                        p2a  => $subq->{power2answer},
                        code => $qc->{code}
                    },

                };

            }

        }
        elsif ($qc->{type} eq 'displaytext') {

            push @questions, {
                type       => 'displaytext',
                style      => 'normal',
                content    => $qc->{question},
                _relevance => $relevance,
            };

        }
        elsif ($qc->{type} eq 'photo_attachment') {

            push @questions, {
                type       => 'photo_attachment',
                content    => $qc->{question},
                ref        => 'BT' . $qc->{id},
                label      => $qc->{button_label} || 'Selecionar foto',
                _relevance => $relevance,
                _code      => $qc->{code},
            };

        }
        elsif ($qc->{type} eq 'create_ticket') {

            push @questions, {
                type       => 'create_ticket',
                content    => $qc->{question},
                ref        => 'BT' . $qc->{id},
                _relevance => $relevance,
                _code      => $qc->{code},
            };

        }
        elsif ($qc->{type} eq 'botao_fim') {

            push @questions, {
                type       => 'button',
                content    => $qc->{question},
                action     => 'none',
                ref        => 'BT' . $qc->{id},
                label      => $qc->{button_label} || 'Enviar',
                _relevance => $relevance,
                _code      => $qc->{code},
                _end_chat  => 1,
            };

        }
        elsif ($qc->{type} eq 'multiplechoices' || $qc->{type} eq 'onlychoice') {
            my $is_mc = $qc->{type} eq 'multiplechoices' ? 1 : 0;

            my $ref = {
                type       => $is_mc ? 'multiplechoices' : 'onlychoice',
                content    => $qc->{question},
                ref        => ($is_mc ? 'MC' : 'OC') . $qc->{id},
                _code      => $qc->{code},
                _relevance => $relevance,
                options    => [],
            };

            my $counter = 0;
            foreach my $option ($qc->{options}->@*) {
                my $value = $option->{value};
                $value =~ s/\,/\\\,/;
                $ref->{_db_option}[$counter] = $value;

                push @{$ref->{options}}, {
                    display => $option->{label},
                    index   => $counter,
                };
                $counter++;
            }
            push @questions, $ref;

        }

    }

    # verificando se o banco nao tem nada muito inconsistente
    my $dup_by_code = {};
    foreach my $qq (@questions) {

        sub is_power_of_two { not $_[0] & $_[0] - 1 }

        die "%s is missing _relevance", to_json($qq) if !$qq->{_relevance};

        if ($qq->{type} eq 'button') {
            for my $missing (qw/content action label ref/) {
                die sprintf "question %s is missing $missing\n", to_json($qq), $missing if !$qq->{$missing};
            }
        }
        elsif ($qq->{type} eq 'multiplechoices' || $qq->{type} eq 'onlychoice') {
            for my $missing (qw/options ref/) {
                die sprintf "question %s is missing $missing\n", to_json($qq), $missing if !$qq->{$missing};
            }

            for my $option ($qq->{options}->@*) {
                die sprintf "question option is missing text\n", to_json($qq) if !$option->{display};
            }
        }
        elsif (exists $qq->{_sub}) {
            for my $missing (qw/content ref/) {
                die sprintf "question %s is missing $missing\n", to_json($qq) if !$qq->{$missing};
            }

            # nao pode ter por exemplo, dois campos referencia ou power2answer iguais na mesma ref
            $dup_by_code->{$qq->{_sub}{code}} ||= {};
            my $dup = $dup_by_code->{$qq->{_sub}{code}};

            if ($dup->{'_' . $qq->{_sub}{ref}}++ > 0) {
                die sprintf "question %s has duplicate reference '%s'\n", to_json($qq), $qq->{_sub}{ref};
            }

            if ($qq->{_sub}{p2a} < 1 || !is_power_of_two($qq->{_sub}{p2a})) {
                die sprintf "question %s has invalid power of two (%s is not a valid value)\n", to_json($qq),
                  $qq->{_sub}{p2a};
            }

            if ($dup->{$qq->{_sub}{p2a}}++ > 0) {
                die sprintf "question %s has duplicate power of two(%s)\n", to_json($qq), $qq->{_sub}{p2a};
            }
        }

    }

    my $stash = {
        pending   => \@questions,
        prev_msgs => []
    };

    return $stash;
}

sub _get_error_questionnaire_stash {
    my ($err, $c) = @_;

    my $stash = {
        prev_msgs => [],
        pending   => [
            &_new_displaytext_error('Encontramos um problema para montar o questionário!'),
            &_new_displaytext_error($err . ''),
            {
                type                     => 'button',
                content                  => 'Tente novamente mais tarde, e entre em contato caso o erro persista.',
                _relevance               => '1',
                _currently_has_relevance => 1,
                _reset                   => 1,
                _code                    => 'ERROR',
                ref                      => 'btn',
                action                   => 'reload',
                label                    => 'Tentar agora',
            }
        ]
    };

}

1;