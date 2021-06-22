#<<<
use utf8;
package Lgpdjus::Schema::Result::Sobrelgpd;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("sobrelgpd");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sobrelgpd_id_seq",
  },
  "sort",
  { data_type => "integer", is_nullable => 1 },
  "user_created",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "date_created",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "user_updated",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "date_updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "perguntas",
  { data_type => "json", is_nullable => 1 },
  "nome",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "descricao",
  { data_type => "varchar", is_nullable => 1, size => 400 },
  "is_test",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "introducao_linha_1",
  { data_type => "text", is_nullable => 1 },
  "introducao_linha_2",
  { data_type => "text", is_nullable => 1 },
  "rodape",
  { data_type => "text", is_nullable => 1 },
  "link_imagem",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-06-22 13:35:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dj7UhQsg0oNqUYYl+GjnRA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
