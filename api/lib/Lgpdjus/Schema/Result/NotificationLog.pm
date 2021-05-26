#<<<
use utf8;
package Lgpdjus::Schema::Result::NotificationLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("notification_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "notification_log_id_seq",
  },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "notification_message_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Lgpdjus::Schema::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "notification_message",
  "Lgpdjus::Schema::Result::NotificationMessage",
  { id => "notification_message_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-12 14:21:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jgg3O2ELI+1ZTb0oeo6imQ

# ALTER TABLE notification_log ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE CASCADE;
# ALTER TABLE notification_log ADD FOREIGN KEY (notification_message_id) REFERENCES notification_message(id) ON DELETE RESTRICT ON UPDATE RESTRICT;
# create index ix_notification_log_by_time on notification_log (created_at, cliente_id);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
