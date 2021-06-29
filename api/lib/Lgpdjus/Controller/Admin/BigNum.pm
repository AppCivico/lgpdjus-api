package Lgpdjus::Controller::Admin::BigNum;
use Mojo::Base 'Lgpdjus::Controller';
use utf8;
use JSON;
use Lgpdjus::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Crypt::JWT qw(encode_jwt decode_jwt);
use Mojo::URL;

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

    my @rows = (
        {name => 'Resumo manifestantes', resource => {dashboard => 1}, params => {}},
    );
    my $metabase_secret = $ENV{METABASE_SECRET} || 'secret';
    my @ret             = ();
    foreach my $payload (@rows) {
        $payload->{_}{admin_user} = $c->stash('admin_user')->id;
        $payload->{exp} = time() + 3600;                           # 1 hour

        my $jwt = encode_jwt(
            alg     => 'HS256',
            key     => $metabase_secret,
            payload => $payload
        );
        my $url = Mojo::URL->new('https://lgpdjus-metabase.appcivico.com/');
        $url->path('/embed/dashboard/' . $jwt);
        $url->fragment('bordered=false&titled=false');

        push @ret, {
            name => $payload->{name},
            url  => $url->to_string(),
        };
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                results => \@results,
                reports => \@ret,
            }
        },
        html => {
            results => \@results,
            reports => \@ret,

        },
    );
}


1;
