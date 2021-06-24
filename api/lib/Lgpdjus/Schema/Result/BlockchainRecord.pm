#<<<
use utf8;
package Lgpdjus::Schema::Result::BlockchainRecord;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("blockchain_records");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blockchain_records_id_seq",
  },
  "filename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "digest",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 255,
  },
  "media_upload_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 255 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "dcrtime_timestamp",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "decred_merkle_root",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "decred_capture_txid",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "created_at_real",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "ticket_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("ix_blockchain_uniq_digest", ["digest"]);
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "media_upload",
  "Lgpdjus::Schema::Result::MediaUpload",
  { id => "media_upload_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "ticket",
  "Lgpdjus::Schema::Result::Ticket",
  { id => "ticket_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 13:40:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tOyQ2xYTf2VbynVafH/P8A

use Mojo::Util qw(url_escape);

# ALTER TABLE blockchain_records ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL ON UPDATE cascade;
# ALTER TABLE blockchain_records ADD FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE SET NULL ON UPDATE cascade;
# ALTER TABLE blockchain_records ADD FOREIGN KEY (media_upload_id) REFERENCES media_upload(id) ON DELETE cascade ON UPDATE cascade;

sub created_at_dmy_hms {
    my $self = shift();
    my $dt   = $self->created_at_real->set_time_zone('America/Sao_Paulo');
    return $dt->dmy('/') . ' ' . $dt->hms;
}

sub created_at_utc {
    my $self = shift();
    my $dt   = $self->created_at_real->set_time_zone('UTC');
    return $dt->dmy('/') . ' ' . $dt->hms;
}

sub dcrtime_timestamp_utc {
    my $self = shift();
    my $dt   = $self->dcrtime_timestamp->set_time_zone('UTC');
    return $dt->dmy('/') . ' ' . $dt->hms;
}


sub build_status {
    my $self = shift();
    return $self->decred_capture_txid
      ? sprintf(
        'Registrado<br/> <a target="_blank" href="%s">txid: %s</a>',
        'https://explorer.dcrdata.org/tx/' . $self->decred_capture_txid, $self->decred_capture_txid
      )
      : 'Pendente de registro';
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
