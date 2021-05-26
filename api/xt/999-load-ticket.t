use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Lgpdjus::Test;
my $t = test_instance;

use DateTime;

my $schema = $t->app->schema;

my $ticket = $schema->resultset('Ticket')->find(329);


$t->app->generate_ticket_pdf(ticket => $ticket, output_file => '/tmp/foo.pdf');


done_testing();

exit;
