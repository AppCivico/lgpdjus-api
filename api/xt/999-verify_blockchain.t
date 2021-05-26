use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Lgpdjus::Test;
my $t = test_instance;

use DateTime;

my $schema = $t->app->schema;

my $user_obj = $schema->resultset('Cliente')->next;


$t->app->verify_blockchain(blockchain_record_id => 4);


done_testing();

exit;
