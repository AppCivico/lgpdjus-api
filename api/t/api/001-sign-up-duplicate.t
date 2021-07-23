use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Lgpdjus::Test;
use Lgpdjus::Minion::Tasks::DeleteUser;
use Lgpdjus::Minion::Tasks::AddBlockchain;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;


AGAIN:
my $random_cpf           = random_cpf();
my $bad_random_cpf       = random_cpf(0);
my $valid_but_wrong_date = '89253398035';

my $random_email = 'email' . $random_cpf . '@autotests.com';
goto AGAIN if cpf_already_exists($random_cpf);

$ENV{MAX_CPF_ERRORS_IN_24H} = 10000;

my @other_fields = (
    apelido     => 'ca',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

do {
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $bad_random_cpf,
            email         => $random_email,
            senha         => '1A`S345678A*',
            @other_fields,
        },
    )->status_is(400, 'a1')->json_is('/error', 'form_error')->json_is('/field', 'cpf')->json_is('/reason', 'invalid');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            @other_fields,
            dry => 1,

        },
    )->status_is(200)->json_is('/continue', '1');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '3As344578a ',
            @other_fields,

        },
    )->status_is(400, 'a2')->json_is('/error', 'warning_space_password');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '3As344578a',
            @other_fields,

        },
    )->status_is(400, 'a3')->json_is('/error', 'pass_too_weak/char');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '65658895',
            @other_fields,

        },
    )->status_is(400, 'a4',)->json_is('/error', 'pass_too_weak/letter');
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'oiuytrew',
            @other_fields,

        },
    )->status_is(400, 'a5')->json_is('/error', 'pass_too_weak/number');
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'iuy123*',
            @other_fields,

        },
    )->status_is(400, 'a6')->json_is('/error', 'pass_too_weak/size');

};

my $job = Minion::Job->new(
    id     => fake_int(1, 99)->(),
    minion => $t->app->minion,
    task   => 'testmocked',
    notes  => {hello => 'mock'}
);
my $cliente_id;
my $user_obj;
do {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '1A`S345678A*',
            @other_fields,
        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $user_obj   = get_schema->resultset('Cliente')->find($cliente_id);

    ok(
        Lgpdjus::Minion::Tasks::AddBlockchain::job_generate_pdf_and_blockchain(
            $job, test_get_minion_args_job($ENV{LAST_PDF_JOB_ID})
        ),
        'generate pdf'
    );

    my ($template, $email_id) = trace_grep('citizen_email');
    is $template, 'signup', 'signup template';
    ok $email_id, 'email was created';
    my $signup_email = get_schema->resultset('EmaildbQueue')->find($email_id);
    ok $signup_email, 'has email';


    my ($ntf_message_id) = trace_grep('citizen_notification');
    ok $ntf_message_id, 'notification was created';
    my $signup_notification = get_schema->resultset('NotificationMessage')->find($ntf_message_id);
    ok $signup_notification, 'has signup NotificationMessage';
    is $signup_notification->icon, 1, 'icon 1 for this notification';

    my $cadastro = $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(200)->tx->res->json;

    is $cadastro->{user_profile}{nome_completo}, 'test name';

    is $user_obj->clientes_preferences->count, 0, 'no clientes_preferences';
    $t->get_ok('/me/preferences', {'x-api-key' => $res->{session}})->status_is(200);


    ok my $key0 = last_tx_json->{preferences}[0]{key}, 'has some pref';

    $t->post_ok(
        '/me/preferences', {'x-api-key' => $res->{session}},
        form => {
            ignored => '1',
            $key0   => 0,
        }
    )->status_is(204);
    $t->get_ok('/me/preferences', {'x-api-key' => $res->{session}})->status_is(200);
    is last_tx_json->{preferences}[0]{key}, $key0, 'name ok';
    is last_tx_json->{preferences}[0]{value}, 0, 'key 0 is updated to 0';

    is $user_obj->clientes_preferences->count, 1, '1 clientes_preferences';

    $t->post_ok(
        '/me/preferences', {'x-api-key' => $res->{session}},
        form => {
            $key0 => 1,
        }
    )->status_is(204);
    $t->get_ok('/me/preferences', {'x-api-key' => $res->{session}})->status_is(200);
    is last_tx_json->{preferences}[0]{key}, $key0, 'name ok';
    is last_tx_json->{preferences}[0]{value}, 1, 'key 0 is updated to 1';

    is $user_obj->clientes_preferences->count, 1, '1 clientes_preferences';

    $t->post_ok(
        '/logout',
        {'x-api-key' => $res->{session}}
    )->status_is(204);

    $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(403);
};

on_scope_exit { user_cleanup(user_id => $cliente_id); };

my $session;
subtest_buffered 'Login' => sub {
    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => '1AS34567',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(400)->json_is('/error', 'wrongpassword');

    my $res = $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => '1A`S345678A*',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200)->json_has('/session')->tx->res->json;

    $session = $res->{session};
    $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(200);

};

my $directus = get_cliente_by_email($random_email);

subtest_buffered 'update' => sub {
    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            email => $random_email,
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha => $random_email,
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual')
      ->json_is('/reason', 'is_required');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => 'foobar',
            senha       => $random_email,
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual')
      ->json_is('/reason', 'invalid');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {senha_atual => 'foobar', senha => 'lalalala'}
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual')
      ->json_is('/reason', 'invalid');

    my $random_user = get_schema->resultset('Cliente')->search({email => {'!=' => $random_email}})->next;
    if ($random_user) {
        $t->put_ok(
            '/me',
            {'x-api-key' => $session},
            form => {
                senha_atual => '1A`S345678A*',
                email       => $random_user->email,
            }
        )->status_is(400, 'xp')->json_is('/error', 'form_error')->json_is('/field', 'email')
          ->json_is('/reason', 'duplicate');

    }

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => '1A`S345678A*',
            senha       => '1234578',
        }
    )->status_is(400, 'senha muito fraca')->json_is('/error', 'pass_too_weak');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => '1A`S345678A*',
            senha       => 'XXD~EFWDA1',
        }
    )->status_is(200, 'senha atualizada');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {}
    )->status_is(200, 'just messing arround');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => 'XXD~EFWDA1',
            email       => $random_email,
        }
    )->status_is(200);

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {apelido => 'ze pequenoあ'}
    )->status_is(200)->json_is('/user_profile/apelido', 'ze pequenoあ', 'nome ok, encoding ok');

};

subtest_buffered 'Reset de senha' => sub {

    is(get_forget_password_row($directus->{id}), undef, 'no rows');

    $t->post_ok(
        '/reset-password/request-new',
        form => {
            email       => $random_email,
            app_version => '...',
        }
    )->status_is(200);

    ok(my $forget = get_forget_password_row($directus->{id}), 'has a new row');
    ok $forget->{token}, 'has token';
    is $forget->{used_at}, undef, 'used_at is null';

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 1,
            token       => '1A`S345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'invalid_token');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => '1A`S345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha');

    my $rand_password = 'aS3lso34o*83m2' . rand;
    $user_obj->update({senha_sha256 => sha256_hex($rand_password)});
    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => $rand_password,
            app_version => '...',
        }
    )->status_is(400, 'not the same')->json_is('/error', 'pass_same_as_before', 'nao pode ser igual');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 1,
            token       => $forget->{token},
            senha       => 'abc1A`S345678',
            app_version => '...',
        }
    )->status_is(200, 'ok 1')->json_is('/continue', '1', 'suc 2');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => 'abc1A`S345678',
            app_version => '...',
        }
    )->status_is(200, 'ok 2')->json_is('/success', '1', 'suc 2');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => 'abc1A`S345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'invalid_token');

    ok($forget = get_forget_password_row($directus->{id}), 'has a new row');
    ok $forget->{used_at}, 'used_at is NOT null';

    my $email_rs = get_schema->resultset('EmaildbQueue')->search(
        {
            to => $random_email,
        }
    );

    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => 'abc1A`S345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200, 'pass ok')->json_has('/session');
    is $user_obj->status, 'active', 'status active';
    my $session = last_tx_json()->{session};
    $t->get_ok(
        '/me/delete-text',
        {'x-api-key' => $session},
    )->status_is(200)->json_has('/text', 'tem texto');
    $t->delete_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => 'abc1A`S345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(204);
    is $user_obj->discard_changes->status, 'account_disabled', 'disabled account';
    is $user_obj->perform_delete_at, undef, 'perform_delete_at is null still';

    $t->get_ok('/me', {'x-api-key' => $session})->status_is(403);


    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => 'abc1A`S345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200)->json_has('/session')->json_is('/account_disabled', '1');
    $session = last_tx_json()->{session};
    is $user_obj->discard_changes->status, 'account_disabled', 'still disabled';
    is $user_obj->perform_delete_at, undef, 'perform_delete_at still null';
    $t->get_ok('/me', {'x-api-key' => $session})->status_is(404);

    $t->post_ok(
        '/reactivate',
        {'x-api-key' => $session},
        form => {
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(204);
    $t->get_ok('/me', {'x-api-key' => $session})->status_is(200);

    is $user_obj->discard_changes->status, 'active', 'is active';
    is $user_obj->perform_delete_at, undef, 'perform_delete_at is null';

    my $user_obj = get_schema->resultset('Cliente')->find($cliente_id);
    $user_obj->update(
        {
            perform_delete_at   => '2020-01-01',
            deletion_started_at => undef,
            status              => 'deleted_scheduled'
        }
    );

    trace_popall;
    $ENV{MAINTENANCE_SECRET} = '1234';
    $t->get_ok(
        '/maintenance/housekeeping',
        form => {secret => $ENV{MAINTENANCE_SECRET}}
    )->status_is(200);
    ok $ENV{LAST_DELETE_JOB_ID}, 'has $ENV{LAST_DELETE_JOB_ID}';
    ok(
        Lgpdjus::Minion::Tasks::DeleteUser::delete_user($job, test_get_minion_args_job($ENV{LAST_DELETE_JOB_ID})),
        'delete user'
    );
    my $text = trace_popall;
    is $text, "minion:delete_user,$cliente_id", 'logs looks ok';

};

done_testing();

exit;
