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

alter table public.configuracoes drop column texto_faq_index;
alter table public.configuracoes drop column texto_faq_contato;
--delete from directus_fields where field='texto_faq_contato' or field= 'texto_faq_index';
alter table public.configuracoes add column texto_sobre varchar not null default 'texto tela sobre';


alter table public.quiz_config add column camera_lens_direction varchar;
alter table public.quiz_config add column button_style varchar default 'primary';

alter table directus_users add column lgpdjus_items_per_page int not null default 20;

alter table clientes drop column dt_nasc, drop column genero, drop column cep, drop column cep_cidade, drop column cep_estado;

alter table public.quiz_config add column button_change_questionnaire int references questionnaires(id);

alter table quiz_config alter questionnaire_id set not null;

alter table tickets add column started_at timestamp without time zone;
alter table tickets add column closed_at timestamp without time zone;
update tickets set started_at=created_on;
update tickets set closed_at = _x from (select ticket_id, max(created_on) as _x from tickets_responses where type in ('verify_yes','verify_no','response')
group by 1) x
where id = ticket_id;
alter table tickets alter started_at set not null;

alter table questionnaires add column requires_account_verification boolean not null default false;
delete from directus_fields where field= 'end_screen' and collection='questionnaires';
delete from directus_fields where field= 'last_tm_activity' and collection='clientes_app_activity';

alter table questionnaires drop column end_screen;
alter table clientes_app_activity drop column last_tm_activity;

drop table admin_big_numbers;
drop table faq_tela_sobre;
drop table faq_tela_sobre_categoria;
drop table tag_indexing_config;
drop table rss_feeds_tags;
drop table noticias2tags;
drop table rss_feeds cascade;
drop table noticias_aberturas;
drop table noticias;
drop table tags;

delete from directus_fields where collection in (
'admin_big_numbers',
'faq_tela_sobre',
'faq_tela_sobre_categoria',
'tag_indexing_config',
'rss_feeds_tags',
'noticias2tags',
'rss_feeds',
'noticias_aberturas',
'noticias',
'tags');

delete from public.directus_relations where one_collection in (
'admin_big_numbers',
'faq_tela_sobre',
'faq_tela_sobre_categoria',
'tag_indexing_config',
'rss_feeds_tags',
'noticias2tags',
'rss_feeds',
'noticias_aberturas',
'noticias',
'tags');
alter table  questionnaires alter column title type varchar;

COMMIT;
