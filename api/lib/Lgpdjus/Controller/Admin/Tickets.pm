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
                }
            ],
        }
    )->next();
    if (!$ticket) {
        $c->flash_to_redis({message => 'Solicitação não encontrada!'});
        return $c->redirect_to('/admin/tickets');
    }
    my $is_verify = $ticket->questionnaire->code eq 'verify_account';

    my $base_url        = '/admin/tickets-details?protocol=' . $ticket->protocol;
    my $actions_by_code = {
        reopen       => ['Reabrir', 'btn-light'],
        ask_add_info => [
            'Pedir informação adicional', 'btn-light', 'Descreva qual informação adicional é necessária',
            'Precio que me envie novamente a foto do...'
        ],
        close      => ['Analisar e concluir', 'btn-primary', 'Escreva a resposta da solicitação', 'Sim, tratamos ...'],
        change_due => ['Mudar prazo',         'btn-light',   'Escolha o novo prazo',              ''],
        verify     => [
            'Analisar e verificar conta', 'btn-primary', 'Comentário',
            'Descreva o resultado ou motivo da negação'
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
        );
        if ($c->req->method eq 'POST') {
            my $param2;

            my $form = $c->validate_request_params(
                response_content => {required => 1, type => 'Str', max_length => 10000},
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
            elsif ($valid->{selected_action} eq 'change_due'
                && $ticket->action_change_due($c, due_date => $form->{response_content}))
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
                    name  => $actions_by_code->{$code}[0],
                    class => $actions_by_code->{$code}[1],
                    href  => "$base_url&selected_action=$code",
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
    );
    my $rows = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $offset = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'TICKETS:NP';
        $offset = $tmp->{offset};
    }

    my $rs = $c->schema->resultset('Ticket')->search(
        {
            ($ENV{ADMIN_FILTER_CLIENTE_ID} ? ('me.cliente_id' => $ENV{ADMIN_FILTER_CLIENTE_ID})                   : ()),
            ($valid->{cliente_id}          ? ('me.cliente_id' => $valid->{cliente_id})                            : ()),
            ($valid->{filter_type} && $valid->{filter_type} != -1 ? ('questionnaire.id' => $valid->{filter_type}) : ()),
        },
        {
            order_by   => \'me.id DESC',
            join       => ['questionnaire', 'cliente'],
            '+columns' => [
                {
                    questionnaire_label          => 'questionnaire.label',
                    cliente_nome_completo        => 'cliente.nome_completo',
                    cliente_verified             => 'cliente.account_verified',
                    cliente_verification_pending => 'cliente.account_verification_pending',
                }
            ],
        }
    );

    $valid->{filter} ||= 'pending';
    my $filters = {
        pending => {'me.status' => 'pending'},
        done    => {'me.status' => 'done'},
        waiting => {'me.status' => 'wait-additional-info'},
    };
    my $filter = $filters->{$valid->{filter}};

    $valid->{filter} = 'all' unless $filter;

    $rs = $rs->search($filter, {rows => $rows + 1, offset => $offset});
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
                {id => 'pending', label => 'Exibir todas solicitações pendentes'},
                {id => 'all',     label => 'Exibir todas solicitações'},
                {id => 'done',    label => 'Exibir todas solicitações finalizadas'},
                {id => 'waiting', label => 'Exibir todas solicitações aguardando informações'},

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
            rows      => \@rows,
            has_more  => $has_more,
            next_page => $has_more ? $next_page : undef,
        },
    );
}


1;
