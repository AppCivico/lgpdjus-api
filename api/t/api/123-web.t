use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Lgpdjus::Test;

my $t = test_instance;

use DateTime;
use utf8;
use Business::BR::CPF qw/random_cpf/;

my $schema = $t->app->schema;

&test_cli_seg();

&test_blockchain();

&test_faq();

done_testing();

exit;

sub test_cli_seg {

    my ($session, $user_id) = get_user_session('24115775670', 'Segmenta');
    on_scope_exit { user_cleanup(user_id => $user_id); };
    my $cliente    = get_schema->resultset('Cliente')->find($user_id);
    my $random_cpf = random_cpf();
    my ($session2, $user_id2) = get_user_session($random_cpf, 'Segmentb');
    my $cliente2 = get_schema->resultset('Cliente')->find($user_id2);
    on_scope_exit { user_cleanup(user_id => $user_id2); };

    my $segment_rs = $schema->resultset('AdminClientesSegment')->search(
        {
            is_test => '1',
        }
    );

    $segment_rs->delete;
    my $q = $segment_rs->create(
        {
            label   => 'test1',
            is_test => 1,
            cond    => to_json({'me.id' => $user_id}),
            attr    => to_json({}),
        }
    );

    my $q2 = $segment_rs->create(
        {
            label   => 'test1',
            is_test => 1,
            cond    => to_json({'me.cpf' => [$cliente->cpf, $cliente2->cpf]}),
            attr    => to_json({}),
        }
    );

    is $q->last_run_at, undef, 'run is null';

    &loggin_as_admin();

    $t->get_ok(
        '/admin/users',
        form => {segment_id => $q->id}
    )->status_is(200, 'filtro de segmento');

    #ok $q->discard_changes->last_run_at, 'run is not null';
    #is $q->last_count, 1, 'one row found';

    db_transaction2 {

        $cliente->notification_logs->delete;

        # se der errado, n pode afetar prod!

        $t->post_ok(
            '/admin/add-notification',
            form => {
                segment_id      => $q->id,
                message_title   => 'hey',
                message_content => 'kids',
            }
        )->status_is(200)->json_has('/notification_message_id', 'defined notification_message_id');

        ok my $msg = $cliente->notification_logs->next, 'notification_logs defined';

        is $msg->notification_message_id, last_tx_json->{notification_message_id},
          'notification_message_id matches';
        $cliente->notification_logs->delete;

        $t->post_ok(
            '/admin/add-notification',
            form => {
                cliente_id      => $cliente->id,
                message_title   => 'hey',
                message_content => 'kids',
            }
        )->status_is(200)->json_has('/notification_message_id', 'defined notification_message_id');

        ok $msg = $cliente->notification_logs->next, 'notification_logs defined';
        is $msg->notification_message_id, last_tx_json->{notification_message_id},
          'notification_message_id matches';

        $t->post_ok(
            '/admin/add-notification',
            form => {
                message_title   => 'hey',
                message_content => 'kids',
            }
        )->status_is(400)->json_is('/error', 'form_error');


        $t->post_ok(
            '/admin/add-notification',
            form => {
                segment_id      => $q2->id,
                message_title   => 'a',
                message_content => 'boo',
            }
        )->status_is(200)->json_has('/notification_message_id', 'defined notification_message_id');

        is get_schema->resultset('NotificationLog')
          ->search({notification_message_id => last_tx_json->{notification_message_id}})->count, 2, '2 rows';
    };

    $segment_rs->delete;
}


sub test_blockchain {

    $t->get_ok(
        '/admin/blockchains',
      )->status_is(200, 'testando get endpoint')    #
      ->json_is('/filter', 'all', 'not filtered')   #
      ->json_has('/rows', 'has rows');

}


sub test_faq {

    $t->get_ok(
        '/web/termos-de-uso',
    )->status_is(200, 'puxando termos_de_uso');

    $t->get_ok(
        '/web/politica-privacidade',
    )->status_is(200, 'puxando politica-privacidade');

    $t->get_ok(
        '/web/sobre',
    )->status_is(200, 'puxando sobre');

}