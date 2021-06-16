package Lgpdjus::Controller::Admin::BigNum;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;

sub abignum_get {
    my $c = shift;
    $c->stash(
        template => 'admin/big_num',
    );

    my $rs = $c->schema->resultset('AdminBigNumber')->search(
        {
            status => 'published',
        },
        {
            order_by     => 'sort',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );
    my @results;

    while (my $r = $rs->next) {
        my ($column1) = $c->schema->storage->dbh->selectrow_array($r->{sql});

        $r->{number} = $column1;
        push @results, $r;
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                results => \@results,
            }
        },
        html => {
            results => \@results,
        },
    );
}


1;
