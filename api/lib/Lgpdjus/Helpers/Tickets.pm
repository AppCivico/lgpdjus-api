package Lgpdjus::Helpers::Tickets;
use common::sense;
use Carp qw/confess /;
use utf8;
use Scope::OnExit;
use Mojo::Util qw/dumper/;

use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;

sub setup {
    my $self = shift;

    $self->helper('list_tickets'           => sub { &list_tickets(@_) });
    $self->helper('list_available_tickets' => sub { &list_available_tickets(@_) });

    $self->helper('_get_tickets_rows' => sub { &_get_tickets_rows(@_) });

    $self->helper('load_ticket_object'           => sub { &load_ticket_object(@_) });
    $self->helper('get_ticket_detail'            => sub { &get_ticket_detail(@_) });
    $self->helper('create_ticket_response_reply' => sub { &create_ticket_response_reply(@_) });
}

sub load_ticket_object {
    my ($c, %opts) = @_;
    my $form = $c->validate_request_params(
        ticket_id => {required => 0, type => 'Int'},
    );
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    return $user_obj->tickets->search({'me.id' => $form->{ticket_id}})->next
      or $c->reply_invalid_param('ticket não encontrado.');
}

sub get_ticket_detail {
    my ($c, %opts) = @_;
    my $ticket = $opts{ticket} or confess 'missing ticket';

    return &_format_ticket_detail($ticket, c => $c, is_app => $opts{is_app});
}

sub list_tickets {
    my ($c, %opts) = @_;

    my $rows = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    if ($opts{next_page}) {
        slog_info('list_news applying next_page=%s', to_json($opts{next_page}));
    }

    my $is_first_page = $opts{next_page} ? 0 : 1;

    my $next_page = {
        iss => 'next_page',
    };
    my $has_more = 0;

    my @rows = $c->_get_tickets_rows(
        user_obj => $user_obj,
        %{$opts{next_page}},
        next_page => $next_page,
        rows      => $rows,
    );

    $has_more  = 1 if delete $next_page->{set_has_more_true};
    $next_page = $c->encode_jwt($next_page, 1);

    return {
        rows => [
            (
                scalar @rows > 0
                ? (
                    ($is_first_page ? ({type => 'header', value => 'Lista de Solicitações',}) : ()),
                    @rows
                  )
                : ()
            )
        ],
        has_more => $has_more,
        ($next_page ? (next_page => $next_page) : ()),
    };
}

sub list_available_tickets {
    my ($c, %opts) = @_;

    my $questionnaires = $c->list_questionnaires(%opts);

    return {
        rows     => [@{$questionnaires->{rows}}],
        has_more => 0,
    };
}

sub create_ticket_response_reply {
    my ($c, %opts) = @_;

    my $form = $c->validate_request_params(
        response_id => {required => 1, type => 'Int'},
        content     => {required => 1, type => 'Str', max_length => $ENV{TICKET_CONTENT_MAX_LENGTH}, label => 'Resposta'},
        media_id    => {required => 0, type => 'Str', max_length => 500},
    );
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $ticket   = $opts{ticket}   or confess 'missing ticket';

    my $content  = $form->{content} or confess 'missing content';
    my $media_id = $form->{media_id};

    if ($media_id) {
        $c->reply_invalid_param('media_id inválido')
          unless is_uuid_v4($media_id);

        $c->reply_invalid_param('media_id não encontrado')
          if $user_obj->media_uploads->search(
            {
                id => $media_id,
            }
        )->count != 1;
    }

    $c->schema->txn_do(
        sub {
            slog_info(
                'create_ticket_response_reply content=%s media_id=%s',
                $content,
                $media_id || '-'
            );
            my $response = $ticket->tickets_responses->search(
                {
                    id   => $form->{response_id},
                    type => 'request-additional-info'
                },
                {for => 'update'}
            )->next or $c->reply_invalid_param('Pergunta não encontrada.');

            $c->reply_invalid_param('Pergunta já foi respondida.') if $response->cliente_reply;
            $ticket->obtain_lock;

            $response->update(
                {
                    cliente_reply            => $form->{content},
                    cliente_attachments      => to_json([$media_id ? ($media_id) : ()]),
                    cliente_reply_created_at => \'now()',
                }
            );

            $ticket->ticket_recalc_status_based_on_responses();
            $ticket->_generate_pdf(
                $c, 'cliente_send_email',
                {
                    template => 'ticket_response_reply',
                }
            );

            $c->dpo_send_email(ticket => $ticket, template => 'new_response');
        }
    );

    $ticket->discard_changes;
    return $ticket;
}

sub _get_tickets_rows {
    my ($c, %opts) = @_;

    my $user_obj      = $opts{user_obj};
    my $rows          = $opts{rows};
    my $plain_news    = 1;
    my $tickets_added = {map { $_ => 1 } @{$opts{tickets_added} || []}};
    my $user_id       = $user_obj->id;

    slog_info('_get_tickets_rows rows=%s cliente_id=%s', $rows, $user_id);

    my $cond = {
        'me.cliente_id' => $user_id,
        'me.id'         => {'not in' => [keys %$tickets_added]},
    };

    my @news = $c->schema->resultset('Ticket')->search(
        $cond,
        {
            order_by => [
                is_test()
                ? ({'-desc' => 'me.updated_at'})
                : (
                    \"case when status = 'wait-additional-info' then -1 else 1 end",
                    {'-desc' => 'me.updated_at'}
                )
            ],
            rows     => $rows + 1,
            prefetch => 'questionnaire',
        }
    )->all;

    my $has_more = scalar @news > $rows ? 1 : 0;
    pop @news if $has_more;

    $opts{next_page}{set_has_more_true} = $has_more;

    my @rows;
    foreach my $r (@news) {
        $tickets_added->{$r->id}++;
        push @rows, &_format_ticket($r, %opts);
    }
    log_info(dumper($tickets_added));

    $opts{next_page}{tickets_added} = [keys %$tickets_added];

    return @rows;
}

sub _format_ticket {
    my ($r, %opts) = @_;

    $opts{user_obj} or confess 'missing $opts{user_obj}';

    return {
        type    => 'ticket',
        id      => $r->id(),
        content => $r->html_preview(),
    };
}

sub _format_ticket_detail {
    my ($r, %opts) = @_;

    my @responses = map {
        +{
            id      => $_->id(),
            body => $_->tr_detail_body($opts{c}),
            detail  => $_->tr_detail_hash($opts{c}),
            meta    => {
                can_reply => $_->tr_can_reply(),
            },
            _type => $_->type()
        }
    } $r->tickets_responses->search(undef, {order_by => 'created_on'})->all;
    my $detail = $r->html_detail(c => $opts{c});

    ## CODIGO TEMPORARIO!!
    if ($opts{is_app} && $opts{c}->app_build_version() < 41) {

        my $str = '';
        foreach my $r (reverse @responses) {
            next if delete $r->{_type} eq 'request-additional-info';

            $str .= $r->{body};
        }

        if ($str) {
            $detail
              = '<p style="color: #398FCE; font-weight: 700; font-size: 16pt; line-height: 19pt;">Histórico de ações</p>'
              . $str
              . $detail;
        }
    }


    return {
        id        => $r->id(),
        body      => $detail,
        responses => \@responses,
        meta      => {
            header => 'Solicitação ' . $r->protocol,
        }
    };
}

1;
