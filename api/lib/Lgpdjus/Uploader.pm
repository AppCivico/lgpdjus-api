package Lgpdjus::Uploader;
use common::sense;
use MooseX::Singleton;

use URI;
use URI::Escape;
use Net::Amazon::S3;
use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);
use Mojo::URL;
use Net::Amazon::S3::Authorization::Basic;
use Net::Amazon::S3::Vendor::Generic;

use Lgpdjus::Utils;

has access_key => (is => 'rw', isa => 'Str', lazy => 1, default => sub {$ENV{LGPDJUS_S3_ACCESS_KEY}},);

has secret_key => (is => "rw", isa => 'Str', lazy => 1, default => sub{$ENV{LGPDJUS_S3_SECRET_KEY}},);

has media_bucket => (is => "rw", isa => 'Str', lazy => 1, default => sub{$ENV{LGPDJUS_S3_MEDIA_BUCKET}},);

has _s3 => (is => "ro", isa => "Net::Amazon::S3", lazy_build => 1, handles => [qw/ err errstr /],);

sub _build__s3 {
    my ($self) = @_;

    defined $self->access_key   or die "missing 'access_key'.";
    defined $self->secret_key   or die "missing 'secret_key'.";
    defined $self->media_bucket or die "missing 'media_bucket'.";


    my $vendor = Net::Amazon::S3::Vendor::Generic->new(
        host                 => $ENV{LGPDJUS_S3_HOST} || 's3.amazonaws.com',
        use_https            => $ENV{LGPDJUS_S3_USE_HTTPS} ? 1 : 0,
        use_virtual_host     => 1,
        authorization_method => 'Net::Amazon::S3::Signature::V4',
        default_region       => $ENV{LGPDJUS_S3_REGION} || 'us-west-1',
    );

    return Net::Amazon::S3->new(
        vendor                => $vendor,
        authorization_context => Net::Amazon::S3::Authorization::Basic->new(
            aws_access_key_id     => $self->access_key,
            aws_secret_access_key => $self->secret_key,
        ),
        retry => 1,
    );
}

sub upload {
    my ($self, $args) = @_;

    # Required args.
    defined $args->{$_} or die "missing '$_'" for qw(file path type);

    if (is_test()) {
        return $args->{path};
    }

    my $bucket  = $self->_s3->bucket($self->media_bucket);
    my $success = $bucket->add_key_filename($args->{path}, $args->{file}, {content_type => $args->{type}});

    if (!$success) {
        die $self->_s3->err . ': ' . $self->_s3->errstr;
    }

    return $args->{path};
}

sub query_string_authentication_uri {
    my ($self, $key, $expires_in) = @_;

    $expires_in ||= 3600;    # valid for one hour

    my $bucket = $self->_s3->bucket($self->media_bucket);
    my $uri    = $bucket->query_string_authentication_uri(
        key        => $key,
        expires_at => time + $expires_in,
    );

    return $uri;
}

sub remove_by_uri {
    my ($self, $uri) = @_;

    my $path = Mojo::URL->new($uri)->path->to_abs_string;
    if (is_test()) {
        return 1;
    }
    my $bucket  = $self->_s3->bucket($self->media_bucket);
    my $success = $bucket->delete_key($path);
    if (!$success) {
        die $bucket->err . ': ' . $bucket->errstr;
    }
    return $success;
}


__PACKAGE__->meta->make_immutable;

1;

