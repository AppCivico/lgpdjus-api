#<<<
use utf8;
package Lgpdjus::Schema::Result::NotificationMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("notification_message");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "notification_message_id_seq",
  },
  "is_test",
  { data_type => "smallint", default_value => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "meta",
  { data_type => "text", default_value => "{}", is_nullable => 0 },
  "icon",
  { data_type => "bigint", is_nullable => 1 },
  "created_by_admin_user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
__PACKAGE__->has_many(
  "notification_logs",
  "Lgpdjus::Schema::Result::NotificationLog",
  { "foreign.notification_message_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-27 17:48:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8RuK8/oOd9UnVXTNDmc3Ug

__PACKAGE__->belongs_to(
    "admin_user",
    "Lgpdjus::Schema::Result::DirectusUser",
    {id            => "created_by_admin_user_id"},
    {is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT",},
);

use JSON;

sub meta__count {
    my $self = shift;
    my $obj = from_json($self->meta);
    return $obj->{count};
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
