-- Deploy lgpdjus:0006-notification_message to pg
-- requires: 0005-update-data-tests

BEGIN;

alter table notification_message add column cliente_id int;
ALTER TABLE notification_message ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE CASCADE;

COMMIT;
