#<<<
use utf8;
package Lgpdjus::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-12 14:21:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lgYcnuze01R9JIRHYkTISA

use Lgpdjus::Logger;
my $_variables_loaded = 0;
use Lgpdjus::Utils qw/random_string/;

use Carp;

sub sum_login_errors {
    my ($self, %opts) = @_;

    return $self->resultset('LoginErro')->search(
        {
            'created_at' => {'>' => DateTime->now->add(minutes => -60)->datetime(' ')},
            'cliente_id' => ($opts{cliente_id} or croak 'missing cliente_id'),
        }
    )->count();
}

sub get_jwt_key {
    my ($self) = @_;

    my $secret = delete $ENV{JWT_SECRET_KEY};
    die 'ENV variables not loaded' unless ++$_variables_loaded;

    # Se não estiverem configuradas, vamos iniciar uma.
    if (!$secret) {
        die;
        $secret = random_string(64);
        $self->txn_do(
            sub {
                $self->storage->dbh->do(
                    <<'SQL_QUERY', undef,
                    INSERT INTO lgpdjus_config ("name", "value") VALUES (?, ?)
                    ON CONFLICT (name)
                    WHERE valid_to = 'infinity'
                    DO UPDATE SET value = EXCLUDED.value;
SQL_QUERY
                    ('JWT_SECRET_KEY', $secret,)
                );
            }
        );
    }

    return $secret;
}

use DateTime::Format::DateParse;

sub now {
    my $self = shift;

    my $now = $self->storage->dbh_do(
        sub {
            DateTime::Format::DateParse->parse_datetime($_[1]->selectrow_array('SELECT replaceable_now()'));
        }
    );

    return $now;
}

sub unaccent {
    my $self = shift;
    my $text = shift;
    return undef unless defined $text;
    return '' if $text eq '';
    return $self->storage->dbh_do(
        sub {
            $_[1]->selectrow_array('SELECT unaccent(?)', {}, $text);
        }
    );
}

1;
