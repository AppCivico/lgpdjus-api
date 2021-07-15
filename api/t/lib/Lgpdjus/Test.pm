package Mojo::Transaction::Role::PrettyDebug {
    use Mojo::Base -role;
    use Mojo::Util 'term_escape';
    use DDP;

    use constant PRETTY => $ENV{TRACE} || $ENV{MOJO_CLIENT_PRETTY_DEBUG} || 0;

    after client_read => sub {
        my ($self, $chunk) = @_;
        my $url = $self->req->url->to_abs;
        my $err = $chunk =~ /1\.1\s[45]0/ ? '31' : '32';

        if (PRETTY) {
            my $tmp
              = $self->res->json && !$ENV{TRACE_JSON}
              ? $self->res->code . ' '
              . $self->res->message . "\n"
              . $self->res->headers->to_string() . "\n"
              . np($self->res->json, caller_info => 0)
              : term_escape($chunk);

            warn "\x{1b}[${err}m" . term_escape("-- Server response for $url\n") . $tmp . "\x{1b}[0m\n";


        }
    };

    around client_write => sub {
        my $orig  = shift;
        my $self  = shift;
        my $chunk = $self->$orig(@_);
        my $url   = $self->req->url->to_abs;
        warn "\x{1b}[32m" . term_escape("-- Client requesting $url...\n$chunk") . "\x{1b}[0m\n" if PRETTY;
        return $chunk;
    };
};

package Lgpdjus::Test;
use Mojo::Base -strict;
use Test2::V0;
use Test2::Plugin::BailOnFail;
use Test2::Tools::Subtest qw(subtest_buffered subtest_streamed);
use Test2::Mock;
use Test::Mojo;
use Minion;
use Minion::Job;
use Lgpdjus::Logger;
use Digest::SHA qw/sha256_hex/;
my $redis_ns;

sub END {
    if (defined $redis_ns) {
        my $redis = app()->kv->instance->redis;
        my @del   = $redis->keys($redis_ns . '*');
        $redis->del(@del) if @del;
    }
}

use DateTime;
use Lgpdjus::Utils;
use Data::Fake qw/ Core Company Dates Internet Names Text /;
use Data::Printer;
use Mojo::Util qw(monkey_patch);
use JSON;
use Mojo::JSON qw(true false);
use Scope::OnExit;
our @trace_logs;

sub trace_popall {
    my @list = @trace_logs;

    @trace_logs = ();

    return join ',', @list;
}

sub trace_grep {
    my $grep_value = shift();
    my @found;

    foreach (@trace_logs) {
        next if ref $_ ne 'ARRAY';
        my ($key, @values) = @$_;
        push @found, @values if $key eq $grep_value;
    }
    return wantarray ? @found : $found[0];
}

our $_minion_job_id   = 0;
our $minion_jobs_args = {};
our %minion_mock      = (

    minion => Test2::Mock->new(
        track    => 0,
        class    => 'Minion',
        override => [
            add_task => sub { $_[0] },
            enqueue  => sub {
                my ($minion, $task, $args) = @_;
                my $job_id = $_minion_job_id++;
                $minion_jobs_args->{$job_id} = from_json(to_json($args));
                return $job_id;
            },
        ],
    ),

    job => Test2::Mock->new(track => 0, class => 'Minion::Job', override => [finish => sub { shift; @_ },],),
);

my $admin_email    = $ENV{DIRECTUS_ADMIN_USER_EMAIL} || 'tests.automatic@example.com';
my $admin_password = $ENV{DIRECTUS_ADMIN_USER_PWD}   || 'ifyouare555';


sub test_get_minion_args_job {
    my @args = @{$minion_jobs_args->{shift()} || []};
    return wantarray ? @args : \@args;
}

sub import {
    strict->import;

    $ENV{DIRECUTS_API_TOKEN}  = 'SSzNpkUCVo1g2G4JxL5MnaM6';
    $ENV{DISABLE_RPS_LIMITER} = 1;
    srand(time() ^ ($$ + ($$ << 15)));
    $redis_ns = $ENV{REDIS_NS} = 'TEST_NS:' . int(rand() * 100000) . '__';
    no strict 'refs';

    my $caller = caller;

    while (my ($name, $symbol) = each %{__PACKAGE__ . '::'}) {
        next if $name eq 'BEGIN';
        next if $name eq 'import';
        next unless *{$symbol}{CODE};

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
}

my $t = Test::Mojo->with_roles('+StopOnFail')->new('Lgpdjus');
$t->ua->on(
    start => sub {
        my ($ua, $tx) = @_;
        $tx->with_roles('Mojo::Transaction::Role::PrettyDebug');
    }
);

sub test_instance {$t}
sub t             {$t}

sub app { $t->app }

sub get_schema { $t->app->schema }

sub resultset { get_schema->resultset(@_) }

sub db_transaction (&) {
    my ($code) = @_;

    my $schema = get_schema;
    eval {
        $schema->txn_do(
            sub {
                $code->();
                die "rollbackPG\n";
            }
        );
    };
    die $@ unless $@ =~ m{rollbackPG};
}

sub db_transaction2 (&) {
    my ($code) = @_;

    my $schema = get_schema;
    eval {
        $schema->txn_do(
            sub {
                $code->();
                die "rollbackMDB\n";
            }
        );
    };
    die $@ unless $@ =~ m{rollbackMDB};
}

sub cpf_already_exists {
    my ($cpf) = @_;

    return app->schema->resultset('Cliente')->search({cpf => $cpf,})->count;
}

sub get_cliente_by_email {

    my $res = app->schema->resultset('Cliente')->search(
        {

            'email' => shift,
        },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
    )->next;

    return $res;
}

sub get_forget_password_row {
    my $id = shift or die 'missing id';

    my $res = app->schema->resultset('ClientesResetPassword')->search(
        {
            'cliente_id' => $id,
        },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
    )->next;

    return $res;
}

sub get_user_session {
    my $random_cpf   = shift;
    my $name         = shift || 'Quiz';
    my $random_email = 'email' . $random_cpf . '@autotests.com';

    my @other_fields = (
        raca        => 'pardo',
        apelido     => 'ca',
        app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        dry         => 0,
    );

    my $session;
    my $user_id;
    if (!cpf_already_exists($random_cpf)) {
        subtest_buffered 'Cadastro com sucesso' => sub {
            my $res = $t->post_ok(
                '/signup',
                form => {
                    nome_completo => $name . ' UserName',
                    cpf           => $random_cpf,
                    email         => $random_email,
                    senha         => 'ARU 55 PASS',
                    cep           => '12345678',
                    dt_nasc       => '1994-01-31',
                    @other_fields,
                    genero => 'Feminino',
                },
            )->status_is(200)->tx->res->json;
            $session = $res->{session};
            $user_id = $res->{_test_only_id};
        };
    }
    else {
        my $res = $t->post_ok(
            '/login',
            form => {
                email       => $random_email,
                senha       => 'ARU 55 PASS',
                app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
            }
        )->status_is(200)->tx->res->json;
        $session = $res->{session};
        $user_id = $res->{_test_only_id};
    }
    die 'missing session' unless $session;

    return ($session, $user_id);
}

sub user_cleanup {
    my (%opts) = @_;

    my $user_id = $opts{user_id};
    log_info("Apagando cliente " . (ref $user_id ? join(',', $user_id->@*) : $user_id));

    foreach my $table (
        qw/
        ClientesActiveSession
        LoginErro
        MediaUpload
        BlockchainRecord
        /
      )
    {
        my $rs = app->schema->resultset($table);
        $rs->search({cliente_id => $user_id})->delete;
    }

    app->schema->resultset('Cliente')->search({id => $user_id})->delete;
}

sub last_tx_json {
    test_instance->tx->res->json;
}

sub create_fake_ticket {
    my ($cliente, $status, $interval, %opts) = @_;

    my $questionnaire_id = $opts{questionnaire_id} || 4;
    $interval ||= 1;
    my $content = to_json(
        from_json(
            q|{
  "responses": {
    "abc": "Y",
    "start_time": 1619095117
  },
  "session_id": -1,
  "quiz": [
    {
      "content": "xxxx",
      "type": "displaytext"
    },
    {
      "type": "yesno",
      "content": "foobar",
      "code": "abc"
    }
  ]
}|
        )
    );
    my $ticket = $cliente->tickets->create(
        {
            content          => $content,
            content_hash256  => sha256_hex($content),
            questionnaire_id => $questionnaire_id,
            protocol         => int(rand() * 1000000000),
            status           => $status || 'pending',
            due_date         => \["now() + (?::text || ' days')::interval",    1],
            created_on       => \["now() - (?::text || ' minutes')::interval", $interval],
            updated_at       => \["now() - (?::text || ' minutes')::interval", $interval],
            started_at       => \'now()',
        }
    );

    if ($ticket->status eq 'wait-additional-info') {
        $ticket->tickets_responses->create(
            {
                user_id       => \[q!(select id from directus_users where email = ?)!, $admin_email],
                cliente_id    => $cliente->id,
                reply_content => \'random()::text',
                created_on    => \'now()',
                type          => 'request-additional-info'
            }
        );
    }

    return $ticket;

}

sub loggin_as_admin {

    # ID do role de test
    my $admin = get_schema->resultset('DirectusUser')->search(
        {
            status => 'active',
            email  => $admin_email
        }
    )->next;
    $ENV{ADMIN_ALLOWED_ROLE_IDS} = $admin->role;

    $t->post_ok(
        '/admin/login',
        form => {
            email => $admin_email,
            senha => $admin_password,
        },
    )->status_is(200)->json_is('/ok', '1', 'login was ok');

    return $admin;
}

1;
