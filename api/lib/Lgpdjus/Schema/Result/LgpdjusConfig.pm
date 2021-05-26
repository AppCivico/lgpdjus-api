#<<<
use utf8;
package Lgpdjus::Schema::Result::LgpdjusConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("lgpdjus_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "lgpdjus_config_id_seq",
  },
  "name",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 255,
  },
  "value",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 0,
    size => 255,
  },
  "valid_from",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "valid_to",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-26 18:09:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LUKc7CHWZm5AO3djSFE/Dw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
