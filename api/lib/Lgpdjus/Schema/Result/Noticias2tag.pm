#<<<
use utf8;
package Lgpdjus::Schema::Result::Noticias2tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("noticias2tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "noticias2tags_id_seq",
  },
  "noticias_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "tag_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "noticia",
  "Lgpdjus::Schema::Result::Noticia",
  { id => "noticias_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "tag",
  "Lgpdjus::Schema::Result::Tag",
  { id => "tag_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-16 09:45:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ACD9S/fc6SWhLPnX1ivdmg

#ALTER TABLE noticias2tags ADD FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;
#ALTER TABLE noticias2tags ADD FOREIGN KEY (noticias_id) REFERENCES noticias(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
