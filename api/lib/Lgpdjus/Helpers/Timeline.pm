package Lgpdjus::Helpers::Timeline;
use common::sense;
use Carp qw/confess /;
use utf8;
use Lgpdjus::KeyValueStorage;
use Scope::OnExit;
use Digest::MD5 qw/md5_hex/;
use Mojo::Util qw/trim xml_escape url_escape dumper/;

use JSON;
use Lgpdjus::Logger;
use Lgpdjus::Utils;
use List::Util '1.54' => qw/sample/;
use DateTime::Format::Pg;
use Encode;

sub kv { Lgpdjus::KeyValueStorage->instance }

sub setup {
    my $self = shift;

    $self->helper('list_news'      => sub { &list_news(@_) });
    $self->helper('_get_news_rows' => sub { &_get_news_rows(@_) });
}

sub list_news {
    my ($c, %opts) = @_;

    my $rows = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $user = $opts{user} or confess 'missing user';

    $opts{$_} ||= '' for qw/tags/;

    if ($opts{next_page}) {
        slog_info('list_news applying next_page=%s', to_json($opts{next_page}));

        if ($opts{tags} ne $opts{next_page}{tags}) {
            $c->reply_invalid_param('não pode trocar de tags durante uso do next_page');
        }
    }

    slog_info(
        '_get_news_rows tags=%s rows=%s',
        $opts{tags} || '-',
        $rows || '-',
    );

    my $next_page = {
        tags => $opts{tags},
        iss  => 'next_page',
    };
    my $has_more = 0;

    my @rows = $c->_get_news_rows(
        user     => $user,
        tags     => $opts{tags},
        %{$opts{next_page}},
        next_page => $next_page,
        rows      => $rows,
    );

    $has_more  = 1 if delete $next_page->{set_has_more_true};
    $next_page = $c->encode_jwt($next_page, 1);

    return {
        rows     => \@rows,
        has_more => $has_more,
        ($next_page ? (next_page => $next_page) : ()),
    };
}

sub _get_tracked_news_url {
    my ($user, $news) = @_;

    my $userid      = $user->{id}        or confess 'missing user.id';
    my $newsid      = $news->{id}        or confess 'missing news.id';
    my $url         = $news->{hyperlink} or confess 'missing news.hyperlink';
    my $valid_until = time() + 3600;
    my $trackid     = random_string(4);

    my $hash = substr(md5_hex(join ':', $ENV{NEWS_HASH_SALT}, $userid, $newsid, $trackid, $valid_until, $url), 0, 12);
    return
        $ENV{PUBLIC_API_URL}
      . "news-redirect/?uid=$userid&nid=$newsid&u=$valid_until&t=$trackid&h=$hash&url="
      . url_escape(encode_utf8($url));
}

sub _get_proxy_image_url {
    my ($url) = @_;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . encode_utf8($url)), 0, 12);

    return $ENV{PUBLIC_API_URL} . "get-proxy/?h=$hash&href=" . url_escape(encode_utf8($url));
}

sub _get_news_rows {
    my ($c, %opts) = @_;

    log_info("running _get_news_rows");

    my $tags       = $opts{tags};
    my $rows       = $opts{rows};
    my $plain_news = 1;
    my $news_added = {map { $_ => 1 } @{$opts{news_added} || []}};

    log_info("asking for $rows rows of Noticias");
    log_info("\$news_added is " . dumper($news_added));

    my $cond = {
        'me.published' => is_test() ? 'published:testing' : 'published',
        'me.id'        => {'not in' => [keys %$news_added]},
        (
            $tags
            ? (
                '-and' => [{'-or' => [map { +{'me.tags_index' => {'like' => "%,$_,%"}} } split ',', $tags]}],
              )
            : (
                'me.has_topic_tags' => '1',
            )
        ),
    };

    my @news = $c->schema->resultset('Noticia')->search(
        $cond,
        {
            order_by     => [{'-desc' => 'me.display_created_time'}],
            columns      => [qw/me.id me.title me.display_created_time me.fonte me.hyperlink me.image_hyperlink/],
            rows         => $rows + 1,
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->all;

    my $has_more = scalar @news > $rows ? 1 : 0;
    pop @news if $has_more;

    $opts{next_page}{set_has_more_true} = $has_more;

    my @rows;
    foreach my $r (@news) {
        $news_added->{$r->{id}}++;
        push @rows, {
            type   => 'news_group',
            header => undef,
            news   => [&_format_noticia($r, %opts)]
        };
    }
    log_info(dumper($news_added));

    $opts{next_page}{news_added} = [keys %$news_added];

    return @rows;
}


sub _format_noticia {
    my ($r, %opts) = @_;

    $opts{user} or confess 'missing $opts{user}';

    return {
        id       => $r->{id},
        href     => &_get_tracked_news_url($opts{user}, $r),
        title    => $r->{title},
        source   => $r->{fonte},
        date_str => DateTime::Format::Pg->parse_datetime($r->{display_created_time})->dmy('/'),
        image    => (
              $r->{image_hyperlink}
            ? &_get_proxy_image_url($r->{image_hyperlink})
            : $ENV{NEWS_DEFAULT_IMAGE} || $ENV{PUBLIC_API_URL} . '/avatar/news.jpg'
        )
    };
}


1;
