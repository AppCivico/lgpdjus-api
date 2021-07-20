package Lgpdjus::Helpers;
use Mojo::Base -base;
use Lgpdjus::SchemaConnected;
use Lgpdjus::Controller;

use Lgpdjus::Helpers::Quiz;
use Lgpdjus::Helpers::Tickets;
use Lgpdjus::Helpers::Blockchain;
use Lgpdjus::Helpers::PdfExporter;
use Lgpdjus::Helpers::Html2Pdf;
use Lgpdjus::KeyValueStorage;
use Lgpdjus::Helpers::CitizenEmail;
use Lgpdjus::Helpers::Notifications;
use Lgpdjus::Helpers::WebHelpers;

use Carp qw/croak confess/;

sub setup {
    my $c = shift;

    Lgpdjus::Helpers::Quiz::setup($c);
    Lgpdjus::Helpers::Tickets::setup($c);
    Lgpdjus::Helpers::Blockchain::setup($c);
    Lgpdjus::Helpers::Html2Pdf::setup($c);
    Lgpdjus::Helpers::CitizenEmail::setup($c);
    Lgpdjus::Helpers::PdfExporter::setup($c);
    Lgpdjus::Helpers::Notifications::setup($c);
    Lgpdjus::Helpers::WebHelpers::setup($c);

    state $kv = Lgpdjus::KeyValueStorage->instance;
    $c->helper(kv                    => sub {$kv});
    $c->helper(sum_cpf_errors        => \&sum_cpf_errors);
    $c->helper(rs_user_by_preference => \&rs_user_by_preference);

    $c->helper(
        assert_user_has_module => sub {
            my $c      = shift;
            my $module = shift or confess 'missing param $module';

            my $user_obj = $c->stash('user_obj') or confess 'missing stash.user_obj';

            $c->log->info(
                "Asserting user has access to module '$module' - user modules is: " . $user_obj->access_modules_str());

            die {status => 400, error => 'missing_module', message => "Você não tem acesso ao modulo $module",}
              unless $user_obj->has_module($module);

            return;
        }
    );

    $c->helper(
        accept_html => sub {
            my $c = shift;
            return ($c->req->headers->header('accept') || '') =~ /html/ ? 1 : 0;
        }
    );

    $c->helper(
        remote_addr => sub {
            my $c = shift;

            foreach my $place (@{['cf-connecting-ip', 'x-real-ip', 'x-forwarded-for', 'tx']}) {
                if ($place eq 'cf-connecting-ip') {
                    my $ip = $c->req->headers->header('cf-connecting-ip');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-real-ip') {
                    my $ip = $c->req->headers->header('X-Real-IP');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-forwarded-for') {
                    my $ip = $c->req->headers->header('X-Forwarded-For');
                    return $ip if $ip;
                }
                elsif ($place eq 'tx') {
                    my $ip = $c->tx->remote_address;
                    return $ip if $ip;
                }
            }

            return;
        },
    );

    $c->helper(
        'nl2br' => sub {
            my ($c, $text) = @_;
            $text =~ s/(\r\n|\n\r|\n|\r)/<br\/>$1/g;
            return $text;
        }
    );

    $c->helper('reply.exception' => sub { Lgpdjus::Controller::reply_exception(@_) });
    $c->helper('reply.not_found' => sub { Lgpdjus::Controller::reply_not_found(@_) });
    $c->helper('user_not_found'  => sub { Lgpdjus::Controller::reply_not_found(@_, type => 'user_not_found') });

    $c->helper('reply_invalid_param' => sub { Lgpdjus::Controller::reply_invalid_param(@_) });
}


=pod
create view view_user_preferences as
   SELECT
        p.name,
        c.id as cliente_id,
        coalesce(cp.value, p.initial_value) as value
    FROM preferences p
    CROSS JOIN clientes c
    LEFT JOIN clientes_preferences cp ON cp.cliente_id = c.id AND cp.preference_id = p.id;
=cut

sub rs_user_by_preference {
    my ($c, $pref_name, $pref_value, $as_hashref) = @_;

    $as_hashref ||= 1;

    my $rs = $c->schema->resultset('ViewUserPreference')->search(
        {
            name  => $pref_name,
            value => $pref_value,
        },
        {
            columns => 'cliente_id',
            ($as_hashref ? (result_class => 'DBIx::Class::ResultClass::HashRefInflator') : ())
        }
    );
    return $rs;

}

1;
