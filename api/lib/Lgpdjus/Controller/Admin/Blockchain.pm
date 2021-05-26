package Lgpdjus::Controller::Admin::Blockchain;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::DOM;

sub a_blockchain_list_get {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(
        template => 'admin/list_blockchain',
    );

    my $valid = $c->validate_request_params(
        rows       => {required => 0, type => 'Int'},
        next_page  => {required => 0, type => 'Str'},
        filter     => {required => 0, type => 'Str'},
        cliente_id => {required => 0, type => 'Int'},
    );
    my $rows = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $offset = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'BLOCKCHAIN:NP';
        $offset = $tmp->{offset};
    }

    my $rs = $c->schema->resultset('BlockchainRecord')->search(
        {
            ($ENV{ADMIN_FILTER_CLIENTE_ID} ? ('me.cliente_id' => $ENV{ADMIN_FILTER_CLIENTE_ID}) : ()),
            ($valid->{cliente_id}          ? ('me.cliente_id' => $valid->{cliente_id})          : ()),
        },
        {
            order_by   => \'me.id DESC',
            join       => [qw/ticket cliente/],
            '+columns' => [
                {
                    cliente_nome_completo => 'cliente.nome_completo',
                    ticket_protocol       => 'ticket.protocol',
                }
            ],
        }
    );

    $valid->{filter} ||= 'all';
    my $filters = {
        all      => {},
        pending  => {'me.decred_merkle_root' => undef},
        anchored => {'me.decred_merkle_root' => {'!=' => undef}},
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
            iss    => 'BLOCKCHAIN:NP',
            offset => $offset + $cur_count,
        },
        1
    );

    return $c->respond_to_if_web(
        json => {
            json => {
                rows => [
                    map { {digest => $_->digest} } @rows,
                ],
                has_more  => $has_more,
                next_page => $has_more ? $next_page : undef,
                filter    => $valid->{filter},

            }
        },
        html => {
            filter      => $valid->{filter},
            filter_opts => [
                {id => 'all',      label => 'Todos os registros'},
                {id => 'pending',  label => 'Aguardando ancoragem'},
                {id => 'anchored', label => 'Ancorado'},
            ],
            rows      => \@rows,
            has_more  => $has_more,
            next_page => $has_more ? $next_page : undef,
        },
    );
}


1;
