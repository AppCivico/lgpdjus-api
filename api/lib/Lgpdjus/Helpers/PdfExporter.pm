package Lgpdjus::Helpers::PdfExporter;
use common::sense;
use Carp qw/confess /;
use utf8;
use Scope::OnExit;
use Mojo::Util qw/dumper/;

use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;

use File::Temp qw/ tempfile  /;


sub setup {
    my $self = shift;

    $self->helper('generate_ticket_pdf'  => sub { &generate_ticket_pdf(@_) });
    $self->helper('generate_account_pdf' => sub { &generate_account_pdf(@_) });
}

sub generate_ticket_pdf {
    my ($c, %opts) = @_;
    my $ticket = $opts{ticket} or confess 'missing ticket';

    my $vars = {
        ticket         => $ticket,
        cliente        => {$ticket->cliente->columns()},
        details_html   => $ticket->html_detail(c => $c, admin => 0, pdf => 1),
        responses_html => $ticket->html_ticket_responses(c => $c, pdf => 1, admin => 0),

    };

    local $c->stash->{layout} = undef;
    my $html = $c->render_to_string('parts/ticket_pdf', format => 'html', %$vars);

    my $filename = $c->html2pdf(html => $html, output_file => $opts{output_file});

    return $filename;
}

sub generate_account_pdf {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    my $vars = {account_html => $user_obj->account_html(c => $c)};

    local $c->stash->{layout} = undef;
    my $html = $c->render_to_string('parts/account_pdf', format => 'html', %$vars);

    my $filename = $c->html2pdf(html => $html, output_file => $opts{output_file});

    return $filename;
}


1;
