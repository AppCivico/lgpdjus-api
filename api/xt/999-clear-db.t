use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Lgpdjus::Test;
my $t = test_instance;

use DateTime;

my $schema = $t->app->schema;

my $ids = [
    map { $_->id } $schema->resultset('Cliente')->search(
        {
            email         => {'like' => '%@autotests.com'},
        },

    )->all
];

user_cleanup(user_id => $ids) if @$ids > 0;
ok('1', 'ok');

done_testing();

exit;
