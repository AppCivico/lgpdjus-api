#<<<
use utf8;
package Lgpdjus::Schema::Result::MediaUpload;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("media_upload");
__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "file_info",
  { data_type => "text", is_nullable => 1 },
  "file_sha1",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "file_size",
  { data_type => "bigint", is_nullable => 1 },
  "s3_path",
  { data_type => "text", is_nullable => 0 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "intention",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "s3_path_avatar",
  { data_type => "text", is_nullable => 1 },
  "file_size_avatar",
  { data_type => "bigint", is_nullable => 1 },
  "is_on_blockchain",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "blockchain_records",
  "Lgpdjus::Schema::Result::BlockchainRecord",
  { "foreign.media_upload_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->has_many(
  "tickets_cliente_pdf_media_uploads",
  "Lgpdjus::Schema::Result::Ticket",
  { "foreign.cliente_pdf_media_upload_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tickets_user_pdf_media_uploads",
  "Lgpdjus::Schema::Result::Ticket",
  { "foreign.user_pdf_media_upload_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-25 12:47:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FTcrMKeDHjTs1YHWofoC6w


use Mojo::Util qw(url_escape);

use Digest::MD5 qw/md5_hex/;

# ALTER TABLE media_upload ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT ON UPDATE RESTRICT;

sub media_generate_download_url {
    my ($self, $c, $quality) = @_;

    $quality = 'sd' unless $quality;
    my $ip       = $c->remote_addr();
    my $media_id = $self->id;
    my $hash     = substr(md5_hex($ENV{MEDIA_HASH_SALT} . $self->cliente_id . $quality . $ip), 0, 12);
    return $ENV{PUBLIC_API_URL} . "media-download/?m=$media_id&q=$quality&h=$hash";
}

sub media_generate_download_url_admin {
    my ($self, $c, $quality, $jpeg, $filename) = @_;

    $jpeg    = defined $jpeg ? $jpeg ? 1 : 0 : 1;
    $quality = 'sd' unless $quality;
    my $media_id = $self->id;

    return
        $c->req->url->to_abs->scheme . '://'
      . $c->req->url->to_abs->host . ':'
      . $c->req->url->to_abs->port
      . "/admin/media-download/?m=$media_id&q=$quality&jpeg=$jpeg"
      . ($filename ? '&filename=' . url_escape($filename) : '');
}

sub media_generate_download_url_internal {
    my ($self, $c, $quality) = @_;

    $quality = 'sd' unless $quality;

    my $media_id = $self->id;

    # poors mans jwt
    my $key = md5_hex($ENV{MEDIA_HASH_SALT} . 'internal' . $media_id);

    return $ENV{PUBLIC_API_URL} . "internal-media-download/?m=$media_id&q=$quality&key=$key";
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
