package Lgpdjus::Minion::Tasks::DeleteTicketAttachment;
use Mojo::Base 'Mojolicious::Plugin';
use Lgpdjus::Utils qw/is_test/;
use JSON;
use utf8;
use Lgpdjus::Logger;
use Lgpdjus::Uploader;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(ticket_remove_attachments => \&ticket_remove_attachments);
}

sub ticket_remove_attachments {
    my ($job, $ticket_id) = @_;

    log_trace("minion:ticket_remove_attachments", $ticket_id);
    my $schema = $job->app->schema;    # pg

    my $logger = $job->app->log;

    my $ticket = $schema->resultset('Ticket')->find($ticket_id);
    die 'ticket not found' if !$ticket;

    my @medias = map {
        my $r = from_json($_);
        @{$r}
    } $ticket->tickets_responses->get_column('cliente_attachments')->all;

    my $content = from_json($ticket->content);
    foreach my $quiz_item ($content->{quiz}->@*) {
        my $type = $quiz_item->{type};
        next unless $type eq 'photo_attachment';

        my $response = $content->{responses}{$quiz_item->{code}};
        push @medias, $response;
    }

    my $s3       = Lgpdjus::Uploader->new();
    my $media_rs = $schema->resultset('MediaUpload')->search(
        {
            cliente_id => $ticket->cliente_id,
            id         => {'in' => \@medias},

            (
                is_test() ? () : (
                    is_on_blockchain => 0,
                )
            ),
        }
    );

    my $sum_deleted_bytes = 0;
    while (my $r = $media_rs->next) {

        $s3->remove_by_uri($r->s3_path);
        $s3->remove_by_uri($r->s3_path_avatar) if $r->s3_path_avatar;

        $sum_deleted_bytes += $r->file_size;
        $sum_deleted_bytes += $r->file_size_avatar if $r->file_size_avatar;

        $logger->info("removing media " . $r->id);

        $r->delete;
    }
    $logger->info("s3 deleted $sum_deleted_bytes bytes");

    return $job->finish(1);
}

1;
