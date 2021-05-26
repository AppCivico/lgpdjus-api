package Lgpdjus::Helpers::Html2Pdf;
use common::sense;
use Carp qw/confess /;
use utf8;
use Scope::OnExit;

use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils qw/is_test/;

use File::Temp qw/ tempfile  /;

use MIME::Base64 qw(encode_base64);
use Encode qw(encode);

my $wkhtmltopdf_bin;
my $wkhtmltopdf_server;
my $wkhtmltopdf_type;

sub setup {
    my $self = shift;

    $ENV{WKHTMLTOPDF_SERVER_TYPE} = 'dev-with-x' if is_test() && !$ENV{WKHTMLTOPDF_HTTP_TEST};

    $wkhtmltopdf_type = $ENV{WKHTMLTOPDF_SERVER_TYPE} || 'dev-with-x';

    if ($wkhtmltopdf_type eq 'dev-with-x') {
        $wkhtmltopdf_bin = $ENV{WKHTMLTOPDF_BIN} || 'wkhtmltopdf';
        my $command = "$wkhtmltopdf_bin --version";
        `$command`;
        if ($? == -1) {
            log_fatal
              "$command failed to execute: $!\nPlease check if wkhtmltopdf is installed or set WKHTMLTOPDF_BIN to the binary\n";
        }
        elsif ($? & 127) {
            slog_fatal "$command child died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? 'with' : 'without';
        }
        elsif ($? != 0) {
            slog_fatal "$command child exited with value %d\n", $? >> 8;
        }
    }
    elsif ($wkhtmltopdf_type eq 'http') {

        $wkhtmltopdf_server = $ENV{WKHTMLTOPDF_HTTP};
        die 'missing value for WKHTMLTOPDF_HTTP' unless $wkhtmltopdf_server;
        die "invalid value for WKHTMLTOPDF_HTTP: $wkhtmltopdf_server must begin with http"
          unless $wkhtmltopdf_server =~ /^http/;
        $wkhtmltopdf_server =~ s/\/$//;
    }
    else {
        log_fatal(
                "Env WKHTMLTOPDF_SERVER_TYPE '$wkhtmltopdf_type' is not valid. use 'dev-with-x' and set WKHTMLTOPDF_BIN"
              . " or 'http' and set WKHTMLTOPDF_HTTP to oberonamsterdam/wkhtmltopdf container http ip and port");
    }

    $self->helper('html2pdf' => sub { &html2pdf(@_) });
}

sub html2pdf {
    my ($c, %opts) = @_;
    my $html = $opts{html} or confess 'missing html';

    my ($fh, $pdf_file_name);
    if ($opts{output_file}) {
        $pdf_file_name = $opts{output_file};
    }
    else {
        ($fh, $pdf_file_name) = tempfile(SUFFIX => '.pdf', UNLINK => 0);
        close $fh;
    }
    use DDP;

    # metodo pra rodar em maquinas locais com X disponível
    if ($wkhtmltopdf_type eq 'dev-with-x') {

        my ($html_fh, $html_file_name) = tempfile(SUFFIX => '.html', UNLINK => 0);
        on_scope_exit { unlink($html_file_name) };

        print $html_fh $html;
        close $html_fh;

        my $command = "$wkhtmltopdf_bin $html_file_name $pdf_file_name";
        `$command`;
        if ($? == -1) {
            log_fatal
              "$command failed to execute: $!\nPlease check if wkhtmltopdf is installed or set WKHTMLTOPDF_BIN to the binary\n";
        }
        elsif ($? & 127) {
            slog_fatal "$command child died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? 'with' : 'without';
        }
        elsif ($? != 0) {
            slog_fatal "$command child exited with value %d\n", $? >> 8;
        }
    }
    elsif ($wkhtmltopdf_type eq 'http') {
        $c->ua->post(
            $wkhtmltopdf_server, {
                'content-type' => 'application/json'
            }, json => {contents => encode_base64(encode("UTF-8", $opts{html}))}
        )->result->save_to($pdf_file_name);
    }
    else {
        die "unknown WKHTMLTOPDF_SERVER_TYPE $wkhtmltopdf_type config";
    }

    return $pdf_file_name;
}

1;
