#<<<
use utf8;
package Lgpdjus::Schema::Result::LoginLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("login_logs");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "login_logs_id_seq",
  },
  "remote_ip",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "app_version",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 800,
  },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-16 09:45:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gAxsiCiwwtAqzhgANRwodw

# ALTER TABLE login_logs ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
