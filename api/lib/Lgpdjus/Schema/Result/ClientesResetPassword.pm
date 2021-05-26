#<<<
use utf8;
package Lgpdjus::Schema::Result::ClientesResetPassword;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("clientes_reset_password");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_reset_password_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "token",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "valid_until",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "used_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "requested_by_remote_ip",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "used_by_remote_ip",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-12 14:21:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:icpyV5umE0SPS4y7XO53oQ

# ALTER TABLE clientes_reset_password ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
