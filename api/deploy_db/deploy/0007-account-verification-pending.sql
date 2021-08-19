-- Deploy lgpdjus:0007-account-verification-pending to pg
-- requires: 0006-notification_message

BEGIN;

alter table clientes add column account_verification_locked boolean not null default false;

update clientes set
account_verification_locked = true
where id in (
    select cliente_id from clientes_quiz_session c
    join questionnaires q on q.id = c.questionnaire_id
    where c.finished_at is null
    and q.code = 'verify_account'
    and c.deleted_at is null
);

update clientes set account_verification_pending = false where account_verification_pending;

update clientes set
account_verification_pending = true
where id in (
    select cliente_id from tickets t
    join questionnaires q on q.id = t.questionnaire_id
    where t.status = 'pending'
    and q.code = 'verify_account'
);

COMMIT;
