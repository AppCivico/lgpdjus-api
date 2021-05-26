package Lgpdjus::Helpers::CitizenEmail;
use common::sense;
use Carp qw/confess /;
use utf8;
use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;
use MIME::Base64;

sub setup {
    my $self = shift;

    $self->helper('cliente_send_email' => sub { &cliente_send_email(@_) });
}

sub cliente_send_email {
    my ($c, %opts) = @_;

    my $file       = $opts{file}       or confess 'missing file';
    my $name       = $opts{name}       or confess 'missing name';
    my $template   = $opts{template}   or confess 'missing template';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';
    my $ticket_id  = $opts{ticket_id};

    my $content = '';
    open my $fh, '<:raw', $file or die sprintf 'cannot read %s %s', $file, $!;
    $content .= $_ while <$fh>;
    close $fh;

    my $cliente = $c->schema->resultset('Cliente')->find($cliente_id)
      or die sprintf 'cannot find cliente_id %s', $cliente_id;

    my $ticket = $ticket_id ? $c->schema->resultset('Ticket')->find($ticket_id) : undef;
    die sprintf 'cannot find ticket_id %s', $ticket_id if $ticket_id && !$ticket;

    my $config = $c->schema->resultset('Configuraco')->next;

    my ($email_config) = grep { $_->{template} eq $template } @{from_json($config->email_config)};
    die sprintf 'cannot find template=%s on %s', $template, $config->email_config unless $email_config;
    my $variables = {
        ticket  => $ticket ? $ticket->as_hashref() : undef,
        cliente => $cliente->as_hashref(),
    };

    my $subject = tt_render($email_config->{subject}, $variables);
    my $body    = tt_render($email_config->{body},    $variables);

    my $email = $c->schema->resultset('EmaildbQueue')->create(
        {
            to        => $cliente->email,
            template  => $email_config->{template_file} || 'generic.html',
            subject   => $subject,
            config_id => $ENV{EMAILDB_CONFIG_ID} || 1,
            variables => to_json(
                {
                    attachments_config => {
                        files => [
                            {
                                name         => $name,
                                content      => encode_base64($content),
                                content_type => 'application/pdf'
                            },
                        ]
                    },
                    ($ENV{EMAILDB_REPLY_TO} ? ('reply-to' => $ENV{EMAILDB_REPLY_TO}) : ()),
                    body => $body,
                },
            ),


        }
    );
    slog_info('created email %s', $email->id);
    log_trace(['citizen_email', $template, $email->id]);

    if ($email_config->{notification_enabled} && $email_config->{notification_title}) {
        my $ntf_title   = tt_render($email_config->{notification_title},   $variables);
        my $ntf_content = tt_render($email_config->{notification_content}, $variables);

        &_new_notification($c, $cliente, $ntf_title, $ntf_content);
    }

    return 1;
}


sub _new_notification {
    my ($c, $cliente, $title, $content) = @_;

    my $schema = $c->schema;    # mysql
    my $logger = $c->log;

    my $message = {
        is_test    => is_test() ? 1 : 0,
        title      => $title,
        content    => $content,
        meta       => to_json({cliente_id => $cliente->id}),
        created_at => \'now()',
        icon       => 1,
    };

    my $preference_name = 'NOTIFY_BY_APP';
    my @clientes        = $c->rs_user_by_preference($preference_name, '1')->search(
        {
            cliente_id => $cliente->id,
        }
    )->all;

    log_trace($preference_name, scalar @clientes);

    # nao tem nenhum habilitado, entao nao precisa nem criar a mensagem
    return unless @clientes;


    $schema->txn_do(
        sub {
            my $message_row = $schema->resultset('NotificationMessage')->create($message);
            slog_info('notification message %s', $message_row->id);
            log_trace(['citizen_notification', $message_row->id]);

            $schema->resultset('NotificationLog')->populate(
                [
                    [qw/cliente_id notification_message_id created_at/],
                    map {
                        [
                            $_->{cliente_id},
                            $message_row->id,
                            \'NOW()'
                        ]
                    } @clientes
                ]
            );
        }
    );

    $c->user_notifications_clear_cache($_->{cliente_id}) for @clientes;

    return (
        clientes => \@clientes,
    );
}
1;
