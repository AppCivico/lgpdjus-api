-- Deploy lgpdjus:0009-new-fields to pg
-- requires: 0008-govbr

BEGIN;

alter table configuracoes
add column acessibilidade_android text,
add column acessibilidade_ios text,
add column permisoes_e_contas text,
add column texto_pagina_entrar text;

COMMIT;
