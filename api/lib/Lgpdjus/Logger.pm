package Lgpdjus::Logger;
use strict;
use warnings;

use DateTime;
use IO::Handle;
use Log::Log4perl qw(:levels);
use Lgpdjus::Utils qw(is_test);
use Carp qw/croak/;
our @ISA = qw(Exporter);

our @EXPORT = qw(
  log_info log_fatal log_error get_logger log_trace log_warn log_debug
  slog_info slog_fatal slog_error slog_trace slog_warn slog_debug
);

our $instance;

sub get_logger {

    return $instance if $instance;

    my $test_is_folder;
    if (@ARGV) {
        $test_is_folder = $ARGV[-1] eq 't' || $ARGV[-1] eq 't/' || $ARGV[-1] eq './t' || $ARGV[-1] eq './t/';
    }

    if ($ENV{LGPDJUS_API_LOG_DIR}) {
        print STDERR sprintf "LGPDJUS_API_LOG_DIR configured AS %s\n", $ENV{LGPDJUS_API_LOG_DIR};
        if (-d $ENV{LGPDJUS_API_LOG_DIR}) {
            my $date_now = DateTime->now->ymd('-');

            # vai ter q rever isso, quando é mojo..
            my $app_type = $0 =~ /\.psgi/ ? 'api' : &_extract_basename($0);

            my $log_file = $app_type eq 'api' ? "api.$date_now.$$" : "$app_type.$date_now";

            $ENV{LGPDJUS_API_LOG_DIR} = $ENV{LGPDJUS_API_LOG_DIR} . "/$log_file.log";
            print STDERR "Redirecting STDERR/STDOUT to $ENV{LGPDJUS_API_LOG_DIR}\n";
            close(STDERR);
            close(STDOUT);
            autoflush STDERR 1;
            autoflush STDOUT 1;
            open(STDERR, '>>', $ENV{LGPDJUS_API_LOG_DIR}) or die 'cannot redirect STDERR';
            open(STDOUT, '>>', $ENV{LGPDJUS_API_LOG_DIR}) or die 'cannot redirect STDOUT';

        }
        else {
            print STDERR "LGPDJUS_API_LOG_DIR is not a dir\n";
        }
    }
    else {
        print STDERR "LGPDJUS_API_LOG_DIR not configured\n";
    }

    Log::Log4perl->easy_init(
        {
            level  => $DEBUG,
            layout =>
              (is_test() && $test_is_folder ? '' : '[%d{dd/MM/yyyy HH:mm:ss.SSS}] [%p{4} %P] %x %m{indent=1}%n'),
            ($ENV{LGPDJUS_API_LOG_DIR} ? (file => '>>' . $ENV{LGPDJUS_API_LOG_DIR}) : ()),
            'utf8'    => 1,
            autoflush => 1,

        }
    );

    return $instance = Log::Log4perl::get_logger;
}

# logs
sub log_info {
    my (@texts) = @_;
    get_logger()->info(join ' ', @texts);
}

sub log_warn {
    my (@texts) = @_;
    get_logger()->warn(join ' ', @texts);
}

sub log_error {
    my (@texts) = @_;
    get_logger()->error(join ' ', @texts);
}

sub log_fatal {
    my (@texts) = @_;
    my $text    = join ' ', @texts;
    get_logger()->fatal($text);
    croak $text;
}

sub log_debug {
    my (@texts) = @_;
    get_logger()->debug(join ' ', @texts);
}


sub slog_info {
    get_logger()->info(sprintf shift(), @_);
}

sub slog_warn {
    get_logger()->warn(sprintf shift(), @_);
}

sub slog_error {
    get_logger()->error(sprintf shift(), @_);
}

sub slog_fatal {
    my (@texts) = @_;
    my $text    = sprintf shift(), @_;
    get_logger()->fatal($text);
    croak $text;
}

sub slog_debug {
    get_logger()->debug(sprintf shift(), @_);
}


sub _extract_basename {
    my ($path) = @_;
    my ($part) = $path =~ /.+(?:\/(.+))$/;
    return lc($part);
}

sub log_trace {
    return unless is_test();

    push @Lgpdjus::Test::trace_logs, @_;
}

1;
