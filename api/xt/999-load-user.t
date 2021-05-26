use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Lgpdjus::Test;
my $t = test_instance;

use DateTime;

my $schema = $t->app->schema;

my $user_obj = $schema->resultset('Cliente')->next;

=pod
$t->app->generate_account_pdf(user_obj => $user_obj, output_file => '/tmp/foo.pdf');

$t->app->add_to_blockchain(
    cliente_id => $user_obj->id,
    name       => 'foo.pdf',
    file_info  => {},
    file       => '/tmp/foo.pdf',
);
=cut

my $x = $t->app->minion->enqueue(
    'generate_pdf_and_blockchain',
    ['account', $user_obj->id] => {
        attempts => 5,
    }
);

use DDP; p $x;
ok $x;

done_testing();

exit;
