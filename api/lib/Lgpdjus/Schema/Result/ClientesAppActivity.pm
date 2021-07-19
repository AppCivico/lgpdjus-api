#<<<
use utf8;
package Lgpdjus::Schema::Result::ClientesAppActivity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("clientes_app_activity");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_app_activity_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "last_activity",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("idx_219124_cliente_id", ["cliente_id"]);
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-19 13:46:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7bizOI8sGaOFDoDNjuFekQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
