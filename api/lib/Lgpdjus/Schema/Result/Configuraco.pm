#<<<
use utf8;
package Lgpdjus::Schema::Result::Configuraco;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Lgpdjus::Schema::Base';
__PACKAGE__->table("configuracoes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "configuracoes_id_seq",
  },
  "termos_de_uso",
  { data_type => "text", is_nullable => 0 },
  "privacidade",
  { data_type => "text", is_nullable => 0 },
  "texto_faq_index",
  { data_type => "text", is_nullable => 1 },
  "texto_faq_contato",
  { data_type => "text", is_nullable => 1 },
  "email_config",
  { data_type => "json", default_value => "[]", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-22 13:08:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AZ5pkj8nTr8XiLHQZ+Lxsg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
