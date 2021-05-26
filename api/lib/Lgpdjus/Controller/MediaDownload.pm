package Lgpdjus::Controller::MediaDownload;
use Mojo::Base 'Lgpdjus::Controller';
use Digest::MD5 qw/md5_hex/;
use DateTime;
use Lgpdjus::Utils qw/get_media_filepath is_uuid_v4 is_test/;
use Mojo::UserAgent;
use feature 'state';
use Encode;
use Lgpdjus::Uploader;

has _uploader => sub { Lgpdjus::Uploader->new() };

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user_id');
    return 1;
}

sub logged_in_get_media {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        'm' => {required => 1, type => 'Str', max_length => 36, min_length => 36,},
        'h' => {required => 1, type => 'Str', max_length => 12, min_length => 12},
        'q' => {required => 1, type => 'Str', max_length => 2,  min_length => 2},
    );

    my $id = $params->{m};

    my $user_id = $c->stash('user_id');
    my $quality = $params->{q};
    my $ip      = $c->remote_addr;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . $user_id . $quality . $ip), 0, 12);

    if ($params->{h} ne $hash) {
        return $c->render(
            json => {
                error   => 'media_hash_invalid',
                message => 'hash não confere.'
            },
            status => 400,
        );
    }

    return _get_media($c, $id, $quality);
}

sub internal_get_media {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $c->validate_request_params(
        'm'   => {required => 1, type => 'Str', max_length => 36, min_length => 36,},
        'q'   => {required => 1, type => 'Str', max_length => 2,  min_length => 2},
        'key' => {required => 1, type => 'Str',},
    );

    my $id      = $params->{m};
    my $quality = $params->{q};

    # poors mans jwt
    my $key = md5_hex($ENV{MEDIA_HASH_SALT} . 'internal' . $id);
    if ($key ne $params->{key}) {
        return $c->render(
            json => {
                error   => 'media_hash_invalid',
                message => 'key não confere.'
            },
            status => 400,
        );
    }

    return _get_media($c, $id, $quality, 1);
}


sub admin_logged_in_get_media {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $c->validate_request_params(
        'm'        => {required => 1,     type       => 'Str', max_length => 36, min_length => 36,},
        'q'        => {required => 1,     type       => 'Str', max_length => 2,  min_length => 2},
        'jpeg'     => {required => 1,     type       => 'Bool',},
        'filename' => {type     => 'Str', max_length => 1000},
    );

    my $id      = $params->{m};
    my $quality = $params->{q};

    return _get_media($c, $id, $quality, $params->{jpeg}, $params->{filename});
}

sub _get_media {
    my $c          = shift;
    my $id         = shift;
    my $quality    = shift;
    my $header_jpg = shift || 0;
    my $filename   = shift;

    # just in case
    $c->reply_item_not_found() unless is_uuid_v4($id);

    my $cached_filename = get_media_filepath("$id.$quality");

    if (is_test()) {
        return $c->render(json => {media_id => $id, quality => $quality});
    }

    $c->res->headers->content_type('image/jpeg') if $header_jpg;

    $c->res->headers->cache_control("max-age=2592000, must-revalidate");
    if (-e $cached_filename) {
        if ($filename) {
            $c->render_file('filepath' => $cached_filename, 'filename' => $filename);
        }
        else {
            $c->reply->file($cached_filename);
        }
    }
    else {
        state $ua = Mojo::UserAgent->new;

        my $media             = $c->schema->resultset('MediaUpload')->find($id) or $c->reply_item_not_found();
        my $resolution_column = $quality eq 'sd' ? 's3_path_avatar' : 's3_path';
        my $s3_path           = $c->_uploader->query_string_authentication_uri($media->$resolution_column);

        $c->render_later;
        $ua->get_p($s3_path)->then(
            sub {
                my $tx = shift;

                $tx->result->save_to($cached_filename);
                if ($filename) {
                    $c->render_file('filepath' => $cached_filename, 'filename' => $filename);
                }
                else {
                    $c->reply->file($cached_filename);
                }
            }
        )->catch(
            sub {
                my $err = shift;
                $c->log->debug("Proxy error: $err while downloading $s3_path");
                $c->render(text => 'Something went wrong!', status => 400);
            }
        );
    }

}

# download de photos com cache+proxy pra sempre ser https
sub public_get_proxy {
    my $c = shift;

    # limite bem generoso por IP, 180x por minuto [3 loads a cada 10 segundos, repetindo por 1 minuto]
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'PG' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(180, 60);

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        'href' => {required => 1, type => 'Str', max_length => 5000, min_length => 5,},
        'h'    => {required => 1, type => 'Str', max_length => 12,   min_length => 12},
    );

    my $href = $params->{href};

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . encode_utf8($href)), 0, 12);

    if ($params->{h} ne $hash) {
        return $c->render(
            json => {
                error   => 'media_hash_invalid',
                message => 'hash não confere.'
            },
            status => 400,
        );
    }

    my $cached_filename = get_media_filepath('NT' . md5_hex(encode_utf8($href)));

    if (-e $cached_filename) {
        $c->reply->file($cached_filename);
    }
    else {
        state $ua = Mojo::UserAgent->new;

        $c->render_later;
        $ua->get_p($href)->then(
            sub {
                my $tx = shift;

                my $code = $tx->result->code;

                if ($code == 200) {
                    $tx->result->save_to($cached_filename);

                    # cache 30 dias
                    $c->res->headers->cache_control("max-age=2592000, must-revalidate");

                    $c->reply->file($cached_filename);
                }
                else {
                    if ($code == 404) {

                        # cache 1 hora
                        $c->res->headers->cache_control("max-age=3600, must-revalidate");

                        $c->reply->static('avatar/news.404.jpg');
                    }
                    else {
                        # cache 1 hora
                        $c->res->headers->cache_control("max-age=3600, must-revalidate");

                        $c->reply->static('avatar/news.err.jpg');
                    }
                }

            }
        )->catch(
            sub {
                my $err = shift;
                $c->log->debug("Proxy error: $err while downloading $href");

                # cache 1 hora
                $c->res->headers->cache_control("max-age=3600, must-revalidate");

                $c->reply->static('avatar/news.err.jpg');
            }
        );

    }

}

1;
