package Lgpdjus::Tasks;
use Mojo::Base -role;

use Lgpdjus::SchemaConnected;

requires qw(do);

has schema => sub { get_schema() };

sub register {
    my $app = shift;


}

1;
