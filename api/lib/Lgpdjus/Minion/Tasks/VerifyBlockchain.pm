package Lgpdjus::Minion::Tasks::VerifyBlockchain;
use Mojo::Base 'Mojolicious::Plugin';
use utf8;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(verify_blockchain => \&job_verify_blockchain);
}

sub job_verify_blockchain {
    my ($job, $record_id) = @_;

    die "not anchored yet" unless $job->app->verify_blockchain(blockchain_record_id => $record_id);

  OK:
    return $job->finish(1);
}

1;
