-- Deploy lgpdjus:0005-update-data-tests to pg
-- requires: 0004-remove_cond

BEGIN;

CREATE OR REPLACE FUNCTION public.f_tgr_quiz_config_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF (TG_OP = 'UPDATE') THEN

        update questionnaires
         set modified_on = now()
         where id = NEW.questionnaire_id OR  id = OLD.questionnaire_id;
     ELSIF (TG_OP = 'INSERT') THEN
        update questionnaires
         set modified_on = now()
         where id = NEW.questionnaire_id;
     END IF;

    RETURN NEW;
END;
$$;

delete from public.quiz_config;
delete from public.questionnaires;

INSERT INTO public.questionnaires (id, created_on, modified_on, active, code, icon_href, label, short_text, is_test, due_days, sort, category_short, title, body, start_button, category_full, legal_info, requires_account_verification) VALUES (7, NULL, '2021-07-19 14:22:24.21668-03', true, 'verify_account', 'document.svg', 'verificar conta (testes)', 'verificar conta', true, 1, 3, 'short 7', 'verify 7', 'body 7', 'start button 7', 'full 7', 'verify 7', false);
INSERT INTO public.questionnaires (id, created_on, modified_on, active, code, icon_href, label, short_text, is_test, due_days, sort, category_short, title, body, start_button, category_full, legal_info, requires_account_verification) VALUES (5, '2020-04-26 21:37:58-03', '2021-06-08 18:59:52.175-03', true, 'unset', '[% 1 %]', 'label 5', 'short_text 5', true, 1, 1, 'cat short 5', 'title 5', 'body 5', 'start button 5', 'cat full 5', NULL, false);
INSERT INTO public.questionnaires (id, created_on, modified_on, active, code, icon_href, label, short_text, is_test, due_days, sort, category_short, title, body, start_button, category_full, legal_info, requires_account_verification) VALUES (4, '2020-04-26 21:36:58-03', '2021-07-19 14:22:24.21668-03', true, 'unset', 'document.svg', 'label 4', 'short_text 4', true, 1, 2, 'cat short 4', 'title 4', 'body 4', 'start button 4', 'cat full 4', 'legal info 4', false);

INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (12, 'published', 1, '2020-07-26 16:15:58-03', 'text', 'freetext', 'question for YES', NULL, NULL, 'yesno1 == ''Y''', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (13, 'published', 1, '2020-07-26 16:15:58-03', 'text', 'freetext', 'question for NO', NULL, NULL, 'yesno1 == ''N''', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (16, 'published', 5, '2020-07-26 16:15:59-03', 'displaytext', 'displaytext', 'displaytext flow', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (28, 'published', 1, NULL, 'text', 'q1', 'verify_account question 1', NULL, NULL, '1', NULL, 7, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (40, 'published', 10, '2021-05-11 11:07:09.551-03', 'yesno', 'yesno_customlabel', 'customyesno question', NULL, NULL, '1', NULL, 4, 'Yup!', 'Nope!', 'no', 'yes', '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (41, 'published', 11, NULL, 'multiplechoices', 'mc', 'multiple choices options', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[{"label":"opção a","value":"a"},{"value":"b","label":"opção b"},{"value":"c","label":"opção c"}]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (42, 'published', 12, NULL, 'onlychoice', 'oc', 'only choice options', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[{"value":"1","label":"opção 1"},{"value":"2","label":"opção 2"},{"value":"3","label":"opção 3"}]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (11, 'published', 0, '2021-06-10 20:49:21.047-03', 'yesno', 'yesno1', 'yesno question☺️⚠️👍👭🤗🤳', NULL, '[{"newItem":true,"text":"intro1"},{"newItem":true,"text":"HELLO[% cliente.nome_completo %]!"}]', '1', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[{"text":"appendix 1"}]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (26, 'published', 60, '2021-07-05 23:55:53.11-03', 'photo_attachment', 'pic1', 'ponha o arquivo', NULL, NULL, '1', 'anexar', 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (18, 'published', 999, '2021-07-05 23:30:58.508-03', 'botao_fim', 'btn_fim', 'Fim. MC=[%json_array_to_string(mc_json)%]. A_Member=[%is_json_member(''a'',mc_json)%] D_Member=[%is_json_member(''d'',mc_json)%]', NULL, NULL, '1', 'btn label fim', 4, NULL, NULL, NULL, NULL, '[]', 99, '[]', NULL, NULL, 'success', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (27, 'published', 990, '2021-07-05 23:33:57.197-03', 'create_ticket', 'ticket', 'create_ticket [% ticket_protocol %]', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (14, 'published', 2, '2021-06-09 20:06:18.347-03', 'yesnogroup', 'groupq', 'a group of yes no questions will start now', '[{"newItem":true,"question":"Question A","power2answer":"1","referencia":"refa","Status":true},{"newItem":true,"question":"Question B","power2answer":"4","referencia":"reb","Status":true}]', NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (76, 'published', 70, NULL, 'botao_continue', 'test_continue', 'texto continuar', NULL, NULL, '1', 'continuar', 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', NULL, NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (73, 'published', 65, '2021-07-05 23:32:45.454-03', 'text', 'test_cpf', 'digite o cpf', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', 'CPF', NULL, 'primary', NULL);
INSERT INTO public.quiz_config (id, status, sort, modified_on, type, code, question, yesnogroup, intro, relevance, button_label, questionnaire_id, yesno_yes_label, yesno_no_label, yesno_no_value, yesno_yes_value, options, progress_bar, appendix, text_validation, camera_lens_direction, button_style, button_change_questionnaire) VALUES (74, 'published', 66, NULL, 'text', 'test_birthday', 'digite data nascimento', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]', 0, '[]', 'birthday', NULL, 'primary', NULL);

SELECT pg_catalog.setval('public.questionnaires_id_seq', 14, true);
SELECT pg_catalog.setval('public.quiz_config_id_seq', 92, true);

CREATE TABLE public.sobrelgpd (
    id integer NOT NULL,
    sort integer,
    user_created uuid,
    date_created timestamp with time zone,
    user_updated uuid,
    date_updated timestamp with time zone,
    perguntas json,
    nome character varying(100),
    descricao character varying(400),
    is_test boolean DEFAULT false NOT NULL,
    introducao_linha_1 text,
    introducao_linha_2 text,
    rodape text,
    link_imagem character varying(255)
);

CREATE SEQUENCE public.sobrelgpd_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE ONLY public.sobrelgpd ALTER COLUMN id SET DEFAULT nextval('public.sobrelgpd_id_seq'::regclass);
ALTER TABLE ONLY public.sobrelgpd
    ADD CONSTRAINT sobrelgpd_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.sobrelgpd
    ADD CONSTRAINT sobrelgpd_user_created_foreign FOREIGN KEY (user_created) REFERENCES public.directus_users(id);
ALTER TABLE ONLY public.sobrelgpd
    ADD CONSTRAINT sobrelgpd_user_updated_foreign FOREIGN KEY (user_updated) REFERENCES public.directus_users(id);

delete from public.configuracoes;
INSERT INTO public.configuracoes (id, termos_de_uso, privacidade, email_config, dpo_email_destinatary, dpo_email_config, texto_sobre) VALUES (1, '...', '...', '[{"template":"signup","subject":"Nova conta no LGPDJUS","body":"<p>Ol&aacute;,</p>\n<p>[% cliente.nome_completo %]</p>\n<p>Sua conta no LGPDJus TJSC foi criada com sucesso! Por meio dessa conta &eacute; poss&iacute;vel criar e acompanhar solicita&ccedil;&otilde;es referentes a nova lei de prote&ccedil;&atilde;o de dados pessoais.</p>\n<p>Em anexo um comprovante da cria&ccedil;&atilde;o da sua conta.</p>","notification_enabled":true,"notification_title":"Bem vindo","notification_content":"Bem vindo ao LGPDJus!","template_file":"generic.html"},{"template":"ticket_created","subject":"Solicitação recebida, protocolo [% ticket.protocol %]","body":"<h1><strong>Ol&aacute;,</strong></h1>\n<p>A solicita&ccedil;&atilde;o [% ticket.protocol %] foi aberta. Qualquer novidade iremos enviar por e-mail ou acompanhe pelo aplicativo.</p>\n<p>Em anexo, segue arquivo em PDF com os dados da solicita&ccedil;&atilde;o.</p>\n<p>Atenciosamente,</p>\n<p>Equipe TJSC</p>\n<p>&nbsp;</p>","notification_enabled":true,"notification_title":"Nova solicitação","notification_content":"A solicitação [% ticket.protocol %] foi aberta."},{"template":"ticket_reopen","subject":"Solicitação reaberta","body":"<h1><strong>Ol&aacute;,</strong></h1>\n<p>A solicita&ccedil;&atilde;o [% ticket.protocol %] foi reaberta.</p>\n<p>&nbsp;</p>","notification_content":"A solicitação [% ticket.protocol %] foi reaberta.","notification_title":"Atualização de solicitação","notification_enabled":true},{"template":"ticket_response_reply","subject":"Resposta recebida, protocolo [%ticket.protocol %]","body":"<h1><strong>Ol&aacute;,</strong></h1>\n<p>Recebemos sua resposta na solicita&ccedil;&atilde;o [% ticket.protocol %].</p>\n<p>&nbsp;</p>","notification_title":"Atualização de solicitação","notification_enabled":true,"notification_content":"Recebemos sua resposta na solicitação [% ticket.protocol %]."},{"template":"ticket_close","body":"<h1>Ol&aacute;,</h1>\n<p>A solicita&ccedil;&atilde;o [%ticket.protocol%] foi finalizada.</p>","subject":"Solicitação [%ticket.protocol%] foi finalizada","notification_title":"Atualização de solicitação","notification_enabled":true,"notification_content":"A solicitação [%ticket.protocol%] foi finalizada."},{"template":"ticket_change_due","body":"<h1>Ol&aacute;,</h1>\n<p>A solicita&ccedil;&atilde;o [%ticket.protocol%] mudou de prazo.</p>","subject":"Mudança de prazo, protocolo [%ticket.protocol%]","notification_title":"Atualização de solicitação","notification_enabled":true,"notification_content":"A solicitação [%ticket.protocol%] mudou de prazo."},{"template":"ticket_verify_yes","subject":"Verificação de conta aprovada.","body":"<h1>Ol&aacute;,</h1>\n<p>[% cliente.nome_completo %], sua conta foi verificada com sucesso pela equipe do TJSC!</p>\n<p>&nbsp;</p>","notification_title":"Conta verificada","notification_enabled":true,"notification_content":"[% cliente.nome_completo %], sua conta foi aprovada!"},{"template":"ticket_verify_no","body":"<h1>Ol&aacute;,</h1>\n<p>[% cliente.nome_completo %], sua conta foi rejeitada pela equipe do TJ-SC.</p>\n<p>Voc&ecirc; poder&aacute; refazer o processo, reenviando as documenta&ccedil;&otilde;es pelo aplicativo do TJ-SC.</p>\n<p>&nbsp;</p>","subject":"Verificação de conta rejeitada.","notification_title":"Conta não verificada","notification_enabled":true,"notification_content":"[% cliente.nome_completo %], sua conta foi rejeitada."},{"template":"ticket_request_additional_info","subject":"Precisamos de novas informações para o andamento do protocolo [% ticket.protocol %]","body":"<h1>Ol&aacute;,</h1>\n<p>Precisamos de novas informa&ccedil;&otilde;es para dar andamento ao protocolo &nbsp;[% ticket.protocol %], entre no aplicativo e responda.</p>","notification_title":"Atualização de solicitação","notification_enabled":true,"notification_content":"Precisamos de novas informações para dar andamento ao protocolo  [% ticket.protocol %], entre no aplicativo e responda."}]', 'renato.santos+dpo@example.com', '[{"template":"new_ticket","subject":"Nova solicitação - [% ticket.protocol %]","body":"<p>Ol&aacute;,</p>\n<p>H&aacute; uma nova solicita&ccedil;&atilde;o de [% ticket.questionnaire.category_full %], protocolo [% ticket.protocol %] aberta por [% cliente.nome_completo %].</p>\n<p>Link: https://lgpdjus-api.example.com/admin/tickets-details?protocol=[% ticket.protocol %]</p>"},{"template":"new_response","subject":"Nova resposta na solicitação [% ticket.protocol %]","body":"<p>Ol&aacute; DPO!</p>\n<p>H&aacute; uma nova resposta de [% ticket.questionnaire.category_full %], protocolo [% ticket.protocol %] enviada por [% cliente.nome_completo %].</p>\n<p>Link: https://lgpdjus-api.example.com/admin/tickets-details?protocol=[% ticket.protocol %]</p>"}]', '...');

alter table public.configuracoes add column texto_blockchain_ultima_pagina varchar not null default 'ultima pagina';
alter table public.configuracoes add column texto_blockchain_penultima_pagina varchar not null default 'penultima pagina';

COMMIT;
