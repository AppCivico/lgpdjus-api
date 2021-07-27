package Lgpdjus::Helpers::Notifications;
use common::sense;
use Carp qw/confess croak/;
use utf8;
use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;
use Scope::OnExit;

my $ntf_cache_key = 'unreadntfcount:';

sub setup {
    my $c = shift;

    $c->helper(user_notifications_clear_cache  => \&user_notifications_clear_cache);
    $c->helper(user_notifications_unread_count => \&user_notifications_unread_count);
    $c->helper(user_notifications              => \&user_notifications);
}

sub user_notifications_unread_count {
    my ($c, $user_id) = @_;

    confess '$user_id is not defined' unless defined $user_id;

    return $c->kv->redis_get_cached_or_execute(
        $ntf_cache_key . $user_id,
        86400,    # 24 hours
        sub {
            my $read_until = $c->schema->resultset('ClientesAppNotification')->search({cliente_id => $user_id})
              ->get_column('read_until')->next();

            my $count = $c->schema->resultset('NotificationLog')->search(
                {
                    'me.cliente_id' => $user_id,
                    ($read_until ? ('me.created_at' => {'>' => $read_until}) : ())
                },
                {
                    join => 'cliente',
                }
            )->count;

            return $count;
        }
    );

}

sub user_notifications_clear_cache {
    my ($c, $user_id) = @_;

    confess '$user_id is not defined' unless defined $user_id;

    return $c->kv->redis_del($ntf_cache_key . $user_id);
}

sub user_notifications {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $rows     = $opts{rows} || 100;
    $rows = 10 if !is_test() && ($rows > 1000 || $rows < 10);

    my $older_than;
    my $not_in;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'NFTP';
        $older_than = $tmp->{ot};
        $not_in     = $tmp->{not_in};
    }

    my $rs = $c->schema->resultset('NotificationLog')->search(
        {
            'me.cliente_id' => $user_obj->id,
            (
                $older_than
                ? (
                    'me.created_at' => {'<=' => $older_than},
                    'me.id'         => {'!=' => $not_in}
                  )
                : ()
            ),
        },
        {
            prefetch     => ['notification_message'],
            order_by     => \'me.created_at DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            rows         => $rows + 1,
        }
    );

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }
    my $last_timestamp  = @rows ? $rows[-1]{created_at} : undef;
    my $first_timestamp = @rows ? $rows[0]{created_at}  : undef;

    my @not_in;
    my @output_rows;
    my @load_users;
    my @load_users_chat;    # forcar carregar o chat, mesmo se estiverem em modo anônimo
    foreach my $r (@rows) {
        my $notification_message = $r->{notification_message};
        my $meta                 = $notification_message->{meta} ? from_json($notification_message->{meta}) : {};
        push @not_in, $r->{id} if $r->{created_at} eq $last_timestamp;

        $notification_message->{icon} ||= 0;

        push @output_rows, {
            content => $notification_message->{content},
            title   => $notification_message->{title},
            time    => pg_timestamp2iso_8601($notification_message->{created_at}),
            icon    => $ENV{DEFAULT_NOTIFICATION_ICON} . '/' . $notification_message->{icon} . '.svg',
            _meta   => $meta,
        };
    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'NFTP',
            not_in => \@not_in,
            ot     => $last_timestamp,
        },
        1
    );

    # nao eh paginado, e tem resultados
    # atualiza o "read_until" pra zerar (ou não) o contador
    if (!$opts{next_page} && $first_timestamp) {

        my $updated_timestamp = $c->schema->resultset('ClientesAppNotification')->search({cliente_id => $user_obj->id})
          ->update({read_until => $first_timestamp});
        if ($updated_timestamp == 0) {

            # nao tinha linha.. precisa inserir
            my ($locked, $locked_key)
              = $c->kv->lock_and_wait('ClientesAppNotificationIns' . $user_obj->id, 2)
              ;    # aguarda por 2 segundos no maximo
            on_scope_exit { $c->kv->redis->del($locked_key) };

            if ($locked) {
                $c->schema->resultset('ClientesAppNotification')->create(
                    {
                        cliente_id => $user_obj->id,
                        read_until => $first_timestamp,
                    }
                );
            }      # else: bem, nos tentamos...
        }

        $c->user_notifications_clear_cache($user_obj->id);
    }

    my ($meta);

    # removendo chaves privadas no final e criando deep-links
    foreach my $r (@output_rows) {

        $meta = delete $r->{_meta};

        if ($meta->{ticket_id}) {
            $r->{expand_screen} = '/tickets?id=' . $meta->{ticket_id};
        }
    }

    return {
        rows      => \@output_rows,
        has_more  => $has_more,
        next_page => $has_more ? $next_page : undef,
    };
}

1;
