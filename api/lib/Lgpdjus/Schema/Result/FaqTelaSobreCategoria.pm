#<<<
use utf8;
package Lgpdjus::Schema::Result::FaqTelaSobreCategoria;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("faq_tela_sobre_categoria");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "faq_tela_sobre_categoria_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "is_test",
  { data_type => "boolean", is_nullable => 0 },
  "sort",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "faq_tela_sobres",
  "Lgpdjus::Schema::Result::FaqTelaSobre",
  { "foreign.fts_categoria_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-15 18:01:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UouFrfQteJmP2I5wwElEkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
