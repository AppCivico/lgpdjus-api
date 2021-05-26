package Lgpdjus::Controller::Tags;
use utf8;
use Mojo::Base 'Lgpdjus::Controller';
use Lgpdjus::Utils qw/is_test/;
use Lgpdjus::KeyValueStorage;

sub filter_tags {
    my $c = shift;

    my $cache_key = '';

    my $tags = Lgpdjus::KeyValueStorage->instance->redis_get_cached_or_execute(
        "tags_filter:$cache_key",
        86400,    # 1 day
        sub {
            my @tags = $c->schema->resultset('Tag')->search(
                {
                    'me.status'          => is_test() ? 'test' : 'prod',
                    'me.show_on_filters' => '1',
                },
                {
                    columns => [
                        (qw/me.id me.title/),
                    ],
                    order_by     => 'me.title',
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all;

            return {tags => \@tags};
        }
    );

    return $c->render(json => $tags);
}

sub clear_cache {
    my $c     = shift;
    my $redis = Lgpdjus::KeyValueStorage->instance->redis;

    $redis->del(
        $ENV{REDIS_NS} . 'tags_filter:',    # nenhuma permissao
        $ENV{REDIS_NS} . 'tags_highlight_regexp'
    );

    return $c->render(json => {});
}

1;
