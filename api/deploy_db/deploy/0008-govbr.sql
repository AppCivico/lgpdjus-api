-- Deploy lgpdjus:0008-govbr to pg
-- requires: 0007-account-verification-pending

BEGIN;

alter table clientes add column email_existente boolean not null default true;
alter table clientes add column govbr_nivel varchar;
alter table clientes add column govbr_info json;

create table govbr_session_log (
    id bigserial not null primary key,
    external_secret varchar(43) not null,
    access_token_json json,
    id_token_json json,
    created_at timestamp without time zone not null default now(),
    logged_as_client_id int,
    access_token varchar,
    id_token varchar
);

COMMIT;
