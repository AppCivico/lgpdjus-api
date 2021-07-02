-- Deploy lgpdjus:0004-remove_cond to pg
-- requires: 0003-notification

BEGIN;

alter table questionnaires drop column condition;

alter table questionnaires add column Category_Short varchar(35);
alter table questionnaires add column title varchar(100);
alter table questionnaires add column body varchar(340);
alter table questionnaires add column start_button varchar(35);
alter table questionnaires add column category_full varchar(35);

alter table clientes add column account_verification_pending boolean not null default false;

alter table questionnaires add column legal_info varchar(340);

create unique index ticket_protocol_uniq_idx on tickets(protocol);

alter table quiz_config add column progress_bar smallint not null default 0;
alter table quiz_config alter column question type text;
alter table quiz_config add column appendix json not null default '[]';

alter table notification_message add column created_by_admin_user_id uuid references directus_users(id);
update notification_message set created_by_admin_user_id = (select id from directus_users limit 1) where meta::text like '%created_by%';

alter table quiz_config add column text_validation varchar;

alter table public.configuracoes add column dpo_email_destinatary varchar;
alter table public.configuracoes add column dpo_email_config json DEFAULT '[]'::json NOT NULL;

COMMIT;
