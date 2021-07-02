package Lgpdjus::Helpers::WebHelpers;
use common::sense;
use Carp qw/confess croak/;
use utf8;
use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;
use JSON;

sub setup {
    my $c = shift;

    $c->helper(respond_to_if_web => \&respond_to_if_web);
    $c->helper(flash_to_redis    => \&flash_to_redis);
    $c->helper(use_redis_flash   => \&use_redis_flash);
    $c->helper(web_link_to       => \&web_link_to);
    $c->helper(dpo_send_email       => \&dpo_send_email);


}

sub respond_to_if_web {
    my $c = shift;

    my $accept = $c->req->headers->header('accept');
    if (($c->stash('template') || $c->stash('use_flash_return')) && $accept && $accept =~ /html/) {
        my $ref_header = $c->req->headers->header('referer');
        if ($c->stash('use_flash_return')) {
            if (!$ref_header) {
                goto JSON;
            }
            else {
                my (%keys) = @_;
                my $html = $keys{html};
                if (defined $html && ref $html eq 'HASH') {
                    $c->log->debug("saving to flash " . to_json($html));

                    $html->{params} = $c->req->params->to_hash;

                    $c->flash_to_redis($html);

                    return $c->redirect_to($ref_header);
                }
            }
        }

        $c->respond_to(@_);
    }
    else {
      JSON:
        my %opts = %{{@_}->{json}};
        die 'missing object json' unless $opts{json};
        $c->render(%opts);
    }
}

sub use_redis_flash {
    my $c = shift;

    $c->stash(pg_timestamp2human => \&pg_timestamp2human);

    my $flashredis = $c->flash('flashredis');
    if ($flashredis) {
        my $loaded = $c->kv->redis->get($flashredis);
        $c->kv->redis->del($flashredis);
        if ($loaded) {
            $loaded = from_json($loaded);
            $c->stash(%$loaded);
        }
    }

    $c->stash(use_flash_return => 1) if $c->req->method eq 'POST';
}

sub flash_to_redis {
    my $c         = shift;
    my $content   = shift;
    my $redis_key = 'flash' . random_string(10);
    $c->kv->redis->setex($redis_key, 15, to_json($content));
    $c->flash(flashredis => $redis_key);
}


sub web_link_to {
    my ($c, $basepath, %other) = @_;

    my $url = $basepath;
    if ($basepath eq 'current') {
        $url = $c->req->url->to_string();
    }
    $url = Mojo::URL->new($url);

    if (keys %other) {
        while (my ($method, $args) = each %other) {
            $url = $url->$method(@$args);
        }
    }

    $url = $url->to_string();
    return $url;
}

sub dpo_send_email {
    my ($c, %opts) = @_;

    my $template = $opts{template} or confess 'missing template';
    my $ticket   = $opts{ticket}   or confess 'missing ticket';

    my $config                = $c->schema->resultset('Configuraco')->next;
    my $dpo_email_destinatary = $config->dpo_email_destinatary() || '';

    $dpo_email_destinatary =~ s/^\s+//;
    $dpo_email_destinatary =~ s/\s+$//;

    if (!$dpo_email_destinatary) {
        slog_info('no dpo_email_destinatary was set');
        return;
    }

    my ($email_config) = grep { $_->{template} eq $template } @{from_json($config->dpo_email_config)};
    die sprintf 'cannot find template=%s on %s', $template, $config->email_config unless $email_config;
    my $variables = {
        ticket  => $ticket->as_hashref(),
        cliente => $ticket->cliente->as_hashref(),
    };

    my $subject = tt_render($email_config->{subject}, $variables);
    my $body    = tt_render($email_config->{body},    $variables);

    my @emails = split /\;/, $dpo_email_destinatary;

    foreach my $to (@emails) {
        next if is_test();

        my $email = $c->schema->resultset('EmaildbQueue')->create(
            {
                to        => $to,
                template  => $email_config->{template_file} || 'generic.html',
                subject   => $subject,
                config_id => $ENV{EMAILDB_CONFIG_ID} || 1,
                variables => to_json(
                    {
                        ($ENV{EMAILDB_REPLY_TO} ? ('reply-to' => $ENV{EMAILDB_REPLY_TO}) : ()),
                        body => $body,
                    },
                ),
            }
        );

        slog_info('DPO created email id %s to %s template %s', $email->id, $to, $template);
        log_trace(['dpo_email', $template, $email->id]);
    }

    return 1;
}


1;
