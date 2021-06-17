package Lgpdjus::Controller::Admin::Users;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;

use Lgpdjus::Types qw/DateStr/;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::Util qw/humanize_bytes/;

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
        nome       => {required => 0, type => 'Str', empty_is_valid => 1, max_length => 99},
        segment_id => {required => 0, type => 'Int'},

        load_delete_form => {required => 0, type => 'Bool'},
    );

    my $dirty = 0;
    my $nome  = $valid->{nome};
    my $rows  = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $render_detail = $valid->{cliente_id} && $c->accept_html();
    my $offset        = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'AU:NP';
        $offset = $tmp->{offset};
        $valid->{segment_id} = $tmp->{segment_id} if defined $tmp->{segment_id};
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
                  /,
                (
                    $render_detail
                    ? (
                        qw/
                          me.qtde_login_senha_normal
                          me.dt_nasc
                          me.cep_cidade
                          me.cep_estado
                          me.perform_delete_at
                          /,
                      )
                    : ()
                )
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );

    if ($nome) {
        $dirty++;    #nao atualizar o contador do segmento, se tiver.
        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(me.nome_completo) like ?', "\%$nome\%"],
                    \['lower(me.apelido) like ?',       "\%$nome\%"],
                    \['lower(me.email) like ?',         "\%$nome\%"],
                    \['me.cpf::text like ?',            "$nome\%"],
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

    my ($total_count, @rows);
    if ($render_detail) {
        my $cliente = $rs->next or $c->reply_item_not_found();


        my @fields = (
            [id                      => 'ID'],
            [nome_completo           => 'Nome Completo'],
            [status                  => 'Status'],
            [cpf                     => 'CPF'],
            [qtde_login_senha_normal => 'Nº Login'],
        );

        foreach my $field (@fields) {
            my ($key, $name, $type) = @$field;

            if ($type && $type eq 'tz') {
                $cliente->{$key} = pg_timestamp2human($cliente->{$key});
            }
            elsif ($type && $type eq 'bool') {
                $cliente->{$key} = $cliente->{$key} ? 'Sim' : 'Não';
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
        $total_count = $rs->count;
        $segment->update({last_count => $total_count, last_run_at => \'NOW()'}) if $segment && !$dirty;

        $rs   = $rs->search(undef, {rows => $rows + 1, offset => $offset});
        @rows = $rs->all;
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
            segment_id => $valid->{segment_id}
        },
        1
    );

    my $segments = $c->schema->resultset('AdminClientesSegment')->search(
        {
            is_test => is_test() ? 1 : 0,
            status  => 'published',
        },
        {
            columns      => [qw/id label last_count last_run_at/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => 'sort'
        }
    );

    return $c->respond_to_if_web(
        json => {
            json => {
                rows        => \@rows,
                has_more    => $has_more,
                next_page   => $has_more ? $next_page : undef,
                total_count => $total_count,
                segments    => [$segments->all]
            }
        },
        html => {
            rows               => \@rows,
            has_more           => $has_more,
            next_page          => $has_more ? $next_page : undef,
            total_count        => $total_count,
            pg_timestamp2human => \&pg_timestamp2human,
            segments           => [$segments->all],
            segment            => $segment,
            segment_id         => $segment ? $segment->id : undef,
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
