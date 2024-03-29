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
  "email_config",
  { data_type => "json", default_value => "[]", is_nullable => 0 },
  "dpo_email_destinatary",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "dpo_email_config",
  { data_type => "json", default_value => "[]", is_nullable => 0 },
  "texto_sobre",
  {
    data_type     => "text",
    default_value => "texto tela sobre",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "texto_blockchain_ultima_pagina",
  {
    data_type     => "text",
    default_value => "ultima pagina",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "texto_blockchain_penultima_pagina",
  {
    data_type     => "text",
    default_value => "penultima pagina",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "acessibilidade_android",
  { data_type => "text", is_nullable => 1 },
  "acessibilidade_ios",
  { data_type => "text", is_nullable => 1 },
  "permisoes_e_contas",
  { data_type => "text", is_nullable => 1 },
  "texto_pagina_entrar",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-10-29 22:00:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AxuiuJmYdYTBQ6PcqE/gOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
