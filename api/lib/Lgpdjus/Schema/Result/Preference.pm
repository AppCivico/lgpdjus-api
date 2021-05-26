#<<<
use utf8;
package Lgpdjus::Schema::Result::Preference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("preferences");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "preferences_id_seq",
  },
  "name",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "label",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "active",
  { data_type => "boolean", is_nullable => 0 },
  "initial_value",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 200,
  },
  "sort",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("preferences_name_unique", ["name"]);
__PACKAGE__->has_many(
  "clientes_preferences",
  "Lgpdjus::Schema::Result::ClientesPreference",
  { "foreign.preference_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-16 09:45:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OeZEUTfBRX9w6OszAGTjiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
