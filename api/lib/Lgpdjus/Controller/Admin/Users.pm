package Lgpdjus::Controller::Admin::Users;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;

use Lgpdjus::Types qw/DateStr/;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::Util qw/trim humanize_bytes/;

sub au_search {
    my $c = shift;
    $c->use_redis_flash();
    $c->stash(
        template => 'admin/list_users',
    );

    my $valid = $c->validate_request_params(
        rows       => {required => 0, type => 'Int'},
        cliente_id => {required => 0, type => 'Int'},
        next_page  => {required => 0, type => 'Str'},
        search     => {required => 0, type => 'Str', empty_is_valid => 1, max_length => 99},
        segment_id => {required => 0, type => 'Int',},

        load_delete_form => {required => 0, type => 'Bool'},
    );

    my $dirty  = 0;
    my $search = $valid->{search};
    my $rows = $valid->{rows} || $c->stash('lgpdjus_items_per_page') || die 'missing lgpdjus_items_per_page';
    $rows = 10 if !is_test() && ($rows > 100_000 || $rows < 10);
    my $current_page = 1;

    my $render_detail = $valid->{cliente_id} && $c->accept_html();
    my $offset        = 0;
    my $total_count;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'AU:NP';
        $offset              = $tmp->{offset};
        $valid->{segment_id} = $tmp->{segment_id} if defined $tmp->{segment_id};
        $current_page        = $valid->{page};
        $total_count         = $valid->{count};
    }

    my $rs = $c->schema->resultset('Cliente')->search(
        {($valid->{cliente_id} ? ('me.id' => $valid->{cliente_id}) : ())},
        {
            join     => 'clientes_app_activity',
            order_by => \'last_tm_activity DESC',
            columns  => [
                {activity      => 'clientes_app_activity.last_tm_activity'},
                {tickets_count => \'(SELECT count(1) FROM tickets t WHERE t.cliente_id = me.id )'},
                qw/
                  me.id
                  me.apelido
                  me.nome_completo
                  me.email
                  me.cpf
                  me.status
                  me.account_verified
                  me.account_verification_pending
                  /,
                (
                    $render_detail
                    ? (
                        qw/
                          me.apelido
                          me.perform_delete_at
                          /,
                      )
                    : ()
                )
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );

    $search = trim($search) if defined $search;
    if ($search) {
        $dirty++;    #nao atualizar o contador do segmento, se tiver.
        my $nome_number = $search;
        $nome_number =~ s/[^\d]+//ag;

        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(me.nome_completo) ilike ?', "\%$search\%"],
                    \['lower(me.apelido) ilike ?',       "\%$search\%"],
                    \['lower(me.email) ilike ?',         "\%$search\%"],
                    ($nome_number ? (\['me.cpf::text like ?', "$nome_number\%"]) : ()),
                ],
            }
        );
    }

    my $segment;
    if ($valid->{segment_id}) {
        $segment = $c->schema->resultset('AdminClientesSegment')->find($valid->{segment_id});
        $c->reply_invalid_param('segment_id') unless $segment;
        $rs = $segment->apply_to_rs($c, $rs);
    }

    my @rows;
    if ($render_detail) {
        my $cliente = $rs->next or $c->reply_item_not_found();


        my @fields = (
            [nome_completo => 'Nome Completo'],
            [apelido       => 'Como deseja ser chamado'],
            [email         => 'E-mail'],
            [cpf           => 'CPF', 'cpf'],
        );

        foreach my $field (@fields) {
            my ($key, $name, $type) = @$field;

            if ($type && $type eq 'tz') {
                $cliente->{$key} = pg_timestamp2human($cliente->{$key});
            }
            elsif ($type && $type eq 'bool') {
                $cliente->{$key} = $cliente->{$key} ? 'Sim' : 'Não';
            }
            elsif ($type && $type eq 'cpf') {
                $cliente->{$key} =~ /(...)(...)(...)(..)/;
                $cliente->{$key} = "$1.$2.$3-$4";
            }
        }

        my $cliente_obj = $c->schema->resultset('Cliente')->find($cliente->{id});

        $c->stash(
            template         => 'admin/user_profile',
            cliente          => $cliente,
            fields           => \@fields,
            total_ticket     => $cliente_obj->tickets->count(),
            total_blockchain => $cliente_obj->blockchain_records->count(),
            load_delete_form => $valid->{load_delete_form},
        );

    }
    else {
        $segment->update({last_count => $total_count, last_run_at => \'NOW()'})
          if $segment && !$dirty && defined $total_count;
        $total_count ||= $rs->count;

        $rs   = $rs->search(undef, {rows => $rows + 1, offset => $offset});
        @rows = map {
            $_->{cpf} =~ /(...)(...)(...)(..)/;
            $_->{cpf_formatted} = "$1.$2.$3-$4";
            $_;
        } $rs->all;
    }

    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    my $next_page = $c->encode_jwt(
        {
            iss        => 'AU:NP',
            offset     => $offset + $cur_count,
            segment_id => $valid->{segment_id},
            count      => $total_count,
            page       => $current_page + 1,
        },
        1
    );

    $c->stash(
        segments => [
            $c->schema->resultset('AdminClientesSegment')->search(
                {
                    is_test => is_test() ? 1 : 0,
                    status  => 'published',
                },
                {
                    columns      => [qw/id label last_count last_run_at/],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                    order_by     => 'sort'
                }
            )->all()
        ]
    ) unless $render_detail;

    return $c->respond_to_if_web(
        json => {
            json => {
                rows        => \@rows,
                has_more    => $has_more,
                next_page   => $has_more ? $next_page : undef,
                total_count => $total_count,
            }
        },
        html => {
            rows               => \@rows,
            has_more           => $has_more,
            next_page          => $has_more ? $next_page : undef,
            total_count        => $total_count,
            pg_timestamp2human => \&pg_timestamp2human,

            segment    => $segment,
            segment_id => $segment ? $segment->id : undef,

            search              => $search || '',
            current_page_number => $current_page,
            total_page_number   => ceil($total_count / $rows),

        },
    );
}

sub au_schedule_delete {
    my $c = shift;

    $c->use_redis_flash();
    my $valid = $c->validate_request_params(
        cliente_id  => {required => 1, type => 'Int'},
        delete_date => {required => 1, type => DateStr},
    );

    my $cliente = $c->schema->resultset('Cliente')->find($valid->{cliente_id})
      or $c->reply_item_not_found();

    $cliente->clientes_active_sessions->delete;
    $cliente->update(
        {
            status            => 'deleted_scheduled',
            perform_delete_at => $valid->{delete_date} . ' 12:00:00',
        }
    );

    if ($c->accept_html()) {
        $c->flash_to_redis({success_message => 'Agendamento de remoção agendado com sucesso!'});
        $c->redirect_to('/admin/users?cliente_id=' . $cliente->id);

        return 0;
    }
    else {
        return $c->render(
            json   => {ok => 1},
            status => 200,
        );
    }
}

sub au_unschedule_delete {
    my $c = shift;

    $c->use_redis_flash();
    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Int'},
    );

    my $cliente = $c->schema->resultset('Cliente')->find($valid->{cliente_id})
      or $c->reply_item_not_found();

    $cliente->update(
        {
            status            => 'active',
            perform_delete_at => undef,
        }
    );

    if ($c->accept_html()) {
        $c->flash_to_redis({success_message => 'Cancelamento do agendamento de remoção executado com sucesso!'});
        $c->redirect_to('/admin/users?cliente_id=' . $cliente->id);

        return 0;
    }
    else {
        return $c->render(
            json   => {ok => 1},
            status => 200,
        );
    }
}

1;
