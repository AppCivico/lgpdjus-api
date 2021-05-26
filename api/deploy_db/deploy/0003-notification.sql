-- Deploy lgpdjus:0003-notification to pg
-- requires: 0002-is_on_blockchain

BEGIN;

update preferences set name='NOTIFY_BY_APP', label='Receber notificações com atualizações da solicitação' where name='NOTIFY_BY_EMAIL';

COMMIT;
