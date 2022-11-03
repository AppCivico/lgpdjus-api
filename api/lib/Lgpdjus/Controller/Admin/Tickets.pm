package Lgpdjus::Controller::Admin::Tickets;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::DOM;

sub a_tickets_detail_get_post {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(
        template => 'admin/detail_ticket',
    );

    my $valid = $c->validate_request_params(
        protocol        => {required => 1, type => 'Int'},
        selected_action => {required => 0, type => 'Str'},
    );
    my $ticket = $c->schema->resultset('Ticket')->search(
        {protocol => $valid->{protocol}},
        {
            order_by   => \'me.id DESC',
            join       => ['questionnaire', 'cliente'],
            '+columns' => [
                {
                    questionnaire_label          => 'questionnaire.label',
                    cliente_nome_completo        => 'cliente.nome_completo',
                    cliente_verified             => 'cliente.account_verified',
                    cliente_verification_pending => 'cliente.account_verification_pending',
                    cliente_govbr_nivel          => 'cliente.govbr_nivel',
                }
            ],
        }
    )->next();
    if (!$ticket) {
        $c->flash_to_redis({message => 'Solicitação não encontrada!'});
        return $c->redirect_to('/admin/tickets');
    }

    $c->stash(blockchain_count => $ticket->blockchain_records->count);

    my $is_verify = $ticket->questionnaire->code eq 'verify_account';

    my $base_url = '/admin/tickets-details?protocol=' . $ticket->protocol;

    # action, class, placeholder, button
    my $actions_by_code = {
        reopen       => ['Reabrir', 'btn-light', '(placeholder)', '(button)'],
        ask_add_info => [
            'Pedir informação adicional', 'btn-light', 'Descreva qual informação adicional é necessária',
            'Precio que me envie novamente a foto do...', 'Enviar pedido'
        ],
        close =>
          ['Analisar e concluir', 'btn-primary', 'Escreva a resposta da solicitação', 'Sim, tratamos ...', 'Concluir'],
        change_due => ['Mudar prazo', 'btn-light', 'Justificativa', 'Escreva a justificativa', 'Mudar prazo'],
        verify     => [
            'Analisar e verificar conta', 'btn-primary', 'Comentário',
            'Descreva o resultado ou motivo da negação', 'Verificar conta'
        ],
    };
    my $selected_action = $valid->{selected_action} ? $actions_by_code->{$valid->{selected_action}} : undef;
    my @actions;

    if ($selected_action) {
        if ($valid->{selected_action} eq 'reopen') {

            if ($ticket->action_reopen($c)) {
                $c->flash_to_redis({success_message => 'Solicitação reaberta com sucesso!'});
            }
            else {
                $c->flash_to_redis({message => 'Não foi possível reabrir a solicitação.'});
            }
            return $c->redirect_to($base_url);
        }
        $c->stash(
            action_text_label       => $selected_action->[2],
            action_text_placeholder => $selected_action->[3],
            action_button_text      => $selected_action->[4],
        );
        if ($c->req->method eq 'POST') {
            my $param2;

            my $form = $c->validate_request_params(
                response_content => {
                    required       => $valid->{selected_action} eq 'verify' ? 0 : 1,
                    type           => 'Str',
                    max_length     => 10000,
                    empty_is_valid => 1,
                },
            );

            if (   $valid->{selected_action} eq 'ask_add_info'
                && $ticket->action_ask_add_info($c, message => $form->{response_content}))
            {
                $c->flash_to_redis({success_message => 'Informação adicional enviada com sucesso!'});
            }
            elsif ($valid->{selected_action} eq 'close'
                && $ticket->action_close($c, message => $form->{response_content}))
            {
                $c->flash_to_redis({success_message => 'Solicitação concluída com sucesso!'});
            }
            elsif (
                $valid->{selected_action} eq 'change_due'
                && (
                    $param2 = $c->validate_request_params(
                        due_date => {required => 1, type => 'Str', max_length => 10},
                    )
                )
                && $ticket->action_change_due($c, due_date => $param2->{due_date}, message => $form->{response_content})
              )
            {
                $c->flash_to_redis({success_message => 'Alteração do prazo efetuado com sucesso!'});
            }
            elsif (
                $valid->{selected_action} eq 'verify'
                && (
                    $param2 = $c->validate_request_params(
                        verified => {required => 1, type => 'Bool'},
                    )
                )
                && $ticket->action_verify_cliente(
                    $c,
                    message  => $form->{response_content},
                    verified => $param2->{verified}
                )
              )
            {
                $c->flash_to_redis({success_message => 'Solicitação concluída com sucesso!'});
            }
            else {
                $c->flash_to_redis({message => 'Não foi possível executar a ação!'});
            }
            return $c->redirect_to($base_url);
        }
    }
    else {
        if ($ticket->status eq 'done') {
            for my $code (qw/reopen/) {
                push @actions, {
                    name  => $actions_by_code->{$code}[0],
                    class => $actions_by_code->{$code}[1],
                    href  => "$base_url&selected_action=$code",
                };
            }
        }
        else {
            for my $code (qw/ask_add_info change_due/, ($is_verify ? ('verify') : ('close'))) {
                push @actions, {
                    name    => $actions_by_code->{$code}[0],
                    class   => $actions_by_code->{$code}[1],
                    href    => "$base_url&selected_action=$code",
                    skip_br => $code =~ /ask_add_info/ ? 1 : 0,
                };
            }

        }
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                id      => $ticket->id(),
                actions => \@actions,
            }
        },
        html => {
            ticket          => $ticket,
            actions         => \@actions,
            selected_action => $selected_action ? $valid->{selected_action} : undef,
            action_name     => $selected_action ? $selected_action->[0]     : undef,
            base_url        => $base_url,
        },
    );
}

sub a_tickets_list_get {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(
        template => 'admin/list_tickets',
    );

    my $valid = $c->validate_request_params(
        rows        => {required => 0, type => 'Int'},
        next_page   => {required => 0, type => 'Str'},
        filter      => {required => 0, type => 'Str'},
        filter_type => {required => 0, type => 'Int'},
        cliente_id  => {required => 0, type => 'Int'},
        order_by    => {required => 0, type => 'Str'},
    );
    my $rows = $valid->{rows} || $c->stash('lgpdjus_items_per_page') || die 'missing lgpdjus_items_per_page';
    $rows = 10 if !is_test() && ($rows > 100_000 || $rows < 10);

    my $total_count;
    my $current_page = 1;
    my $offset       = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'TICKETS:NP';
        $offset       = $tmp->{offset};
        $total_count  = $tmp->{count};
        $current_page = $tmp->{page};
    }

    $valid->{order_by} ||= 'default';
    my $order_bys = {
        default  => \'me.id DESC',
        protocol => \'me.protocol ASC',
        duedesc  => \'me.due_date DESC',
        dueasc   => \'me.due_date ASC',
    };
    my $order_bys_labels = {
        default     => 'Padrão (protocolo descedente)',
        protocolasc => 'Protocolo crescente',
        duedesc     => 'Prazo mais recente primeiro',
        dueasc      => 'Prazo mais antigo primeiro',
    };
    my $order_by = exists $order_bys_labels->{$valid->{order_by}} ? $valid->{order_by} : 'default';

    my $rs = $c->schema->resultset('Ticket')->search(
        {
            ($ENV{ADMIN_FILTER_CLIENTE_ID} ? ('me.cliente_id' => $ENV{ADMIN_FILTER_CLIENTE_ID})                   : ()),
            ($valid->{cliente_id}          ? ('me.cliente_id' => $valid->{cliente_id})                            : ()),
            ($valid->{filter_type} && $valid->{filter_type} != -1 ? ('questionnaire.id' => $valid->{filter_type}) : ()),
        },
        {
            order_by   => $order_bys->{$order_by},
            join       => ['questionnaire', 'cliente'],
            '+columns' => [
                {
                    questionnaire_label          => 'questionnaire.label',
                    cliente_nome_completo        => 'cliente.nome_completo',
                    cliente_verified             => 'cliente.account_verified',
                    cliente_verification_pending => 'cliente.account_verification_pending',
                    cliente_govbr_nivel          => 'cliente.govbr_nivel',
                }
            ],
        }
    );

    $valid->{filter} ||= $valid->{cliente_id} ? 'all' : 'pending';
    my $filters = {
        pending => {'me.status' => 'pending'},
        done    => {'me.status' => 'done'},
        waiting => {'me.status' => 'wait-additional-info'},
        pastdue => {
            'me.status'   => 'pending',
            'me.due_date' =>

              # converte para para o dia atual meia noite, depois volta para o timestamp em utc
              {'<=' => \ "timezone('America/Sao_paulo', timezone('America/Sao_paulo', now())::date::timestamp)"}
        },
    };
    my $filter = $filters->{$valid->{filter}};

    $valid->{filter} = 'all' unless $filter;

    $rs = $rs->search($filter);
    $total_count ||= $rs->count;
    $rs = $rs->search(undef, {rows => $rows + 1, offset => $offset});
    my @rows = $rs->all;

    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'TICKETS:NP',
            offset => $offset + $cur_count,
            count  => $total_count,
            page   => $current_page + 1
        },
        1
    );

    if ($valid->{cliente_id}) {
        $c->stash(cliente => $c->schema->resultset('Cliente')->find($valid->{cliente_id}));
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                rows => [
                    map { {id => $_->id, status => $_->status} } @rows,
                ],
                has_more  => $has_more,
                next_page => $has_more ? $next_page : undef,
                filter    => $valid->{filter},

            }
        },
        html => {
            filter      => $valid->{filter},
            filter_type => $valid->{filter_type},
            filter_opts => [
                {id => 'pending', label => 'Solicitações pendentes'},
                {id => 'done',    label => 'Solicitações finalizadas'},
                {id => 'waiting', label => 'Solicitações aguardando informações'},
                {id => 'pastdue', label => 'Solicitações com prazo vencido'},
                {id => 'all',     label => 'Todas as solicitações'},

            ],
            filter_type_opts => [
                {id => -1, label => 'Todos os tipos'},
                map { +{id => $_->{id}, label => $_->{label}} } $c->schema->resultset('Questionnaire')->search(
                    {'me.is_test' => 0},
                    {
                        columns      => [qw/id label/],
                        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                        order_by     => 'me.sort'
                    }
                )
            ],
            order_bys_opts =>
              [map { +{id => $_, label => $order_bys_labels->{$_}} } qw/default protocolasc duedesc dueasc/],
            order_by            => $order_by,
            rows                => \@rows,
            has_more            => $has_more,
            next_page           => $has_more ? $next_page : undef,
            total_count         => $total_count,
            current_page_number => $current_page,
            total_page_number   => ceil($total_count / $rows),
        },
    );
}


1;
