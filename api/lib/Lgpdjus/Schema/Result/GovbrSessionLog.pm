#<<<
use utf8;
package Lgpdjus::Schema::Result::GovbrSessionLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("govbr_session_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "govbr_session_log_id_seq",
  },
  "external_secret",
  { data_type => "varchar", is_nullable => 0, size => 43 },
  "access_token_json",
  { data_type => "json", is_nullable => 1 },
  "id_token_json",
  { data_type => "json", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "logged_as_client_id",
  { data_type => "integer", is_nullable => 1 },
  "access_token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "id_token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-10-09 22:51:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bFYOXGrF46dyMkAAiaN6Fw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
