package Lgpdjus::Helpers::Blockchain;
use common::sense;
use Carp qw/confess /;
use utf8;
use Scope::OnExit;
use Mojo::Util qw/dumper/;
use Digest::SHA;
use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;

use Lgpdjus::Uploader;


sub setup {
    my $self = shift;

    $self->helper('add_to_blockchain' => sub { &add_to_blockchain(@_) });
    $self->helper('verify_blockchain' => sub { &verify_blockchain(@_) });

}

sub add_to_blockchain {
    my ($c, %opts) = @_;
    my $file        = $opts{file}       or confess 'missing file';
    my $name        = $opts{name}       or confess 'missing name';
    my $cliente_id  = $opts{cliente_id} or confess 'missing cliente_id';
    my $file_info   = $opts{file_info}  or confess 'missing file_info';
    my $ticket_id   = $opts{ticket_id};
    my $helper      = $opts{helper};
    my $helper_opts = $opts{helper_opts};

    slog_info('add_to_blockchain %s as %s, cliente_id %s', $file, $name, $cliente_id);

    my $uploader = Lgpdjus::Uploader->instance();

    open my $fh, '<:raw', $file or die "cannot open $file $!";

    my $sha256 = Digest::SHA->new(256);
    $sha256->addfile($fh);
    my $digest = lc($sha256->hexdigest);
    close $fh;

    my $dbh_pg    = $c->schema->storage->dbh;
    my $now       = DateTime->now;
    my $id        = $dbh_pg->selectrow_arrayref("select uuid_generate_v4()", {Slice => {}})->[0];
    my $s3_prefix = sprintf(
        '%s/cliente_%d/%sT%s.%s',
        'blockchain',
        $cliente_id,
        $now->date('-'),
        $now->hms(''),
        $id
    );

    my $remote_path = $uploader->upload(
        {
            path => $s3_prefix,
            file => $file,
            type => 'application/octet-stream',
        }
    );

    my $media_upload;
    $c->schema->txn_do(
        sub {

            if (
                $c->schema->resultset('BlockchainRecord')->search(
                    {
                        digest => $digest,
                    }
                )->count > 0
              )
            {
                slog_info('File digest already exists on BlockchainRecord!');
            }
            else {
                my $media_upload = $c->schema->resultset('MediaUpload')->create(
                    {
                        id               => $id,
                        file_info        => to_json($file_info),
                        file_size        => -s $file,
                        s3_path          => $remote_path,
                        file_sha1        => "SHA256:$digest",
                        intention        => 'blockchain',
                        cliente_id       => $cliente_id,
                        created_at       => \'now()',
                        is_on_blockchain => 1,
                    }
                );
                slog_info('Digest is %s, media_upload_id %s', $digest, $media_upload->id);

                my $register;
                for (1 .. 10) {
                    $register = $c->ua->post(
                        'https://time.decred.org:49152/v1/timestamp/',
                        json => {
                            id      => 'lgpdjus',
                            digests => [$digest]
                        }
                    )->result;
                    if ($register->code == 200) {
                        slog_info('decred response %s', $register->to_string);
                        last;
                    }
                    else {
                        slog_info('decred response %s, trying again...', $register->to_string);
                        sleep 1;
                    }
                }
                die(sprintf 'decred response %s, cannot continue with add_to_blockchain', $register->to_string)
                  unless $register->code == 200;

                my $record = $c->schema->resultset('BlockchainRecord')->create(
                    {
                        filename        => $name,
                        digest          => $digest,
                        media_upload_id => $media_upload->id,
                        created_at      => \['to_timestamp(?)', $register->json->{servertimestamp}],
                        ticket_id       => $ticket_id,
                        cliente_id      => $cliente_id,
                    }
                );

                my $job_id = $c->minion->enqueue(
                    'verify_blockchain',
                    [
                        $record->id,
                    ] => {
                        attempts => 50,
                        delay    => 3600,
                    }
                );
                slog_info('Adding job verify_blockchain %s, job id %s in 3600 seconds', $record->id, $job_id);

                if ($helper) {
                    $c->log->info("calling helper $helper inside transaction");
                    $c->$helper(
                        file       => $file,
                        name       => $name,
                        cliente_id => $cliente_id,
                        file_info  => $file_info,
                        ticket_id  => $ticket_id,
                        ($helper_opts ? (%$helper_opts) : ()),
                    );
                }

            }
        }
    );

    return 1;
}

sub verify_blockchain {
    my ($c, %opts) = @_;

    my $blockchain_record_id = $opts{blockchain_record_id} or confess 'missing blockchain_record_id';

    my $record = $c->schema->resultset('BlockchainRecord')->search({id => $blockchain_record_id})->next
      or die "record $blockchain_record_id not found BlockchainRecord";

    my $verify;

    for (1 .. 10) {
        $verify = $c->ua->post(
            'https://time.decred.org:49152/v1/verify/',
            json => {
                id      => 'lgpdjus',
                digests => [$record->digest]
            }
        )->result;
        if ($verify->code == 200) {
            slog_info('decred response %s', $verify->to_string);
            last;
        }
        else {
            slog_info('decred response %s, trying again...', $verify->to_string);
            sleep 5;
        }
    }
    slog_info('decred response %s, cannot verify now!', $verify->to_string) unless $verify->code == 200;

    my $json  = $verify->json;
    my $chain = $json->{digests}[0]{chaininformation};
    if (   $chain->{merkleroot} ne '0000000000000000000000000000000000000000000000000000000000000000'
        && $chain->{transaction} ne '0000000000000000000000000000000000000000000000000000000000000000'
        && $chain->{chaintimestamp} > 0)
    {
        slog_info('updating record');
        my $update = $record->update(
            {
                dcrtime_timestamp   => \['to_timestamp(?)', $chain->{chaintimestamp}],
                decred_merkle_root  => $chain->{merkleroot},
                decred_capture_txid => $chain->{transaction},
            }
        );
        return 1;
    }
    slog_info('not anchored');

    return 0;
}

1;
