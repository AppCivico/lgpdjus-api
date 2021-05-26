-- Deploy lgpdjus:0002-is_on_blockchain to pg
-- requires: 0001-db-init

BEGIN;

alter table media_upload add column is_on_blockchain boolean not null default false;

COMMIT;
