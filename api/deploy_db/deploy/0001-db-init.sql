--
-- PostgreSQL database dump
--

-- quem estiver antes do pg 13, descomentar
-- CREATE EXTENSION if not exists pgcrypto;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


--
-- Name: minion_state; Type: TYPE; Schema: public; Owner: -
--

begin;

CREATE TYPE public.minion_state AS ENUM (
    'inactive',
    'active',
    'failed',
    'finished'
);


--
-- Name: email_inserted_notify(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.email_inserted_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NOTIFY newemail;
        RETURN NULL;
    END;
$$;


--
-- Name: f_tgr_quiz_config_after_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_tgr_quiz_config_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    update questionnaires
     set modified_on = now()
     where id = NEW.questionnaire_id OR id = OLD.questionnaire_id;

    RETURN NEW;
END;
$$;


--
-- Name: minion_jobs_notify_workers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.minion_jobs_notify_workers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  begin
    if new.delayed <= now() then
      notify "minion.job";
    end if;
    return null;
  end;
$$;


--
-- Name: minion_lock(text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.minion_lock(text, integer, integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare
  new_expires timestamp with time zone = now() + (interval '1 second' * $2);
begin
  lock table minion_locks in exclusive mode;
  delete from minion_locks where expires < now();
  if (select count(*) >= $3 from minion_locks where name = $1) then
    return false;
  end if;
  if new_expires > now() then
    insert into minion_locks (name, expires) values ($1, new_expires);
  end if;
  return true;
end;
$_$;


SET default_tablespace = '';

--
-- Name: admin_big_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_big_numbers (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    label character varying(200) DEFAULT NULL::character varying NOT NULL,
    comment character varying(200) DEFAULT NULL::character varying,
    sql text NOT NULL,
    background_class character varying(100) DEFAULT 'bg-light'::character varying NOT NULL,
    text_class character varying(100) DEFAULT 'text-dark'::character varying NOT NULL,
    sort integer
);


--
-- Name: admin_big_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_big_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_big_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_big_numbers_id_seq OWNED BY public.admin_big_numbers.id;


--
-- Name: admin_clientes_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_clientes_segments (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    is_test integer NOT NULL,
    label character varying(200) DEFAULT NULL::character varying NOT NULL,
    last_count bigint,
    last_run_at timestamp with time zone,
    cond text DEFAULT '{}'::text NOT NULL,
    attr text DEFAULT '{}'::text NOT NULL,
    sort integer
);


--
-- Name: admin_clientes_segments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_clientes_segments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_clientes_segments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_clientes_segments_id_seq OWNED BY public.admin_clientes_segments.id;


--
-- Name: blockchain_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchain_records (
    id integer NOT NULL,
    filename character varying(255) NOT NULL,
    digest character varying(255) DEFAULT NULL::character varying NOT NULL,
    media_upload_id character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    dcrtime_timestamp timestamp with time zone,
    decred_merkle_root character varying(255) DEFAULT NULL::character varying,
    decred_capture_txid character varying(255) DEFAULT NULL::character varying,
    created_at_real timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ticket_id integer,
    cliente_id integer
);


--
-- Name: blockchain_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchain_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchain_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchain_records_id_seq OWNED BY public.blockchain_records.id;


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'setup'::character varying NOT NULL,
    created_on timestamp with time zone NOT NULL,
    cpf character varying(200) DEFAULT NULL::character varying NOT NULL,
    dt_nasc date NOT NULL,
    email character varying(200) DEFAULT NULL::character varying NOT NULL,
    cep character varying(8) DEFAULT NULL::character varying NOT NULL,
    cep_cidade character varying(200) DEFAULT NULL::character varying,
    cep_estado character varying(200) DEFAULT NULL::character varying,
    genero character varying(100) DEFAULT NULL::character varying NOT NULL,
    nome_completo character varying(200) DEFAULT NULL::character varying NOT NULL,
    login_status character varying(20) DEFAULT 'OK'::character varying,
    login_status_last_blocked_at timestamp with time zone,
    senha_sha256 character varying(200) DEFAULT NULL::character varying NOT NULL,
    qtde_login_senha_normal bigint DEFAULT '1'::bigint NOT NULL,
    apelido character varying(200) DEFAULT NULL::character varying NOT NULL,
    upload_status character varying(20) DEFAULT 'ok'::character varying,
    perform_delete_at timestamp with time zone,
    deleted_scheduled_meta text,
    deletion_started_at timestamp with time zone,
    account_verified boolean DEFAULT false NOT NULL,
    verified_account_at timestamp with time zone,
    verified_account_info json DEFAULT '{}'::json NOT NULL
);


--
-- Name: COLUMN clientes.dt_nasc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.dt_nasc IS 'data nascimento';


--
-- Name: COLUMN clientes.login_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.login_status IS 'pode ou nao fazer login';


--
-- Name: COLUMN clientes.login_status_last_blocked_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.login_status_last_blocked_at IS 'Horrio que iniciou-se o ltimo bloqueio de 24h, pelo sistema';


--
-- Name: COLUMN clientes.qtde_login_senha_normal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.qtde_login_senha_normal IS 'quantidade de login normal';


--
-- Name: COLUMN clientes.perform_delete_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.perform_delete_at IS 'Preencher YYYY-MM-DD HH:MM:SS com segundos (ou não ficará salvo)';


--
-- Name: clientes_active_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_active_sessions (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL
);


--
-- Name: clientes_active_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_active_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_active_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_active_sessions_id_seq OWNED BY public.clientes_active_sessions.id;


--
-- Name: clientes_app_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_app_activity (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    last_tm_activity timestamp with time zone,
    last_activity timestamp with time zone
);


--
-- Name: clientes_app_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_app_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_app_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_app_activity_id_seq OWNED BY public.clientes_app_activity.id;


--
-- Name: clientes_app_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_app_notifications (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    read_until timestamp with time zone NOT NULL
);


--
-- Name: clientes_app_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_app_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_app_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_app_notifications_id_seq OWNED BY public.clientes_app_notifications.id;


--
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_id_seq OWNED BY public.clientes.id;


--
-- Name: clientes_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_preferences (
    id bigint NOT NULL,
    value character varying(200) DEFAULT NULL::character varying NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    cliente_id bigint NOT NULL,
    preference_id bigint NOT NULL
);


--
-- Name: clientes_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_preferences_id_seq OWNED BY public.clientes_preferences.id;


--
-- Name: clientes_quiz_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_quiz_session (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    questionnaire_id bigint NOT NULL,
    finished_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    stash json,
    responses json,
    deleted_at timestamp with time zone,
    deleted boolean DEFAULT false NOT NULL,
    ticket_id integer,
    can_delete boolean DEFAULT true NOT NULL
);


--
-- Name: COLUMN clientes_quiz_session.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes_quiz_session.deleted_at IS 'horario que o usuario pediu para refazer';


--
-- Name: clientes_quiz_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_quiz_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_quiz_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_quiz_session_id_seq OWNED BY public.clientes_quiz_session.id;


--
-- Name: clientes_reset_password; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_reset_password (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    token character varying(200) NOT NULL,
    valid_until timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    requested_by_remote_ip character varying(200) NOT NULL,
    used_by_remote_ip character varying(200) DEFAULT NULL::character varying,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: clientes_reset_password_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_reset_password_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_reset_password_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_reset_password_id_seq OWNED BY public.clientes_reset_password.id;


--
-- Name: configuracoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracoes (
    id bigint NOT NULL,
    termos_de_uso text NOT NULL,
    privacidade text NOT NULL,
    texto_faq_index text,
    texto_faq_contato text,
    email_config json DEFAULT '[]'::json NOT NULL
);


--
-- Name: configuracoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuracoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuracoes_id_seq OWNED BY public.configuracoes.id;


--
-- Name: delete_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delete_log (
    id bigint NOT NULL,
    data json DEFAULT '{}'::json NOT NULL,
    email_md5 character varying(200) DEFAULT NULL::character varying NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: delete_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delete_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delete_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delete_log_id_seq OWNED BY public.delete_log.id;


--
-- Name: directus_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_activity (
    id integer NOT NULL,
    action character varying(45) NOT NULL,
    "user" uuid,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip character varying(50) NOT NULL,
    user_agent character varying(255),
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    comment text
);


--
-- Name: directus_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_activity_id_seq OWNED BY public.directus_activity.id;


--
-- Name: directus_collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_collections (
    collection character varying(64) NOT NULL,
    icon character varying(30),
    note text,
    display_template character varying(255),
    hidden boolean DEFAULT false NOT NULL,
    singleton boolean DEFAULT false NOT NULL,
    translations json,
    archive_field character varying(64),
    archive_app_filter boolean DEFAULT true NOT NULL,
    archive_value character varying(255),
    unarchive_value character varying(255),
    sort_field character varying(64),
    accountability character varying(255) DEFAULT 'all'::character varying
);


--
-- Name: directus_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_fields (
    id integer NOT NULL,
    collection character varying(64) NOT NULL,
    field character varying(64) NOT NULL,
    special character varying(64),
    interface character varying(64),
    options json,
    display character varying(64),
    display_options json,
    readonly boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    sort integer,
    width character varying(30) DEFAULT 'full'::character varying,
    "group" integer,
    translations json,
    note text
);


--
-- Name: directus_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_fields_id_seq OWNED BY public.directus_fields.id;


--
-- Name: directus_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_files (
    id uuid NOT NULL,
    storage character varying(255) NOT NULL,
    filename_disk character varying(255),
    filename_download character varying(255) NOT NULL,
    title character varying(255),
    type character varying(255),
    folder uuid,
    uploaded_by uuid,
    uploaded_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_by uuid,
    modified_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    charset character varying(50),
    filesize integer,
    width integer,
    height integer,
    duration integer,
    embed character varying(200),
    description text,
    location text,
    tags text,
    metadata json
);


--
-- Name: directus_folders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_folders (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    parent uuid
);


--
-- Name: directus_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_migrations (
    version character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: directus_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_permissions (
    id integer NOT NULL,
    role uuid,
    collection character varying(64) NOT NULL,
    action character varying(10) NOT NULL,
    permissions json,
    validation json,
    presets json,
    fields text,
    "limit" integer
);


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_permissions_id_seq OWNED BY public.directus_permissions.id;


--
-- Name: directus_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_presets (
    id integer NOT NULL,
    bookmark character varying(255),
    "user" uuid,
    role uuid,
    collection character varying(64),
    search character varying(100),
    filters json,
    layout character varying(100) DEFAULT 'tabular'::character varying,
    layout_query json,
    layout_options json,
    refresh_interval integer
);


--
-- Name: directus_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_presets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_presets_id_seq OWNED BY public.directus_presets.id;


--
-- Name: directus_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_relations (
    id integer NOT NULL,
    many_collection character varying(64) NOT NULL,
    many_field character varying(64) NOT NULL,
    many_primary character varying(64) NOT NULL,
    one_collection character varying(64),
    one_field character varying(64),
    one_primary character varying(64),
    one_collection_field character varying(64),
    one_allowed_collections text,
    junction_field character varying(64),
    sort_field character varying(255)
);


--
-- Name: directus_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_relations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_relations_id_seq OWNED BY public.directus_relations.id;


--
-- Name: directus_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_revisions (
    id integer NOT NULL,
    activity integer NOT NULL,
    collection character varying(64) NOT NULL,
    item character varying(255) NOT NULL,
    data json,
    delta json,
    parent integer
);


--
-- Name: directus_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_revisions_id_seq OWNED BY public.directus_revisions.id;


--
-- Name: directus_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_roles (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    icon character varying(30) DEFAULT 'supervised_user_circle'::character varying NOT NULL,
    description text,
    ip_access text,
    enforce_tfa boolean DEFAULT false NOT NULL,
    module_list json,
    collection_list json,
    admin_access boolean DEFAULT false NOT NULL,
    app_access boolean DEFAULT true NOT NULL
);


--
-- Name: directus_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_sessions (
    token character varying(64) NOT NULL,
    "user" uuid NOT NULL,
    expires timestamp with time zone NOT NULL,
    ip character varying(255),
    user_agent character varying(255)
);


--
-- Name: directus_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_settings (
    id integer NOT NULL,
    project_name character varying(100) DEFAULT 'Directus'::character varying NOT NULL,
    project_url character varying(255),
    project_color character varying(10),
    project_logo uuid,
    public_foreground uuid,
    public_background uuid,
    public_note text,
    auth_login_attempts integer DEFAULT 25,
    auth_password_policy character varying(100),
    storage_asset_transform character varying(7) DEFAULT 'all'::character varying,
    storage_asset_presets json,
    custom_css text
);


--
-- Name: directus_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_settings_id_seq OWNED BY public.directus_settings.id;


--
-- Name: directus_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_users (
    id uuid NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    email character varying(128) NOT NULL,
    password character varying(255),
    location character varying(255),
    title character varying(50),
    description text,
    tags json,
    avatar uuid,
    language character varying(8) DEFAULT 'en-US'::character varying,
    theme character varying(20) DEFAULT 'auto'::character varying,
    tfa_secret character varying(255),
    status character varying(16) DEFAULT 'active'::character varying NOT NULL,
    role uuid,
    token character varying(255),
    last_access timestamp with time zone,
    last_page character varying(255)
);


--
-- Name: directus_webhooks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directus_webhooks (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    method character varying(10) DEFAULT 'POST'::character varying NOT NULL,
    url text,
    status character varying(10) DEFAULT 'active'::character varying NOT NULL,
    data boolean DEFAULT true NOT NULL,
    actions character varying(100) NOT NULL,
    collections text
);


--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directus_webhooks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directus_webhooks_id_seq OWNED BY public.directus_webhooks.id;


--
-- Name: emaildb_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emaildb_config (
    id integer NOT NULL,
    "from" character varying NOT NULL,
    template_resolver_class character varying(60) NOT NULL,
    template_resolver_config json DEFAULT '{}'::json NOT NULL,
    email_transporter_class character varying(60) NOT NULL,
    email_transporter_config json DEFAULT '{}'::json NOT NULL,
    delete_after interval DEFAULT '7 days'::interval NOT NULL
);


--
-- Name: emaildb_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emaildb_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emaildb_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emaildb_config_id_seq OWNED BY public.emaildb_config.id;


--
-- Name: emaildb_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emaildb_queue (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    config_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    template character varying NOT NULL,
    "to" character varying NOT NULL,
    subject character varying NOT NULL,
    variables json NOT NULL,
    sent boolean,
    updated_at timestamp without time zone,
    visible_after timestamp without time zone,
    errmsg character varying
);


--
-- Name: faq_tela_sobre; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faq_tela_sobre (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    title text,
    content_html text NOT NULL,
    exibir_titulo_inline boolean DEFAULT false,
    sort integer,
    fts_categoria_id bigint NOT NULL
);


--
-- Name: faq_tela_sobre_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faq_tela_sobre_categoria (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    title text NOT NULL,
    is_test boolean NOT NULL,
    sort integer
);


--
-- Name: faq_tela_sobre_categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faq_tela_sobre_categoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_tela_sobre_categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faq_tela_sobre_categoria_id_seq OWNED BY public.faq_tela_sobre_categoria.id;


--
-- Name: faq_tela_sobre_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faq_tela_sobre_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: faq_tela_sobre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faq_tela_sobre_id_seq OWNED BY public.faq_tela_sobre.id;


--
-- Name: lgpdjus_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lgpdjus_config (
    id integer NOT NULL,
    name character varying(255) DEFAULT NULL::character varying NOT NULL,
    value character varying(255) DEFAULT NULL::character varying NOT NULL,
    valid_from timestamp with time zone,
    valid_to timestamp with time zone
);


--
-- Name: login_erros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_erros (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    remote_ip character varying(200) NOT NULL,
    cliente_id bigint NOT NULL
);


--
-- Name: login_erros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_erros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_erros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_erros_id_seq OWNED BY public.login_erros.id;


--
-- Name: login_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_logs (
    id bigint NOT NULL,
    remote_ip character varying(200) DEFAULT NULL::character varying NOT NULL,
    cliente_id bigint,
    app_version character varying(800) DEFAULT NULL::character varying,
    created_at timestamp with time zone
);


--
-- Name: login_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_logs_id_seq OWNED BY public.login_logs.id;


--
-- Name: media_upload; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_upload (
    id character varying(200) NOT NULL,
    file_info text,
    file_sha1 character varying(200) NOT NULL,
    file_size bigint,
    s3_path text NOT NULL,
    cliente_id bigint NOT NULL,
    intention character varying(200) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    s3_path_avatar text,
    file_size_avatar bigint
);


--
-- Name: COLUMN media_upload.file_sha1; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.media_upload.file_sha1 IS 'SHA1 do arquivo original (upload); não é o SHA1 dos arquivos do S3';


--
-- Name: minion_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.minion_jobs (
    id bigint NOT NULL,
    args jsonb NOT NULL,
    attempts integer DEFAULT 1 NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    delayed timestamp with time zone NOT NULL,
    finished timestamp with time zone,
    notes jsonb DEFAULT '{}'::jsonb NOT NULL,
    parents bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    priority integer NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    result jsonb,
    retried timestamp with time zone,
    retries integer DEFAULT 0 NOT NULL,
    started timestamp with time zone,
    state public.minion_state DEFAULT 'inactive'::public.minion_state NOT NULL,
    task text NOT NULL,
    worker bigint,
    expires timestamp with time zone,
    lax boolean DEFAULT false NOT NULL,
    CONSTRAINT minion_jobs_args_check CHECK ((jsonb_typeof(args) = 'array'::text)),
    CONSTRAINT minion_jobs_notes_check CHECK ((jsonb_typeof(notes) = 'object'::text))
);


--
-- Name: minion_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.minion_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: minion_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.minion_jobs_id_seq OWNED BY public.minion_jobs.id;


--
-- Name: minion_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.minion_locks (
    id bigint NOT NULL,
    name text NOT NULL,
    expires timestamp with time zone NOT NULL
);


--
-- Name: minion_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.minion_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: minion_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.minion_locks_id_seq OWNED BY public.minion_locks.id;


--
-- Name: minion_workers; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.minion_workers (
    id bigint NOT NULL,
    host text NOT NULL,
    inbox jsonb DEFAULT '[]'::jsonb NOT NULL,
    notified timestamp with time zone DEFAULT now() NOT NULL,
    pid integer NOT NULL,
    started timestamp with time zone DEFAULT now() NOT NULL,
    status jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT minion_workers_inbox_check CHECK ((jsonb_typeof(inbox) = 'array'::text)),
    CONSTRAINT minion_workers_status_check CHECK ((jsonb_typeof(status) = 'object'::text))
);


--
-- Name: minion_workers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.minion_workers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: minion_workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.minion_workers_id_seq OWNED BY public.minion_workers.id;


--
-- Name: mojo_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mojo_migrations (
    name text NOT NULL,
    version bigint NOT NULL,
    CONSTRAINT mojo_migrations_version_check CHECK ((version >= 0))
);


--
-- Name: noticias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias (
    id bigint NOT NULL,
    title character varying(2000) DEFAULT NULL::character varying NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    display_created_time timestamp with time zone NOT NULL,
    hyperlink character varying(2000) DEFAULT NULL::character varying NOT NULL,
    indexed boolean DEFAULT false NOT NULL,
    indexed_at timestamp with time zone,
    author character varying(200) DEFAULT NULL::character varying,
    info json DEFAULT '{}'::json NOT NULL,
    fonte character varying(2000) DEFAULT NULL::character varying,
    published character varying(20) DEFAULT 'hidden'::character varying,
    logs text,
    image_hyperlink character varying(2000) DEFAULT NULL::character varying,
    tags_index character varying(2000) DEFAULT ',,'::character varying NOT NULL,
    has_topic_tags boolean DEFAULT false NOT NULL,
    rss_feed_id bigint
);


--
-- Name: COLUMN noticias.author; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.author IS 'campo author quando que vem no feed';


--
-- Name: COLUMN noticias.info; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.info IS 'JSON com informações para o tagamento automatico';


--
-- Name: COLUMN noticias.fonte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.fonte IS 'campo author quando que vem no feed';


--
-- Name: COLUMN noticias.image_hyperlink; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias.image_hyperlink IS 'URL para a imagem (extraída do metameta[property="og:image"] no caso do feed]';


--
-- Name: noticias2tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias2tags (
    id bigint NOT NULL,
    noticias_id bigint,
    tag_id bigint
);


--
-- Name: noticias2tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias2tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias2tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias2tags_id_seq OWNED BY public.noticias2tags.id;


--
-- Name: noticias_aberturas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias_aberturas (
    id bigint NOT NULL,
    track_id character varying(200) DEFAULT NULL::character varying NOT NULL,
    created_at timestamp with time zone NOT NULL,
    noticias_id bigint NOT NULL,
    cliente_id bigint NOT NULL
);


--
-- Name: COLUMN noticias_aberturas.track_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.noticias_aberturas.track_id IS 'id do link gerado, se tiver repetido em menos de 1h, pro mesmo user/noticia, clicou mais de uma vez';


--
-- Name: noticias_aberturas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias_aberturas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias_aberturas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias_aberturas_id_seq OWNED BY public.noticias_aberturas.id;


--
-- Name: noticias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticias_id_seq OWNED BY public.noticias.id;


--
-- Name: notification_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_log (
    id bigint NOT NULL,
    created_at timestamp with time zone,
    cliente_id bigint NOT NULL,
    notification_message_id bigint NOT NULL
);


--
-- Name: notification_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_log_id_seq OWNED BY public.notification_log.id;


--
-- Name: notification_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_message (
    id bigint NOT NULL,
    is_test smallint DEFAULT '1'::smallint NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    meta text DEFAULT '{}'::text NOT NULL,
    icon bigint
);


--
-- Name: notification_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_message_id_seq OWNED BY public.notification_message.id;


--
-- Name: lgpdjus_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lgpdjus_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lgpdjus_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lgpdjus_config_id_seq OWNED BY public.lgpdjus_config.id;


--
-- Name: preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preferences (
    id bigint NOT NULL,
    name character varying(200) DEFAULT NULL::character varying NOT NULL,
    label character varying(200) DEFAULT NULL::character varying NOT NULL,
    active boolean NOT NULL,
    initial_value character varying(200) DEFAULT NULL::character varying NOT NULL,
    sort integer DEFAULT 1 NOT NULL
);


--
-- Name: preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preferences_id_seq OWNED BY public.preferences.id;


--
-- Name: questionnaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questionnaires (
    id bigint NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    active boolean NOT NULL,
    condition character varying(2000) DEFAULT '[% 1 %]'::character varying NOT NULL,
    end_screen character varying(200) DEFAULT 'home'::character varying NOT NULL,
    code character varying(2000) DEFAULT 'unset'::character varying NOT NULL,
    icon_href character varying(2000) DEFAULT 'default.svg'::character varying NOT NULL,
    label character varying(2000) DEFAULT '[% 1 %]'::character varying NOT NULL,
    short_text character varying(2000) DEFAULT '[% 1 %]'::character varying NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    due_days integer DEFAULT 1 NOT NULL,
    sort integer DEFAULT 1 NOT NULL
);


--
-- Name: COLUMN questionnaires.condition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.questionnaires.condition IS 'Pra quem deve aparecer';


--
-- Name: questionnaires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questionnaires_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questionnaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questionnaires_id_seq OWNED BY public.questionnaires.id;


--
-- Name: quiz_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_config (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    sort integer,
    modified_on timestamp with time zone,
    type character varying(100) DEFAULT NULL::character varying NOT NULL,
    code character varying(100) DEFAULT NULL::character varying NOT NULL,
    question character varying(800) DEFAULT NULL::character varying NOT NULL,
    yesnogroup json,
    intro json,
    relevance character varying(2000) DEFAULT '1'::character varying NOT NULL,
    button_label character varying(200) DEFAULT NULL::character varying,
    questionnaire_id bigint,
    yesno_yes_label character varying(200) DEFAULT NULL::character varying,
    yesno_no_label character varying(200) DEFAULT NULL::character varying,
    yesno_no_value character varying(200) DEFAULT NULL::character varying,
    yesno_yes_value character varying(200) DEFAULT NULL::character varying,
    options json DEFAULT '[]'::json NOT NULL
);


--
-- Name: COLUMN quiz_config.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.code IS 'Identificador da resposta, precisa iniciar com A-Z, depois A-Z0-9 e _';


--
-- Name: COLUMN quiz_config.question; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.question IS 'Pode usar template TT para  formatar o texto e usar respostas anteriores';


--
-- Name: COLUMN quiz_config.yesnogroup; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.yesnogroup IS 'Até 20 questões sim/não. Cada resposta "sim" será "adicionada" {AND operation} para a resposta, baseado em Power2anwser. ';


--
-- Name: COLUMN quiz_config.intro; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.intro IS 'Textos de intrução';


--
-- Name: COLUMN quiz_config.button_label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.quiz_config.button_label IS 'Texto para ser usado no label do botão';


--
-- Name: quiz_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_config_id_seq OWNED BY public.quiz_config.id;


--
-- Name: rss_feeds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rss_feeds (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp with time zone,
    modified_on timestamp with time zone,
    url character varying(2000) DEFAULT NULL::character varying NOT NULL,
    next_tick timestamp with time zone,
    last_run timestamp with time zone,
    fonte character varying(200) DEFAULT NULL::character varying,
    autocapitalize boolean DEFAULT false NOT NULL,
    last_error_message text
);


--
-- Name: COLUMN rss_feeds.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.url IS 'URL do XML do feed RSS/Atom feed';


--
-- Name: COLUMN rss_feeds.next_tick; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.next_tick IS 'proxima vez que irá ser verificado';


--
-- Name: COLUMN rss_feeds.last_run; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.last_run IS 'ultima vez que rodou';


--
-- Name: COLUMN rss_feeds.fonte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.fonte IS 'Salvo no campo Fonte da noticia';


--
-- Name: COLUMN rss_feeds.autocapitalize; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.rss_feeds.autocapitalize IS 'Transformar Title Em CapitalCase';


--
-- Name: rss_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rss_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rss_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rss_feeds_id_seq OWNED BY public.rss_feeds.id;


--
-- Name: rss_feeds_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rss_feeds_tags (
    id integer NOT NULL,
    rss_feeds_id bigint,
    tags_id bigint
);


--
-- Name: rss_feeds_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rss_feeds_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rss_feeds_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rss_feeds_tags_id_seq OWNED BY public.rss_feeds_tags.id;


--
-- Name: tag_indexing_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag_indexing_config (
    id bigint NOT NULL,
    created_on timestamp with time zone,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    tag_id bigint NOT NULL,
    description character varying(200) DEFAULT NULL::character varying,
    page_title_match text,
    page_title_not_match text,
    html_article_match text,
    html_article_not_match character varying(200) DEFAULT NULL::character varying,
    page_description_match text,
    page_description_not_match text,
    url_match text,
    url_not_match text,
    rss_feed_tags_match text,
    rss_feed_tags_not_match text,
    rss_feed_content_match character varying(200) DEFAULT NULL::character varying,
    rss_feed_content_not_match text,
    regexp boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    error_msg text DEFAULT ''::text,
    verified_at timestamp with time zone,
    modified_on timestamp with time zone
);


--
-- Name: COLUMN tag_indexing_config.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.description IS 'Descrição (não é usado pelo sistema)';


--
-- Name: COLUMN tag_indexing_config.page_title_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_title_match IS 'match no atributo <title> do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.page_title_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_title_not_match IS 'match no atributo <title> do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.html_article_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.html_article_match IS 'match em text dentro de tags <article> (usar com cautela!)';


--
-- Name: COLUMN tag_indexing_config.html_article_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.html_article_not_match IS 'match em text dentro de tags <article> (usar com cautela!)';


--
-- Name: COLUMN tag_indexing_config.page_description_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_description_match IS 'match na meta og:description do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.page_description_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.page_description_not_match IS 'match na meta og:description do html da pagina (Feed + HTML)';


--
-- Name: COLUMN tag_indexing_config.url_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.url_match IS 'match na URL';


--
-- Name: COLUMN tag_indexing_config.url_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.url_not_match IS 'match na URL';


--
-- Name: COLUMN tag_indexing_config.rss_feed_tags_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_tags_match IS 'match no tags do RSS, se existir';


--
-- Name: COLUMN tag_indexing_config.rss_feed_tags_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_tags_not_match IS 'match no tags do RSS, se existir';


--
-- Name: COLUMN tag_indexing_config.rss_feed_content_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_content_match IS 'match em text dentro do content do RSS Feed se existir';


--
-- Name: COLUMN tag_indexing_config.rss_feed_content_not_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.rss_feed_content_not_match IS 'match em text dentro do content do RSS Feed se existir';


--
-- Name: COLUMN tag_indexing_config.regexp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.regexp IS 'Se os valores são regexp ou texto. Quando texto, use PIPE para criar uma lista de palavras, quando regexp';


--
-- Name: COLUMN tag_indexing_config.verified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.verified IS 'Se o sistema conseguiu validar esta config';


--
-- Name: COLUMN tag_indexing_config.error_msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.error_msg IS 'Erro informado pelo sistema';


--
-- Name: COLUMN tag_indexing_config.verified_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tag_indexing_config.verified_at IS 'o sistema verifica novamente todas que verified_at < modified_on';


--
-- Name: tag_indexing_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_indexing_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_indexing_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_indexing_config_id_seq OWNED BY public.tag_indexing_config.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    status character varying(20) DEFAULT 'prod'::character varying NOT NULL,
    title character varying(200) DEFAULT NULL::character varying NOT NULL,
    created_at timestamp with time zone NOT NULL,
    show_on_filters boolean DEFAULT false NOT NULL,
    topic_order bigint DEFAULT 0 NOT NULL,
    is_topic boolean
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id integer NOT NULL,
    cliente_id bigint NOT NULL,
    due_date timestamp with time zone NOT NULL,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    created_on timestamp with time zone NOT NULL,
    content json NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    content_hash256 character varying(255) DEFAULT NULL::character varying NOT NULL,
    questionnaire_id bigint NOT NULL,
    cliente_pdf_media_upload_id character varying(255) DEFAULT NULL::character varying,
    user_pdf_media_upload_id character varying(255) DEFAULT NULL::character varying,
    protocol bigint NOT NULL,
    CONSTRAINT status_is_ok CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('done'::character varying)::text, ('wait-additional-info'::character varying)::text])))
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: tickets_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets_responses (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    cliente_id bigint NOT NULL,
    reply_content text NOT NULL,
    cliente_reply text,
    ticket_id integer NOT NULL,
    cliente_attachments json DEFAULT '[]'::json NOT NULL,
    created_on timestamp with time zone NOT NULL,
    type character varying(255) DEFAULT 'response'::character varying NOT NULL,
    cliente_reply_created_at timestamp with time zone
);


--
-- Name: tickets_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_responses_id_seq OWNED BY public.tickets_responses.id;


--
-- Name: view_user_preferences; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_user_preferences AS
 SELECT p.name,
    c.id AS cliente_id,
    COALESCE(cp.value, p.initial_value) AS value
   FROM ((public.preferences p
     CROSS JOIN public.clientes c)
     LEFT JOIN public.clientes_preferences cp ON (((cp.cliente_id = c.id) AND (cp.preference_id = p.id))));


--
-- Name: admin_big_numbers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_big_numbers ALTER COLUMN id SET DEFAULT nextval('public.admin_big_numbers_id_seq'::regclass);


--
-- Name: admin_clientes_segments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_clientes_segments ALTER COLUMN id SET DEFAULT nextval('public.admin_clientes_segments_id_seq'::regclass);


--
-- Name: blockchain_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_records ALTER COLUMN id SET DEFAULT nextval('public.blockchain_records_id_seq'::regclass);


--
-- Name: clientes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id SET DEFAULT nextval('public.clientes_id_seq'::regclass);


--
-- Name: clientes_active_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_active_sessions ALTER COLUMN id SET DEFAULT nextval('public.clientes_active_sessions_id_seq'::regclass);


--
-- Name: clientes_app_activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity ALTER COLUMN id SET DEFAULT nextval('public.clientes_app_activity_id_seq'::regclass);


--
-- Name: clientes_app_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_notifications ALTER COLUMN id SET DEFAULT nextval('public.clientes_app_notifications_id_seq'::regclass);


--
-- Name: clientes_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences ALTER COLUMN id SET DEFAULT nextval('public.clientes_preferences_id_seq'::regclass);


--
-- Name: clientes_quiz_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session ALTER COLUMN id SET DEFAULT nextval('public.clientes_quiz_session_id_seq'::regclass);


--
-- Name: clientes_reset_password id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reset_password ALTER COLUMN id SET DEFAULT nextval('public.clientes_reset_password_id_seq'::regclass);


--
-- Name: configuracoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes ALTER COLUMN id SET DEFAULT nextval('public.configuracoes_id_seq'::regclass);


--
-- Name: delete_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delete_log ALTER COLUMN id SET DEFAULT nextval('public.delete_log_id_seq'::regclass);


--
-- Name: directus_activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_activity ALTER COLUMN id SET DEFAULT nextval('public.directus_activity_id_seq'::regclass);


--
-- Name: directus_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_fields ALTER COLUMN id SET DEFAULT nextval('public.directus_fields_id_seq'::regclass);


--
-- Name: directus_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_permissions ALTER COLUMN id SET DEFAULT nextval('public.directus_permissions_id_seq'::regclass);


--
-- Name: directus_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_presets ALTER COLUMN id SET DEFAULT nextval('public.directus_presets_id_seq'::regclass);


--
-- Name: directus_relations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_relations ALTER COLUMN id SET DEFAULT nextval('public.directus_relations_id_seq'::regclass);


--
-- Name: directus_revisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_revisions ALTER COLUMN id SET DEFAULT nextval('public.directus_revisions_id_seq'::regclass);


--
-- Name: directus_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_settings ALTER COLUMN id SET DEFAULT nextval('public.directus_settings_id_seq'::regclass);


--
-- Name: directus_webhooks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_webhooks ALTER COLUMN id SET DEFAULT nextval('public.directus_webhooks_id_seq'::regclass);


--
-- Name: emaildb_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_config ALTER COLUMN id SET DEFAULT nextval('public.emaildb_config_id_seq'::regclass);


--
-- Name: faq_tela_sobre id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre ALTER COLUMN id SET DEFAULT nextval('public.faq_tela_sobre_id_seq'::regclass);


--
-- Name: faq_tela_sobre_categoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre_categoria ALTER COLUMN id SET DEFAULT nextval('public.faq_tela_sobre_categoria_id_seq'::regclass);


--
-- Name: lgpdjus_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lgpdjus_config ALTER COLUMN id SET DEFAULT nextval('public.lgpdjus_config_id_seq'::regclass);


--
-- Name: login_erros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_erros ALTER COLUMN id SET DEFAULT nextval('public.login_erros_id_seq'::regclass);


--
-- Name: login_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs ALTER COLUMN id SET DEFAULT nextval('public.login_logs_id_seq'::regclass);


--
-- Name: minion_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_jobs ALTER COLUMN id SET DEFAULT nextval('public.minion_jobs_id_seq'::regclass);


--
-- Name: minion_locks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_locks ALTER COLUMN id SET DEFAULT nextval('public.minion_locks_id_seq'::regclass);


--
-- Name: minion_workers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_workers ALTER COLUMN id SET DEFAULT nextval('public.minion_workers_id_seq'::regclass);


--
-- Name: noticias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias ALTER COLUMN id SET DEFAULT nextval('public.noticias_id_seq'::regclass);


--
-- Name: noticias2tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias2tags ALTER COLUMN id SET DEFAULT nextval('public.noticias2tags_id_seq'::regclass);


--
-- Name: noticias_aberturas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_aberturas ALTER COLUMN id SET DEFAULT nextval('public.noticias_aberturas_id_seq'::regclass);


--
-- Name: notification_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log ALTER COLUMN id SET DEFAULT nextval('public.notification_log_id_seq'::regclass);


--
-- Name: notification_message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_message ALTER COLUMN id SET DEFAULT nextval('public.notification_message_id_seq'::regclass);


--
-- Name: preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences ALTER COLUMN id SET DEFAULT nextval('public.preferences_id_seq'::regclass);


--
-- Name: questionnaires id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires ALTER COLUMN id SET DEFAULT nextval('public.questionnaires_id_seq'::regclass);


--
-- Name: quiz_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config ALTER COLUMN id SET DEFAULT nextval('public.quiz_config_id_seq'::regclass);


--
-- Name: rss_feeds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds ALTER COLUMN id SET DEFAULT nextval('public.rss_feeds_id_seq'::regclass);


--
-- Name: rss_feeds_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags ALTER COLUMN id SET DEFAULT nextval('public.rss_feeds_tags_id_seq'::regclass);


--
-- Name: tag_indexing_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_indexing_config ALTER COLUMN id SET DEFAULT nextval('public.tag_indexing_config_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: tickets_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets_responses ALTER COLUMN id SET DEFAULT nextval('public.tickets_responses_id_seq'::regclass);


--
-- Data for Name: admin_big_numbers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.admin_big_numbers VALUES (16, 'published', '2021-04-14 14:29:41.415+00', '2021-04-14 14:29:46.816+00', 'Número de clientes', NULL, 'select count(1) from clientes', 'bg-light', 'text-dark', NULL);


--
-- Data for Name: admin_clientes_segments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: blockchain_records; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes_active_sessions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes_app_activity; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes_app_notifications; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes_preferences; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes_quiz_session; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: clientes_reset_password; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: configuracoes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.configuracoes VALUES (1, '<h1>texto termos de uso configurado na tabela configura&ccedil;&otilde;es</h1>
<p>&nbsp;</p>
<div id="Content">
<div id="Translation">
<h3>The standard Lorem Ipsum passage, used since the 1500s</h3>
<p>"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."</p>
<h3>Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"</p>
<h3>1914 translation by H. Rackham</h3>
<p>"But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?"</p>
<h3>Section 1.10.33 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat."</p>
<h3>1914 translation by H. Rackham</h3>
<p>"On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains."</p>
</div>
</div>
<p>&nbsp;</p>', '<h1>texto privacidade configuradona tabela configura&ccedil;&otilde;es</h1>
<p>&nbsp;</p>
<h3>The standard Lorem Ipsum passage, used since the 1500s</h3>
<p>"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."</p>
<h3>Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"</p>
<h3>1914 translation by H. Rackham</h3>
<p>"But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?"</p>
<h3>Section 1.10.33 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat."</p>
<h3>1914 translation by H. Rackham</h3>
<p>"On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains."</p>', '<h1>Texto FAQ introdu&ccedil;&atilde;o configurado&nbsp;</h1>
<h1>na tabela configura&ccedil;&otilde;es</h1>
<h3>The standard Lorem Ipsum passage, used since the 1500s</h3>
<p>"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."</p>
<h3>Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"</p>
<h3>1914 translation by H. Rackham</h3>
<p>"But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?"</p>
<h3>Section 1.10.33 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat."</p>
<h3>1914 translation by H. Rackham</h3>
<p>"On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains."</p>', '<h1>texto faq contato configurado na tabela configura&ccedil;&otilde;es</h1>
<h3>The standard Lorem Ipsum passage, used since the 1500s</h3>
<p>"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."</p>
<h3>Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"</p>
<h3>1914 translation by H. Rackham</h3>
<p>"But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?"</p>
<h3>Section 1.10.33 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC</h3>
<p>"At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat."</p>
<h3>1914 translation by H. Rackham</h3>
<p>"On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains."</p>', '[{"template":"signup","subject":"Nova conta no LGPDJUS","body":"<p>Ol&aacute;,</p>\n<p>[% cliente.nome_completo %]</p>\n<p>Sua conta no LGPDJus TJSC foi criada com sucesso!</p>\n<p>Em anexo um comprovante da cria&ccedil;&atilde;o da sua conta.</p>"},{"template":"ticket_created","subject":"Solicitação recebida, protocolo [% ticket.protocol %]","body":"<h1><strong>Ol&aacute;,</strong></h1>\n<p>A solicita&ccedil;&atilde;o [% ticket.protocol %] foi aberta.</p>\n<p>&nbsp;</p>"},{"template":"ticket_reopen","subject":"Solicitação reaberta","body":"<h1><strong>Ol&aacute;,</strong></h1>\n<p>A solicita&ccedil;&atilde;o [% ticket.protocol %] foi reaberta.</p>\n<p>&nbsp;</p>"},{"template":"ticket_response_reply","subject":"Resposta recebida, protocolo [%ticket.protocol %]","body":"<h1><strong>Ol&aacute;,</strong></h1>\n<p>Recebemos sua resposta na solicita&ccedil;&atilde;o [% ticket.protocol %].</p>\n<p>&nbsp;</p>"},{"template":"ticket_close","body":"<h1>Ol&aacute;,</h1>\n<p>A solicita&ccedil;&atilde;o [%ticket.protocol%] foi finalizada.</p>","subject":"Solicitação [%ticket.protocol%] foi finalizada"},{"template":"ticket_change_due","body":"<h1>Ol&aacute;,</h1>\n<p>A solicita&ccedil;&atilde;o [%ticket.protocol%] mudou de prazo.</p>","subject":"Mudança de prazo, protocolo [%ticket.protocol%]"},{"template":"ticket_verify_yes","subject":"Verificação de conta aprovada.","body":"<h1>Ol&aacute;,</h1>\n<p>[% cliente.nome_completo %], sua conta foi aprovada!</p>\n<p>&nbsp;</p>"},{"template":"ticket_verify_no","body":"<h1>Ol&aacute;,</h1>\n<p>[% cliente.nome_completo %], sua conta foi rejeitada.</p>\n<p>&nbsp;</p>","subject":"Verificação de conta rejeitada."},{"template":"ticket_request_additional_info","subject":"Precisamos de novas informações para o andamento do protocolo [% ticket.protocol %]","body":"<h1>Ol&aacute;,</h1>\n<p>Precisamos de novas informa&ccedil;&otilde;es para dar andamento ao protocolo &nbsp;[% ticket.protocol %], entre no aplicativo e responda.</p>"}]');


--
-- Data for Name: delete_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: directus_activity; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: directus_collections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_collections VALUES ('blockchain_records', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('configuracoes', NULL, NULL, NULL, false, true, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('ponto_apoio', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('clientes_audios_eventos', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('minion_jobs', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('minion_workers', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('emaildb_config', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('emaildb_queue', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('minion_locks', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('admin_big_numbers', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');
INSERT INTO public.directus_collections VALUES ('admin_clientes_segments', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');
INSERT INTO public.directus_collections VALUES ('clientes', NULL, NULL, '(ID{{id}}) {{email}}-{{apelido}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('mojo_migrations', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('quiz_config', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');
INSERT INTO public.directus_collections VALUES ('clientes_quiz_session', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('clientes_preferences', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('clientes_active_sessions', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('clientes_app_activity', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('clientes_app_notifications', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('clientes_reset_password', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('delete_log', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('lgpdjus_config', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('login_logs', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('login_erros', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('media_upload', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('notification_log', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('notification_message', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('tag_indexing_config', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('noticias_aberturas', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('noticias2tags', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('noticias', NULL, NULL, NULL, false, false, NULL, 'published', true, 'published:testing', 'published', NULL, 'all');
INSERT INTO public.directus_collections VALUES ('rss_feeds_tags', 'import_export', NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('tags', NULL, NULL, NULL, false, false, NULL, 'status', true, 'dev', 'prod', NULL, 'all');
INSERT INTO public.directus_collections VALUES ('rss_feeds', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('preferences', NULL, NULL, NULL, true, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');
INSERT INTO public.directus_collections VALUES ('tickets', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('tickets_responses', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, NULL, 'all');
INSERT INTO public.directus_collections VALUES ('faq_tela_sobre_categoria', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');
INSERT INTO public.directus_collections VALUES ('faq_tela_sobre', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');
INSERT INTO public.directus_collections VALUES ('questionnaires', NULL, NULL, NULL, false, false, NULL, NULL, true, NULL, NULL, 'sort', 'all');


--
-- Data for Name: directus_fields; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_fields VALUES (6, 'clientes_audios_eventos', 'event_id', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (97, 'tags', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (129, 'questionnaires', 'active', NULL, 'boolean', NULL, 'boolean', NULL, false, false, 4, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (134, 'tags', 'show_on_filters', NULL, 'boolean', NULL, 'boolean', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (99, 'tags', 'created_at', 'date-created', NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (39, 'clientes', 'login_status', NULL, 'select-dropdown', '{"choices":[{"text":"Liberado","value":"OK"},{"text":"Bloqueado 24h","value":"NOK"},{"text":"Bloqueado (Manualmente)","value":"BLOCK"}]}', 'raw', NULL, false, false, 15, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (7, 'configuracoes', 'id', NULL, 'input', NULL, 'raw', NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (136, 'faq_tela_sobre_categoria', 'is_test', NULL, 'boolean', NULL, 'boolean', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (18, 'admin_big_numbers', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, true, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (13, 'admin_big_numbers', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"published","value":"published"},{"text":"draft","value":"draft"},{"text":"deleted","value":"deleted"}]}', NULL, NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (155, 'clientes_quiz_session', 'deleted', NULL, 'boolean', NULL, 'boolean', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (98, 'tags', 'title', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (12, 'admin_big_numbers', 'id', NULL, 'input', NULL, 'raw', NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (23, 'admin_big_numbers', 'background_class', NULL, NULL, NULL, NULL, NULL, false, false, 9, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (8, 'configuracoes', 'termos_de_uso', NULL, 'input-rich-text-html', NULL, 'formatted-value', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (17, 'admin_big_numbers', 'label', NULL, 'input', NULL, 'raw', NULL, false, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (41, 'clientes', 'senha_sha256', NULL, NULL, NULL, NULL, NULL, true, true, 18, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (22, 'admin_big_numbers', 'comment', NULL, 'input', NULL, 'raw', NULL, false, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (102, 'tags', 'is_topic', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (26, 'clientes', 'status', NULL, 'select-dropdown', '{"choices":[{"value":"active","text":"ativo"},{"text":"banido","value":"banned"},{"text":"remoção agendada","value":"deleted_scheduled"}],"icon":"assignment_ind"}', NULL, NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (9, 'configuracoes', 'privacidade', NULL, 'input-rich-text-html', NULL, 'formatted-value', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (58, 'admin_clientes_segments', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"Published","value":"published"},{"text":"Draft","value":"draft"},{"text":"Deleted","value":"deleted"}]}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (15, 'admin_big_numbers', 'text_class', NULL, 'input', NULL, 'raw', NULL, false, false, 8, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (25, 'clientes', 'id', NULL, 'input', NULL, 'raw', NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (10, 'configuracoes', 'texto_faq_index', NULL, 'input-rich-text-html', NULL, 'formatted-value', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (11, 'configuracoes', 'texto_faq_contato', NULL, 'input-rich-text-html', NULL, 'formatted-value', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (28, 'clientes', 'cpf', NULL, 'input', NULL, 'raw', NULL, false, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (38, 'clientes', 'genero', NULL, 'select-dropdown', '{"choices":[{"text":"Masculino","value":"Masculino"},{"text":"Feminino","value":"Feminino"},{"text":"Não informado","value":"NaoInformado"}]}', 'raw', NULL, false, false, 13, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (16, 'admin_big_numbers', 'sql', NULL, 'input-code', '{"language":"sql","lineNumber":true}', 'formatted-value', NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (24, 'admin_big_numbers', 'sort', NULL, 'input', NULL, 'raw', NULL, false, true, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (101, 'tags', 'topic_order', NULL, 'input', '{"stepInterval":1,"minValue":0}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (42, 'clientes', 'qtde_login_senha_normal', NULL, 'input', NULL, 'raw', NULL, true, false, 19, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (57, 'admin_clientes_segments', 'id', NULL, 'input', NULL, 'raw', NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (64, 'admin_clientes_segments', 'last_count', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (65, 'admin_clientes_segments', 'last_run_at', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (40, 'clientes', 'login_status_last_blocked_at', NULL, 'datetime', NULL, 'datetime', NULL, false, false, 16, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (33, 'clientes', 'cep_estado', NULL, 'input', '{"slug":true}', 'raw', NULL, false, false, 9, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (21, 'admin_big_numbers', 'created_on', 'date-created', 'datetime', NULL, 'raw', NULL, false, true, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (69, 'admin_clientes_segments', 'sort', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (126, 'questionnaires', 'created_on', NULL, NULL, NULL, NULL, NULL, false, true, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (216, 'noticias', 'id', NULL, NULL, NULL, NULL, NULL, true, true, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (124, 'questionnaires', 'id', NULL, NULL, NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (27, 'clientes', 'created_on', 'date-created', 'datetime', NULL, 'datetime', NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (34, 'clientes', 'deletion_started_at', NULL, 'datetime', NULL, 'datetime', NULL, true, true, 22, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (31, 'clientes', 'cep', NULL, 'input', NULL, 'raw', NULL, false, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (32, 'clientes', 'cep_cidade', NULL, 'input', NULL, 'raw', NULL, false, false, 8, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (30, 'clientes', 'email', NULL, 'input', '{"trim":true}', 'formatted-value', '{}', false, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (37, 'clientes', 'nome_completo', NULL, 'input', NULL, 'raw', NULL, false, false, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (43, 'clientes', 'apelido', NULL, 'input', NULL, 'raw', NULL, false, false, 11, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (109, 'rss_feeds', 'url', NULL, 'input', NULL, 'raw', NULL, false, false, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (63, 'admin_clientes_segments', 'label', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (131, 'questionnaires', 'condition', NULL, 'input', NULL, 'raw', NULL, false, false, 9, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (121, 'quiz_config', 'relevance', NULL, NULL, NULL, NULL, NULL, false, false, 11, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (108, 'rss_feeds', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, true, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (76, 'faq_tela_sobre', 'id', NULL, NULL, NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (141, 'clientes_quiz_session', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (122, 'quiz_config', 'button_label', NULL, NULL, NULL, NULL, NULL, false, false, 12, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (169, 'delete_log', 'data', NULL, 'input-code', NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (83, 'faq_tela_sobre', 'created_on', 'date-created', NULL, NULL, NULL, NULL, false, true, 8, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (86, 'faq_tela_sobre', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, true, 9, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (107, 'rss_feeds', 'created_on', 'date-created', NULL, NULL, NULL, NULL, false, true, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (175, 'login_logs', 'created_at', NULL, 'datetime', NULL, 'datetime', '{"relative":true}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (137, 'clientes_quiz_session', 'id', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (87, 'faq_tela_sobre_categoria', 'id', NULL, NULL, NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (133, 'quiz_config', 'questionnaire_id', NULL, 'select-dropdown-m2o', '{"template":"{{label}} ({{id}})"}', 'related-values', '{"template":"{{label}}"}', false, false, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (77, 'faq_tela_sobre', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"Rascunho","value":"draft"},{"text":"Publicado","value":"published"}]}', 'raw', NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (89, 'faq_tela_sobre_categoria', 'sort', NULL, NULL, NULL, NULL, NULL, true, true, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (78, 'faq_tela_sobre', 'sort', NULL, 'input', NULL, 'raw', NULL, false, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (92, 'faq_tela_sobre_categoria', 'created_on', 'date-created', NULL, NULL, NULL, NULL, false, true, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (94, 'faq_tela_sobre_categoria', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (138, 'clientes_app_activity', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (139, 'clientes_app_notifications', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (140, 'clientes_preferences', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (142, 'clientes_reset_password', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (110, 'quiz_config', 'id', NULL, NULL, NULL, NULL, NULL, false, false, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (143, 'login_erros', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (112, 'quiz_config', 'sort', NULL, NULL, NULL, NULL, NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (114, 'quiz_config', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, true, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (88, 'faq_tela_sobre_categoria', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"Publicado","value":"published"},{"text":"Rascunho","value":"draft"}]}', NULL, NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (96, 'tags', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"Produção","value":"prod"},{"text":"Teste","value":"dev"}]}', NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (111, 'quiz_config', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"published","value":"published"},{"text":"Draft","value":"draft"},{"text":"Deleted","value":"deleted"}]}', NULL, NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (105, 'rss_feeds', 'status', NULL, 'select-dropdown', '{"choices":[{"text":"active","value":"active"},{"text":"paused","value":"paused"},{"text":"draft","value":"draft"}]}', NULL, NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (219, 'noticias', 'display_created_time', NULL, NULL, NULL, NULL, NULL, false, false, 5, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (104, 'rss_feeds', 'id', NULL, 'input', NULL, 'raw', NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (217, 'noticias', 'title', NULL, 'input', NULL, 'raw', NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (173, 'login_logs', 'remote_ip', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (174, 'login_logs', 'app_version', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (167, 'delete_log', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (177, 'preferences', 'name', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (170, 'delete_log', 'email_md5', NULL, NULL, NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (171, 'delete_log', 'created_at', NULL, NULL, NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (178, 'preferences', 'label', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (172, 'login_logs', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (180, 'preferences', 'initial_value', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (176, 'preferences', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (181, 'preferences', 'sort', NULL, NULL, NULL, NULL, NULL, false, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (117, 'quiz_config', 'question', NULL, 'input', NULL, 'raw', NULL, false, false, 9, 'full', NULL, NULL, 'este valor não aparece quando o tipo da pergunta for "grupo de sim/não"');
INSERT INTO public.directus_fields VALUES (206, 'tag_indexing_config', 'regexp', NULL, 'boolean', '{"label":"É Regexp?"}', 'boolean', '{"labelOn":"Sim, é regexp","labelOff":"Não, é texto comum"}', false, false, 5, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (135, 'faq_tela_sobre', 'exibir_titulo_inline', NULL, 'boolean', NULL, 'boolean', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (179, 'preferences', 'active', NULL, 'boolean', NULL, 'boolean', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (85, 'faq_tela_sobre', 'title', NULL, 'input-rich-text-html', NULL, NULL, NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (81, 'faq_tela_sobre', 'content_html', NULL, 'input-rich-text-html', NULL, NULL, NULL, false, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (95, 'faq_tela_sobre_categoria', 'title', NULL, 'input-rich-text-html', NULL, 'raw', NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (207, 'rss_feeds', 'autocapitalize', NULL, 'boolean', NULL, 'boolean', NULL, false, false, 7, 'full', NULL, NULL, 'Se ativado, o título da noticia será convertido para Auto Capital');
INSERT INTO public.directus_fields VALUES (224, 'noticias', 'indexed', NULL, 'boolean', NULL, 'boolean', NULL, false, false, 8, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (255, 'questionnaires', 'is_test', 'boolean', 'boolean', NULL, 'boolean', '{"labelOn":"é para testes","labelOff":"produção"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (288, 'clientes', 'account_verified', 'boolean', 'boolean', NULL, 'boolean', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (144, 'login_logs', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (208, 'rss_feeds', 'last_error_message', NULL, NULL, NULL, NULL, NULL, false, false, 8, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (145, 'media_upload', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (146, 'notification_log', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (220, 'noticias', 'created_at', 'date-created', NULL, NULL, NULL, NULL, false, false, 6, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (225, 'noticias', 'indexed_at', NULL, NULL, NULL, NULL, NULL, false, false, 9, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (204, 'tag_indexing_config', 'err_msg_label', 'alias,no-data', 'presentation-notice', '{"text":"error_msg fica preenchido sempre que ocorreu um erro ao verificar as regexps. Se isso acontecer, é necessário corrigir o erro e limpar o valor do campo \"verified\" para 0, para que o sistema faça a verificação na próxima vez","color":"warning"}', NULL, NULL, false, false, 8, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (29, 'clientes', 'dt_nasc', NULL, 'datetime', '{"use24":false}', 'datetime', '{"format":"short"}', false, false, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (291, 'questionnaires', 'code', NULL, 'select-dropdown', '{"font":"monospace","choices":[{"text":"não configurado","value":"unset"},{"value":"verify_account","text":"verificação de conta"}]}', 'labels', '{"choices":[{"text":"Verificação de conta","value":"verify_account"},{"text":"Não configurado","value":"unset"}]}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (298, 'quiz_config', 'yes_no_fields', 'alias,no-data', 'presentation-notice', '{"text":"Campos abaixo são para configuração da interface do \"Sim\"/\"Não\""}', NULL, NULL, false, false, 13, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (150, 'clientes_active_sessions', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (209, 'rss_feeds', 'next_tick', NULL, NULL, NULL, 'datetime', '{"relative":true}', true, true, 9, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (236, 'noticias_aberturas', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (237, 'noticias_aberturas', 'track_id', NULL, NULL, NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (151, 'clientes_quiz_session', 'questionnaire_id', NULL, 'select-dropdown-m2o', '{"template":"{{name}} ({{id}})"}', 'related-values', '{"template":"{{name}} ({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (261, 'tickets_responses', 'id', NULL, 'input', NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (268, 'tickets_responses', 'cliente_attachments', 'json', 'list', '{"template":"{{ id }}"}', 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (249, 'rss_feeds_tags', 'tags_id', NULL, NULL, NULL, NULL, NULL, false, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (290, 'clientes', 'verified_account_info', 'json', NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (269, 'tickets_responses', 'created_on', 'date-created', NULL, NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (279, 'quiz_config', 'intro', NULL, 'list', '{"template":"{{ text }}","addLabel":"Novo texto","fields":[{"field":"text","name":"Texto","type":"string","meta":{"name":"Texto","field":"text","width":"full","type":"string","options":{"clear":true,"trim":true},"interface":"text-input"}}]}', 'raw', NULL, false, false, 8, 'full', NULL, NULL, 'Apresentar textos antes da pergunta.');
INSERT INTO public.directus_fields VALUES (258, 'questionnaires', 'due_days', NULL, 'slider', '{"minValue":1,"maxValue":30,"stepInterval":1,"alwaysShowValue":true}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (211, 'rss_feeds', 'fonte', NULL, 'input', NULL, 'raw', NULL, false, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (232, 'noticias', 'logs', NULL, 'input-code', '{"language":"plaintext"}', 'raw', NULL, false, false, 15, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (229, 'noticias', 'info', NULL, 'input-code', '{"language":"JSON"}', 'raw', NULL, false, false, 14, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (36, 'clientes', 'perform_delete_at', NULL, 'datetime', NULL, 'datetime', NULL, false, false, 21, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (226, 'noticias', 'rss_feed_id', NULL, 'select-dropdown-m2o', '{"template":"{{url}}({{id}})"}', 'related-values', '{"template":"{{url}}({{id}})"}', false, false, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (280, 'clientes_quiz_session', 'ticket_id', NULL, 'select-dropdown-m2o', '{"template":"{{id}}"}', 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (239, 'noticias_aberturas', 'noticias_id', NULL, 'select-dropdown-m2o', NULL, 'related-values', '{"template":"{{hyperlink}}"}', true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (230, 'noticias', 'fonte', NULL, 'input', NULL, 'raw', NULL, false, false, 13, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (227, 'noticias', 'author', NULL, 'input', NULL, 'raw', NULL, false, false, 12, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (278, 'quiz_config', 'code', NULL, 'input', '{"clear":true}', 'raw', NULL, false, false, 6, 'full', NULL, NULL, 'usado para identificar a resposta dentro deste questionário');
INSERT INTO public.directus_fields VALUES (299, 'tickets', 'content', NULL, 'input-code', NULL, 'raw', NULL, true, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (273, 'tickets', 'content_hash256', NULL, 'input', NULL, 'raw', NULL, true, false, 8, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (274, 'tickets', 'questionnaire_id', NULL, 'select-dropdown-m2o', '{"template":"{{id}} - {{label}}"}', 'related-values', '{"template":"{{id}} - {{label}}"}', true, false, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (158, 'clientes_preferences', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (218, 'noticias', 'description', NULL, 'input-multiline', '{"trim":true}', 'raw', NULL, false, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (160, 'clientes_preferences', 'created_at', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (161, 'clientes_preferences', 'updated_at', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (162, 'clientes_preferences', 'preference_id', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (164, 'clientes_app_activity', 'last_tm_activity', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (163, 'clientes_app_activity', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (165, 'clientes_app_activity', 'last_activity', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (166, 'clientes_app_notifications', 'id', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (265, 'tickets_responses', 'reply_content', NULL, 'input-multiline', NULL, 'raw', NULL, true, false, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (182, 'tag_indexing_config', 'id', NULL, NULL, NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (184, 'tag_indexing_config', 'created_on', 'date-created', NULL, NULL, NULL, NULL, true, true, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (246, 'rss_feeds', 'add_tags', 'm2m', 'list-m2m', NULL, 'related-values', '{"template":"{{tags_id.title}}"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (183, 'tag_indexing_config', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, false, 4, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (185, 'tag_indexing_config', 'status', NULL, 'select-dropdown', '{"allowOther":true,"choices":[{"text":"prod","value":"prod"}]}', NULL, NULL, true, true, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (263, 'tickets_responses', 'user_id', '', 'select-dropdown-m2o', '{"selectMode":"dropdown","template":"{{avatar.$thumbnail}} {{first_name}} {{last_name}}"}', 'related-values', NULL, true, true, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (202, 'tag_indexing_config', 'error_msg', NULL, NULL, NULL, NULL, NULL, false, false, 9, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (238, 'noticias_aberturas', 'created_at', NULL, NULL, NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (187, 'tag_indexing_config', 'tag_id', NULL, NULL, NULL, NULL, NULL, false, false, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (188, 'tag_indexing_config', 'description', NULL, NULL, NULL, NULL, NULL, false, false, 11, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (283, 'tickets', 'protocol', NULL, NULL, NULL, NULL, NULL, true, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (128, 'questionnaires', 'modified_on', 'date-updated', NULL, NULL, NULL, NULL, false, true, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (189, 'tag_indexing_config', 'page_title_match', NULL, NULL, NULL, NULL, NULL, false, false, 13, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (247, 'rss_feeds_tags', 'id', NULL, NULL, NULL, NULL, NULL, false, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (248, 'rss_feeds_tags', 'rss_feeds_id', NULL, NULL, NULL, NULL, NULL, false, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (213, 'noticias2tags', 'noticias_id', NULL, 'select-dropdown-m2o', '{"template":"{{hyperlink}} - {{description}}"}', 'related-values', '{"template":"{{hyperlink}} - {{description}} "}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (266, 'tickets_responses', 'cliente_reply', NULL, 'input-multiline', NULL, 'raw', NULL, true, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (235, 'noticias', 'has_topic_tags', NULL, 'boolean', NULL, NULL, NULL, true, true, 18, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (287, 'clientes_quiz_session', 'can_delete', 'boolean', 'boolean', NULL, 'boolean', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (293, 'quiz_config', 'yesno_no_label', NULL, NULL, NULL, NULL, NULL, false, false, 16, 'half', NULL, NULL, 'Quando o tipo for "Sim/Não", qual o label para "Não"');
INSERT INTO public.directus_fields VALUES (190, 'tag_indexing_config', 'page_title_not_match', NULL, NULL, NULL, NULL, NULL, false, false, 14, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (191, 'tag_indexing_config', 'html_article_match', NULL, NULL, NULL, NULL, NULL, false, false, 15, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (192, 'tag_indexing_config', 'html_article_not_match', NULL, NULL, NULL, NULL, NULL, false, false, 16, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (193, 'tag_indexing_config', 'page_description_match', NULL, NULL, NULL, NULL, NULL, false, false, 17, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (194, 'tag_indexing_config', 'page_description_not_match', NULL, NULL, NULL, NULL, NULL, false, false, 18, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (195, 'tag_indexing_config', 'url_match', NULL, NULL, NULL, NULL, NULL, false, false, 19, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (196, 'tag_indexing_config', 'url_not_match', NULL, NULL, NULL, NULL, NULL, false, false, 20, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (197, 'tag_indexing_config', 'rss_feed_tags_match', NULL, NULL, NULL, NULL, NULL, false, false, 21, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (198, 'tag_indexing_config', 'rss_feed_tags_not_match', NULL, NULL, NULL, NULL, NULL, false, false, 22, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (199, 'tag_indexing_config', 'rss_feed_content_match', NULL, NULL, NULL, NULL, NULL, false, false, 23, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (200, 'tag_indexing_config', 'rss_feed_content_not_match', NULL, NULL, NULL, NULL, NULL, false, false, 24, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (203, 'tag_indexing_config', 'verified_at', NULL, NULL, NULL, NULL, NULL, false, false, 7, 'half', NULL, NULL, 'horário que foi feita a validação da regexps');
INSERT INTO public.directus_fields VALUES (256, 'tickets', 'id', NULL, 'input', NULL, NULL, NULL, true, true, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (159, 'clientes_preferences', 'value', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (212, 'noticias2tags', 'id', NULL, NULL, NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (286, 'tickets_responses', 'cliente_reply_created_at', NULL, NULL, NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (214, 'noticias2tags', 'tag_id', NULL, 'select-dropdown-m2o', '{"template":"{{status}}"}', 'related-values', '{"template":"{{title}}"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (157, 'clientes_quiz_session', 'deleted_at', NULL, 'datetime', NULL, 'datetime', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (35, 'clientes', 'deleted_scheduled_meta', NULL, 'input-code', '{"language":"JSON"}', 'raw', NULL, true, false, 20, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (205, 'tag_indexing_config', 'campos_description', 'alias,no-data', 'presentation-notice', '{"color":"info","text":"Abaixo os campos que podem ou não serem preenchidos para que o match acontecer. Se Regexp estiver marcado, os campos serão considerados regexp, caso contrário, será considerado o valor comum."}', NULL, NULL, false, false, 12, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (277, 'questionnaires', 'sort', NULL, 'input', NULL, 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (186, 'tag_indexing_config', 'verified', NULL, 'slider', '{"minValue":0,"maxValue":1,"stepInterval":1}', 'raw', NULL, false, false, 6, 'half', NULL, NULL, 'se as regexps estão verificadas');
INSERT INTO public.directus_fields VALUES (289, 'clientes', 'verified_account_at', NULL, NULL, NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (234, 'noticias', 'tags_index', NULL, 'input', NULL, 'raw', NULL, true, true, 17, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (292, 'quiz_config', 'yesno_yes_label', NULL, NULL, NULL, NULL, NULL, false, false, 14, 'half', NULL, NULL, 'Quando o tipo for "Sim/Não", qual o label para "SIM"');
INSERT INTO public.directus_fields VALUES (66, 'admin_clientes_segments', 'cond', NULL, 'input-code', '{"language":"JSON"}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (296, 'quiz_config', 'yesno_no_value', NULL, NULL, NULL, NULL, NULL, false, false, 17, 'half', NULL, NULL, 'Quando o tipo for "Sim/Não", qual o valor para "Não"');
INSERT INTO public.directus_fields VALUES (297, 'quiz_config', 'yesno_yes_value', NULL, NULL, NULL, NULL, NULL, false, false, 15, 'half', NULL, NULL, 'Quando o tipo for "Sim/Não", qual o valor para "Sim"');
INSERT INTO public.directus_fields VALUES (67, 'admin_clientes_segments', 'attr', NULL, 'input-code', '{"language":"JSON"}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (154, 'clientes_quiz_session', 'stash', NULL, 'input-code', '{"language":"JSON"}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (156, 'clientes_quiz_session', 'responses', NULL, 'input-code', '{"language":"JSON"}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (284, 'tickets_responses', 'type', NULL, 'input', NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (132, 'questionnaires', 'end_screen', NULL, 'input', NULL, 'raw', NULL, false, false, 5, 'half', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (253, 'questionnaires', 'label', NULL, 'input', NULL, 'raw', NULL, false, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (254, 'questionnaires', 'short_text', NULL, 'input', NULL, 'raw', NULL, false, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (222, 'noticias', 'hyperlink', NULL, 'input', NULL, 'raw', NULL, false, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (233, 'noticias', 'image_hyperlink', NULL, 'input', NULL, 'raw', NULL, false, false, 16, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (252, 'questionnaires', 'icon_href', NULL, 'select-dropdown', '{"allowOther":true,"choices":[{"text":"default.svg","value":"default.svg"},{"text":"pencil.svg","value":"pencil.svg"},{"text":"lookup.svg","value":"lookup.svg"},{"text":"forward.svg","value":"forward.svg"},{"text":"bin.svg","value":"bin.svg"},{"text":"verify.svg","value":"verify.svg"}]}', NULL, '{}', false, false, 11, 'full', NULL, NULL, 'OBS: Precisa ser um SVG. Se começar com "https" poderá ser usado um link externo, caso negativo, será buscado na pasta /src/public/q-icon/ (configurado em QUESTIONNAIRE_ICON_BASE_URL)');
INSERT INTO public.directus_fields VALUES (60, 'admin_clientes_segments', 'created_on', 'date-created', 'datetime', NULL, 'datetime', NULL, false, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (61, 'admin_clientes_segments', 'modified_on', 'date-updated', 'datetime', NULL, 'datetime', NULL, false, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (152, 'clientes_quiz_session', 'finished_at', NULL, 'datetime', NULL, 'datetime', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (153, 'clientes_quiz_session', 'created_at', 'date-created', 'datetime', NULL, 'datetime', NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (210, 'rss_feeds', 'last_run', NULL, 'datetime', NULL, 'datetime', '{"relative":true}', true, false, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (46, 'clientes', 'upload_status', NULL, 'select-dropdown', '{"choices":[{"text":"liberado","value":"ok"},{"value":"block","text":"suspenso"}]}', NULL, NULL, false, false, 17, 'full', NULL, NULL, 'se liberado, pode fazer envio de arquivos via quiz.');
INSERT INTO public.directus_fields VALUES (231, 'noticias', 'published', NULL, 'select-dropdown', '{"choices":[{"text":"Publicada","value":"published"},{"text":"Escondido","value":"hidden"}]}', 'raw', '{}', false, false, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (240, 'noticias_aberturas', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}}({{id}})"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (267, 'tickets_responses', 'ticket_id', NULL, 'select-dropdown-m2o', '{"template":"{{id}} {{status}}"}', 'related-values', '{"template":"{{id}} {{status}}"}', true, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (276, 'faq_tela_sobre', 'fts_categoria_id', NULL, 'select-dropdown-m2o', '{"template":"{{title}}"}', 'related-values', '{"template":"{{title}}"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (120, 'quiz_config', 'yesnogroup', NULL, 'list', '{"choices":[{}],"template":"{{ question }}","addLabel":"Adicionar novo item","fields":[{"field":"question","name":"Questão","type":"string","meta":{"name":"Questão","field":"question","width":"full","type":"string","note":"Qual pergunta será feita.","options":{"trim":true},"interface":"text-input"}},{"field":"power2answer","name":"número power of 2","type":"string","meta":{"name":"número power of 2","field":"power2answer","width":"half","type":"string","note":"quando respondido sim, a resposta terá esse número adicionado.","options":{"choices":[{"text":"2","value":"2"},{"text":"4","value":"4"},{"text":"8","value":"8"},{"text":"16","value":"16"},{"text":"32","value":"32"},{"text":"64","value":"64"},{"text":"128","value":"128"},{"text":"256","value":"256"},{"text":"512","value":"512"},{"text":"1024","value":"1024"},{"text":"2048","value":"2048"},{"text":"4096","value":"4096"},{"text":"8192","value":"8192"},{"text":"16384","value":"16384"}]},"interface":"dropdown"}},{"field":"referencia","name":"referencia","type":"string","meta":{"name":"referencia","field":"referencia","width":"half","type":"string","note":"Referencia para esta pergunta nas respostas.","options":{"trim":true},"interface":"text-input"}}]}', 'formatted-json-value', '{"format":"{{ question }}"}', false, false, 10, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (272, 'tickets', 'updated_at', '', 'datetime', NULL, 'datetime', NULL, true, false, 9, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (281, 'tickets', 'cliente_pdf_media_upload_id', NULL, 'select-dropdown-m2o', '{"template":"{{file_info}}- {{id}}"}', 'raw', NULL, true, false, 11, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (282, 'tickets', 'user_pdf_media_upload_id', NULL, 'select-dropdown-m2o', '{"template":"{{file_info}} - {{id}}"}', 'raw', NULL, true, false, 12, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (300, 'quiz_config', 'options', 'json', 'list', '{"fields":[{"field":"value","name":"value","type":"string","meta":{"field":"value","width":"half","type":"string","note":"valor a ser salvo na resposta","options":{"trim":true},"interface":"input"}},{"field":"label","name":"label","type":"string","meta":{"field":"label","width":"half","type":"string","note":"Valor a ser exibido para usuário selecionar","interface":"input"}}],"template":"{{label}}","addLabel":"Nova opção"}', 'raw', NULL, false, false, NULL, 'full', NULL, NULL, 'valores de opções (tipo múltipla escolha e seleção de opção)');
INSERT INTO public.directus_fields VALUES (115, 'quiz_config', 'type', NULL, 'select-dropdown', '{"choices":[{"text":"Texto livre","value":"text"},{"text":"Botão duplo (Sim/Não)","value":"yesno"},{"text":"Lista de opção (selecionar uma)","value":"onlychoice"},{"text":"Lista de opção (selecionar várias)","value":"multiplechoices"},{"text":"Apenas Exibir texto","value":"displaytext"},{"text":"Botão de finalizar conversa","value":"botao_fim"},{"text":"Várias perguntas de Sim/Não","value":"yesnogroup"},{"text":"Anexar Foto","value":"photo_attachment"},{"text":"Criar ticket","value":"create_ticket"}]}', 'raw', NULL, false, false, 7, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (312, 'blockchain_records', 'ticket_id', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (215, 'noticias', 'tags', 'm2m', 'list-m2m', '{"template":"{{tag_id.id}} {{tag_id.title}}"}', 'related-values', '{"template":"{{tag_id.title}}({{tag_id.id}})"}', false, false, 11, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (307, 'blockchain_records', 'created_at', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (301, 'questionnaires', 'questions', 'o2m', 'list-o2m', '{"template":"{{code}} - {{question}} - {{type}} - {{sort}} - {{relevance}}","enableCreate":true,"enableSelect":false}', NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (270, 'tickets', 'created_on', '', 'datetime', NULL, 'datetime', NULL, true, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (257, 'tickets', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}} ({{id}})"}', 'related-values', '{"template":"{{nome_completo}}({{id}}"}', true, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (259, 'tickets', 'due_date', NULL, NULL, NULL, 'datetime', NULL, true, false, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (260, 'tickets', 'status', NULL, 'select-dropdown', '{"choices":[{"value":"pending","text":"Pendente"},{"value":"wait-additional-info","text":"Aguardando informações adicionais"},{"text":"Finalizado","value":"done"}]}', 'labels', '{"choices":[{"value":"pending","foreground":"#FAFAFA","background":"#F23A3A","text":"Pendente"},{"text":"Finalizado","value":"done","foreground":"#FFFFFF","background":"#11A257"},{"value":"wait-additional-info","foreground":"#FFFFFF","background":"#EDE02C","text":"Aguardando info. adicional"}]}', true, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (302, 'blockchain_records', 'id', NULL, 'input', NULL, NULL, NULL, true, true, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (304, 'blockchain_records', 'filename', NULL, 'input', NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (305, 'blockchain_records', 'digest', NULL, 'input', NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (306, 'blockchain_records', 'media_upload_id', NULL, 'select-dropdown-m2o', NULL, NULL, NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (308, 'blockchain_records', 'dcrtime_timestamp', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (309, 'blockchain_records', 'decred_merkle_root', NULL, 'input', NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (310, 'blockchain_records', 'decred_capture_txid', NULL, 'input', NULL, 'raw', NULL, true, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (311, 'blockchain_records', 'created_at_real', NULL, NULL, NULL, NULL, NULL, false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (264, 'tickets_responses', 'cliente_id', NULL, 'select-dropdown-m2o', '{"template":"{{nome_completo}}"}', 'related-values', '{"template":"{{nome_completo}}"}', true, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (313, 'configuracoes', 'email_config', 'json', 'list', '{"fields":[{"field":"template","name":"template","type":"string","meta":{"field":"template","width":"half","type":"string","options":{"choices":[{"text":"Criação de conta","value":"signup"},{"text":"Solicitação criada","value":"ticket_created"},{"text":"Solicitação reaberta","value":"ticket_reopen"},{"value":"ticket_response_reply","text":"Resposta recebida"},{"value":"ticket_close","text":"Solicitação finalizada"},{"text":"Mudança de prazo","value":"ticket_change_due"},{"value":"ticket_verify_yes","text":"Verificação de conta (aprovada)"},{"text":"Verificação de conta (reprovada)","value":"ticket_verify_no"},{"value":"ticket_request_additional_info","text":"Requisição de nova informação"}]},"interface":"select-dropdown"}},{"field":"subject","name":"subject","type":"string","meta":{"field":"subject","width":"full","type":"string","note":"Assunto do e-mail","interface":"input"}},{"field":"body","name":"body","type":"text","meta":{"field":"body","width":"full","type":"text","note":"Corpo do e-mail","interface":"input-rich-text-html"}}],"template":"{{ template }} {{ subject }}","addLabel":"Nova configuração"}', 'formatted-json-value', '{"format":"{{ template }} {{ subject }}"}', false, false, NULL, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (315, 'emaildb_config', 'id', NULL, NULL, NULL, NULL, NULL, false, false, 1, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (316, 'emaildb_config', 'from', NULL, NULL, NULL, NULL, NULL, false, false, 2, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (317, 'emaildb_config', 'template_resolver_class', NULL, NULL, NULL, NULL, NULL, false, false, 3, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (318, 'emaildb_config', 'template_resolver_config', NULL, NULL, NULL, NULL, NULL, false, false, 4, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (319, 'emaildb_config', 'email_transporter_class', NULL, NULL, NULL, NULL, NULL, false, false, 5, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (320, 'emaildb_config', 'email_transporter_config', NULL, NULL, NULL, NULL, NULL, false, false, 6, 'full', NULL, NULL, NULL);
INSERT INTO public.directus_fields VALUES (314, 'emaildb_config', 'delete_after', NULL, NULL, NULL, NULL, NULL, false, true, 7, 'full', NULL, NULL, NULL);


--
-- Data for Name: directus_files; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: directus_folders; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: directus_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_migrations VALUES ('20201028A', 'Remove Collection Foreign Keys', '2021-04-08 18:32:40.619268+00');
INSERT INTO public.directus_migrations VALUES ('20201029A', 'Remove System Relations', '2021-04-08 18:32:40.62149+00');
INSERT INTO public.directus_migrations VALUES ('20201029B', 'Remove System Collections', '2021-04-08 18:32:40.623264+00');
INSERT INTO public.directus_migrations VALUES ('20201029C', 'Remove System Fields', '2021-04-08 18:32:40.630333+00');
INSERT INTO public.directus_migrations VALUES ('20201105A', 'Add Cascade System Relations', '2021-04-08 18:32:40.66297+00');
INSERT INTO public.directus_migrations VALUES ('20201105B', 'Change Webhook URL Type', '2021-04-08 18:32:40.666963+00');
INSERT INTO public.directus_migrations VALUES ('20210225A', 'Add Relations Sort Field', '2021-04-08 19:48:38.151462+00');
INSERT INTO public.directus_migrations VALUES ('20210304A', 'Remove Locked Fields', '2021-04-08 19:48:38.154557+00');
INSERT INTO public.directus_migrations VALUES ('20210312A', 'Webhooks Collections Text', '2021-04-08 19:48:38.158074+00');
INSERT INTO public.directus_migrations VALUES ('20210331A', 'Add Refresh Interval', '2021-04-14 13:01:53.614663+00');
INSERT INTO public.directus_migrations VALUES ('20210415A', 'Make Filesize Nullable', '2021-04-15 20:15:03.45125+00');
INSERT INTO public.directus_migrations VALUES ('20210416A', 'Add Collections Accountability', '2021-05-11 22:05:08.09092+00');
INSERT INTO public.directus_migrations VALUES ('20210422A', 'Remove Files Interface', '2021-05-11 22:05:08.093976+00');
INSERT INTO public.directus_migrations VALUES ('20210506A', 'Rename Interfaces', '2021-05-11 22:05:08.152871+00');


--
-- Data for Name: directus_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_permissions VALUES (21, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_files', 'create', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (22, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_files', 'read', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (23, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_files', 'update', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (24, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_files', 'delete', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (25, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_folders', 'create', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (26, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_folders', 'read', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (27, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_folders', 'update', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (28, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_folders', 'delete', '{}', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_permissions VALUES (29, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_users', 'read', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (30, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'directus_roles', 'read', '{}', NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (34, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'configuracoes', 'update', NULL, NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (32, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'configuracoes', 'read', NULL, NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (31, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'configuracoes', 'create', NULL, NULL, NULL, '*', NULL);
INSERT INTO public.directus_permissions VALUES (33, '5ff90a02-df14-4d98-a012-062699e7ed3a', 'configuracoes', 'delete', NULL, NULL, NULL, '*', NULL);


--
-- Data for Name: directus_presets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_presets VALUES (3, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'directus_activity', NULL, NULL, 'tabular', '{"tabular":{"sort":"-timestamp","fields":["action","collection","timestamp","user"],"page":2}}', '{"tabular":{"widths":{"action":100,"collection":210,"timestamp":240,"user":368.750244140625}}}', NULL);
INSERT INTO public.directus_presets VALUES (11, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'rss_feeds_tags', NULL, NULL, 'tabular', '{"tabular":{"fields":["rss_feeds_id","id","tags_id"]}}', NULL, NULL);
INSERT INTO public.directus_presets VALUES (12, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'tag_indexing_config', NULL, NULL, 'tabular', NULL, '{"tabular":{"widths":{"modified_on":250.625244140625,"regexp":222.50006103515625}}}', NULL);
INSERT INTO public.directus_presets VALUES (8, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'clientes_quiz_session', NULL, NULL, 'tabular', '{"tabular":{"page":1,"fields":["cliente_id","finished_at","id","questionnaire_id","created_at"],"sort":"-id"}}', '{"tabular":{"widths":{"cliente_id":263.750244140625,"finished_at":270.43145751953125}}}', NULL);
INSERT INTO public.directus_presets VALUES (4, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'clientes', NULL, NULL, 'tabular', '{"tabular":{"page":1}}', NULL, NULL);
INSERT INTO public.directus_presets VALUES (1, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'directus_users', NULL, NULL, 'cards', '{"cards":{"sort":"email","page":1}}', '{"cards":{"icon":"account_circle","title":"{{ first_name }} {{ last_name }}","subtitle":"{{ email }}","size":4}}', NULL);
INSERT INTO public.directus_presets VALUES (2, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'directus_files', NULL, NULL, 'cards', '{"cards":{"sort":"-uploaded_on","page":1}}', '{"cards":{"icon":"insert_drive_file","title":"{{ title }}","subtitle":"{{ type }} • {{ filesize }}","size":4,"imageFit":"crop"}}', NULL);
INSERT INTO public.directus_presets VALUES (9, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'noticias', NULL, '[{"key":"hide-archived","field":"published","operator":"neq","value":"published:testing","locked":true}]', 'tabular', '{"tabular":{"page":1,"sort":"display_created_time","fields":["description","display_created_time","published","title","image_hyperlink"]}}', '{"tabular":{"widths":{"published":190.62506103515625,"title":550.1370849609375,"image_hyperlink":515.7647705078125}}}', NULL);
INSERT INTO public.directus_presets VALUES (10, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'rss_feeds', NULL, NULL, 'tabular', '{"tabular":{"fields":["autocapitalize","fonte","status","url","add_tags","last_run","next_tick"],"page":1}}', '{"tabular":{"widths":{"next_tick":312.1253662109375}}}', NULL);
INSERT INTO public.directus_presets VALUES (13, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'noticias_aberturas', NULL, NULL, 'tabular', '{"tabular":{"page":1}}', NULL, NULL);
INSERT INTO public.directus_presets VALUES (14, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'questionnaires', NULL, '[]', 'tabular', '{"tabular":{"page":1,"sort":"is_test","fields":["active","end_screen","label","short_text","is_test","sort","questions"]}}', '{"tabular":{"widths":{"label":289.2548828125,"is_test":239.058837890625,"questions":353.882568359375}}}', NULL);
INSERT INTO public.directus_presets VALUES (16, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'configuracoes', NULL, NULL, 'tabular', '{"tabular":{"page":1}}', NULL, NULL);
INSERT INTO public.directus_presets VALUES (15, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'faq_tela_sobre_categoria', NULL, NULL, 'tabular', '{"tabular":{"page":1,"sort":"sort"}}', NULL, NULL);
INSERT INTO public.directus_presets VALUES (20, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'delete_log', NULL, NULL, 'tabular', '{"tabular":{"page":1}}', NULL, NULL);
INSERT INTO public.directus_presets VALUES (22, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'tickets_responses', NULL, NULL, 'tabular', '{"tabular":{"fields":["cliente_id","cliente_reply","reply_content","ticket_id","type"]}}', '{"tabular":{"widths":{"ticket_id":328.78424072265625}}}', NULL);
INSERT INTO public.directus_presets VALUES (21, 'Quiz - Exclusão de dados', NULL, NULL, 'quiz_config', '', '[{"key":"p6m0Gu2ig7eZ1nl6Pgnaq","field":"questionnaire_id.id","operator":"eq","value":"8"}]', 'tabular', '{"tabular":{"fields":["id","intro","questionnaire_id","sort","status","type","code","relevance","question","button_label","yesno_no_label","yesno_yes_label"],"page":1,"sort":"sort"}}', '{"tabular":{"widths":{"id":71,"sort":91.23529052734375,"status":119.8431396484375,"type":129.7452392578125,"relevance":226.1568603515625,"question":613.4119873046875,"button_label":149.41162109375},"spacing":"cozy"},"cards":{"title":"{{question}}","subtitle":"{{code}}"},"calendar":{"viewInfo":{"type":"dayGridMonth","startDateStr":"2021-05-01T00:00:00-03:00"}}}', NULL);
INSERT INTO public.directus_presets VALUES (7, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'quiz_config', '', '[{"key":"p6m0Gu2ig7eZ1nl6Pgnaq","field":"questionnaire_id.id","operator":"eq","value":"8"}]', 'tabular', '{"tabular":{"fields":["id","questionnaire_id","sort","status","type","code","relevance","question","button_label","yesnogroup","modified_on"],"page":1,"sort":"-questionnaire_id"}}', '{"tabular":{"widths":{"id":71,"sort":95,"type":162.9998779296875,"relevance":143.7501220703125,"button_label":283.75048828125,"yesnogroup":490.000732421875},"spacing":"cozy"},"cards":{"title":"{{question}}","subtitle":"{{code}}"},"calendar":{"viewInfo":{"type":"dayGridMonth","startDateStr":"2021-05-01T00:00:00-03:00"}}}', NULL);
INSERT INTO public.directus_presets VALUES (19, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'tickets', NULL, NULL, 'tabular', '{"tabular":{"page":1,"sort":"cliente_id"}}', '{"tabular":{"widths":{"cliente_id":342.5882873535156}}}', NULL);
INSERT INTO public.directus_presets VALUES (17, NULL, 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, 'faq_tela_sobre', NULL, NULL, 'tabular', '{"tabular":{"page":1}}', '{"tabular":{"widths":{"content_html":331.921630859375}}}', NULL);


--
-- Data for Name: directus_relations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_relations VALUES (25, 'noticias_tags', 'tag_id', 'id', 'tags', NULL, 'id', NULL, NULL, 'noticias_id', NULL);
INSERT INTO public.directus_relations VALUES (30, 'rss_feeds_tags', 'tag_id', 'id', 'tags', NULL, 'id', NULL, NULL, 'rss_feed_id', NULL);
INSERT INTO public.directus_relations VALUES (32, 'rss_feeds_tags', 'tag_id', 'id', 'tags', NULL, 'id', NULL, NULL, 'rss_feed_id', NULL);
INSERT INTO public.directus_relations VALUES (35, 'rss_feeds_tags', 'tags_id', 'id', 'tags', NULL, 'id', NULL, NULL, 'rss_feeds_id', NULL);
INSERT INTO public.directus_relations VALUES (26, 'noticias', 'rss_feed_id', 'id', 'rss_feeds', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (8, 'clientes_active_sessions', 'cliente_id', 'id', 'clientes', 'clientes_active_sessions', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (9, 'clientes_app_activity', 'cliente_id', 'id', 'clientes', 'clientes_app_activity', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (10, 'clientes_app_notifications', 'cliente_id', 'id', 'clientes', 'clientes_app_notifications', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (11, 'clientes_preferences', 'cliente_id', 'id', 'clientes', 'clientes_preferences', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (12, 'clientes_quiz_session', 'cliente_id', 'id', 'clientes', 'clientes_quiz_session', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (13, 'clientes_reset_password', 'cliente_id', 'id', 'clientes', 'clientes_reset_password', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (14, 'login_erros', 'cliente_id', 'id', 'clientes', 'login_erros', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (15, 'login_logs', 'cliente_id', 'id', 'clientes', 'login_logs', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (16, 'media_upload', 'cliente_id', 'id', 'clientes', 'media_upload', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (17, 'notification_log', 'cliente_id', 'id', 'clientes', 'notification_log', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (21, 'clientes_quiz_session', 'questionnaire_id', 'id', 'questionnaires', 'clientes_quiz_session', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (22, 'noticias2tags', 'noticias_id', 'id', 'noticias', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (28, 'noticias_aberturas', 'cliente_id', 'id', 'clientes', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (27, 'noticias_aberturas', 'noticias_id', 'id', 'noticias', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (38, 'tickets_responses', 'ticket_id', 'id', 'tickets', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (34, 'rss_feeds_tags', 'rss_feeds_id', 'id', 'rss_feeds', 'add_tags', 'id', NULL, NULL, 'tags_id', NULL);
INSERT INTO public.directus_relations VALUES (41, 'faq_tela_sobre', 'fts_categoria_id', 'id', 'faq_tela_sobre_categoria', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (7, 'quiz_config', 'questionnaire_id', 'id', 'questionnaires', 'quiz_config', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (42, 'clientes_quiz_session', 'ticket_id', 'id', 'tickets', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (43, 'tickets', 'cliente_pdf_media_upload_id', 'id', 'media_upload', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (44, 'tickets', 'user_pdf_media_upload_id', 'id', 'media_upload', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (39, 'tickets', 'questionnaire_id', 'id', 'questionnaires', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (36, 'tickets', 'cliente_id', 'id', 'clientes', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (45, 'quiz_config', 'questionnaire_id', 'id', 'questionnaires', 'questions', 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (46, 'blockchain_records', 'media_upload_id', 'id', 'media_upload', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (37, 'tickets_responses', 'cliente_id', 'id', 'clientes', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (23, 'noticias2tags', 'tag_id', 'id', 'tags', NULL, 'id', NULL, NULL, NULL, NULL);
INSERT INTO public.directus_relations VALUES (24, 'noticias2tags', 'noticias_id', 'id', 'noticias', 'tags', 'id', NULL, NULL, 'tag_id', NULL);


--
-- Data for Name: directus_revisions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: directus_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_roles VALUES ('5ff90a02-df14-4d98-a012-062699e7ed3a', 'tests group', 'supervised_user_circle', NULL, NULL, false, NULL, NULL, false, true);
INSERT INTO public.directus_roles VALUES ('77d4e455-bd2d-46a1-9e68-05acd4d8c30f', 'Admin', 'supervised_user_circle', NULL, NULL, false, NULL, '[{"group_name":"Ticket","accordion":"start_open","collections":[{"collection":"tickets"},{"collection":"tickets_responses"}]}]', true, true);


--
-- Data for Name: directus_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_sessions VALUES ('v3cQBdX8XhDv0wROBP4x8FZ2s59ZsAIEKluuAblP34EPlul0475ub2TkkfDhh1wA', 'a406fa30-eb02-4975-bcdd-ac0f39adffc4', '2021-06-01 15:13:11.014+00', '177.45.249.92', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36');


--
-- Data for Name: directus_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.directus_settings VALUES (1, 'LGPD jus', 'https://lgpdjus-directus.sample.com/', NULL, NULL, NULL, NULL, NULL, 25, NULL, 'all', NULL, NULL);


--
-- Data for Name: directus_users; Type: TABLE DATA; Schema: public; Owner: -
--

-- email: admin@sample.com
-- password: admin@sample.com
INSERT INTO public.directus_users VALUES ('a406fa30-eb02-4975-bcdd-ac0f39adffc4', NULL, NULL, 'admin@sample.com', '$argon2i$v=19$m=4096,t=3,p=1$UeqgX9UmSDOTgts1AZOx6A$uhgyad7SgsD7veM8rvT8dyIde5512ccTY7HLK6FPWd0', NULL, NULL, NULL, NULL, NULL, 'pt-BR', 'auto', NULL, 'active', '77d4e455-bd2d-46a1-9e68-05acd4d8c30f', NULL, '2021-05-25 15:13:10.986+00', '/settings/data-model');
INSERT INTO public.directus_users VALUES ('3220d8f0-5d43-4d7c-b471-0c14155591fd', 'tests.automatic@example.com', 'tests.automatic@example.com', 'tests.automatic@example.com', '$argon2i$v=19$m=4096,t=3,p=1$dmQt0gtNPZ7/nT/0BKehEg$gtnAAjyLYttOi9O74Fjy1xRK6QnWkNPQrj3nKySMEss', NULL, NULL, NULL, NULL, NULL, 'en-US', 'auto', NULL, 'active', '5ff90a02-df14-4d98-a012-062699e7ed3a', NULL, NULL, NULL);


--
-- Data for Name: directus_webhooks; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: emaildb_config; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.emaildb_config VALUES (1, '"LGPDjus" <lgpdjus+tjsc@sample.com>', 'Shypper::TemplateResolvers::HTTP', '{"base_url":"https://lgpdjus-api.sample.com/email-templates/"}', 'Email::Sender::Transport::SMTP::Persistent', '{"sasl_username":"apikey","sasl_password":"sample","port":"587","host":"smtp.sendgrid.net"}', '25 years');


--
-- Data for Name: emaildb_queue; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: faq_tela_sobre; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: faq_tela_sobre_categoria; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: lgpdjus_config; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.lgpdjus_config VALUES (8, 'MAX_CPF_ERRORS_IN_24H', '100', '2020-05-07 14:14:19.132662+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (20, 'MINION_ADMIN_PASSWORD', random()::text, '2020-06-16 13:05:45.820877+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (34, 'NOTIFICATIONS_ENABLED', '1', '2020-11-16 01:50:31.004569+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (5, 'JWT_SECRET_KEY', random()::text || random()::text|| random()::text, '2020-04-09 11:16:09.395577+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (13, 'MAINTENANCE_SECRET', random()::text || random()::text|| random()::text, '2020-06-02 07:50:57.538425+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (11, 'AVATAR_PADRAO_URL', 'https://lgpdjus-api.sample.com/avatar/padrao.svg', '2020-05-13 22:43:57.401486+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (12, 'PUBLIC_API_URL', 'https://lgpdjus-api.sample.com/', '2020-05-18 07:40:30.159798+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (33, 'DEFAULT_NOTIFICATION_ICON', 'https://lgpdjus-api.sample.com/i', '2020-11-11 03:54:19.497+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (27, 'ADMIN_ALLOWED_ROLE_IDS', '77d4e455-bd2d-46a1-9e68-05acd4d8c30f', '2020-09-01 15:49:42.225735+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (19, 'LGPDJUS_S3_HOST', 's3.us-west-001.backblazeb2.com', '2020-06-09 16:45:10.688812+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (14, 'LGPDJUS_S3_MEDIA_BUCKET', 'bucket-name', '2020-06-09 16:23:12.530977+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (44, 'QUESTIONNAIRE_ICON_BASE_URL', 'https://lgpdjus-api.sample.com/q-icon', '2021-05-11 18:53:16.09239+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (45, 'WKHTMLTOPDF_SERVER_TYPE', 'http', '2021-05-17 19:36:12.74793+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (46, 'WKHTMLTOPDF_HTTP', 'http://172.17.0.1:64596', '2021-05-17 19:36:57.145358+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (15, 'LGPDJUS_S3_ACCESS_KEY', 's3-access-key', '2020-06-09 16:29:11.19579+00', 'infinity');
INSERT INTO public.lgpdjus_config VALUES (16, 'LGPDJUS_S3_SECRET_KEY', 's3-secret-key', '2020-06-09 16:29:24.459382+00', 'infinity');



INSERT INTO public.mojo_migrations VALUES ('minion', 23);


--
-- Data for Name: noticias; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: noticias2tags; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: noticias_aberturas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: notification_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: notification_message; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: preferences; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.preferences VALUES (6, 'NOTIFY_BY_EMAIL', 'Receber e-mails com atualizações da solicitação', true, '1', 1);


--
-- Data for Name: questionnaires; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.questionnaires VALUES (4, '2020-04-27 00:36:58+00', '2021-05-12 21:39:30.76857+00', true, '1', 'freetext=[%freetext%]', 'unset', 'document.svg', 'label 4', 'short_text 4', true, 1, 2);
INSERT INTO public.questionnaires VALUES (5, '2020-04-27 00:37:58+00', '2021-04-27 17:51:24.111+00', true, 'cliente.cpf_hash == ''NULL''', 'home', 'unset', '[% 1 %]', 'label 5', 'short_text 5', true, 1, 1);
INSERT INTO public.questionnaires VALUES (7, NULL, '2021-04-27 18:24:16.850503+00', true, 'cliente.account_verified == ''0''', 'home', 'verify_account', 'document.svg', 'verificar conta (testes)', 'verificar conta', true, 1, 3);


--
-- Data for Name: quiz_config; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.quiz_config VALUES (11, 'published', 0, '2020-07-26 19:15:58+00', 'yesno', 'yesno1', 'yesno question☺️⚠️👍👭🤗🤳', NULL, '[{"newItem":true,"text":"intro1"},{"newItem":true,"text":"HELLO[% cliente.nome_completo %]!"}]', '1', NULL, 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (12, 'published', 1, '2020-07-26 19:15:58+00', 'text', 'freetext', 'question for YES', NULL, NULL, 'yesno1 == ''Y''', NULL, 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (13, 'published', 1, '2020-07-26 19:15:58+00', 'text', 'freetext', 'question for NO', NULL, NULL, 'yesno1 == ''N''', NULL, 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (16, 'published', 5, '2020-07-26 19:15:59+00', 'displaytext', 'displaytext', 'displaytext flow', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (18, 'published', 999, '2020-07-26 19:31:05+00', 'botao_fim', 'btn_fim', 'final', NULL, NULL, '1', 'btn label fim', 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (14, 'published', 2, '2020-07-26 19:15:58+00', 'yesnogroup', 'groupq', 'a group of yes no questions will start now', '[{"newItem":true,"question":"Question A","power2answer":"1","referencia":"refa","Status":true},{"newItem":true,"question":"Question B","power2answer":"4","referencia":"reb","Status":true}]', NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (26, 'published', 60, NULL, 'photo_attachment', 'pic1', 'ponha o arquivo', NULL, NULL, '1', 'anexar', 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (27, 'published', 63, NULL, 'create_ticket', 'ticket', 'create_ticket [% ticket_protocol %]', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (28, 'published', 1, NULL, 'text', 'q1', 'verify_account question 1', NULL, NULL, '1', NULL, 7, NULL, NULL, NULL, NULL, '[]');
INSERT INTO public.quiz_config VALUES (40, 'published', 10, '2021-05-11 14:07:09.551+00', 'yesno', 'yesno_customlabel', 'customyesno question', NULL, NULL, '1', NULL, 4, 'Yup!', 'Nope!', 'no', 'yes', '[]');
INSERT INTO public.quiz_config VALUES (41, 'published', 11, NULL, 'multiplechoices', 'mc', 'multiple choices options', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[{"label":"opção a","value":"a"},{"value":"b","label":"opção b"},{"value":"c","label":"opção c"}]');
INSERT INTO public.quiz_config VALUES (42, 'published', 12, NULL, 'onlychoice', 'oc', 'only choice options', NULL, NULL, '1', NULL, 4, NULL, NULL, NULL, NULL, '[{"value":"1","label":"opção 1"},{"value":"2","label":"opção 2"},{"value":"3","label":"opção 3"}]');


--
-- Data for Name: rss_feeds; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.rss_feeds VALUES (835, 'paused', '2021-04-27 15:54:31.189+00', '2021-05-02 22:23:23.403+00', 'https://www.google.com/alerts/feeds/07823279905845821519/7065145944253252461', '2021-05-03 00:38:32+00', '2021-05-02 21:38:32+00', 'Google', false, NULL);


--
-- Data for Name: rss_feeds_tags; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tag_indexing_config; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tickets_responses; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: admin_big_numbers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_big_numbers_id_seq', 16, true);


--
-- Name: admin_clientes_segments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_clientes_segments_id_seq', 134, true);


--
-- Name: blockchain_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.blockchain_records_id_seq', 48, true);


--
-- Name: clientes_active_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_active_sessions_id_seq', 8315, true);


--
-- Name: clientes_app_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_app_activity_id_seq', 2925, true);


--
-- Name: clientes_app_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_app_notifications_id_seq', 146, true);


--
-- Name: clientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_id_seq', 41980, true);


--
-- Name: clientes_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_preferences_id_seq', 442, true);


--
-- Name: clientes_quiz_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_quiz_session_id_seq', 1730, true);


--
-- Name: clientes_reset_password_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_reset_password_id_seq', 512, true);


--
-- Name: configuracoes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configuracoes_id_seq', 1, true);


--
-- Name: delete_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.delete_log_id_seq', 175, true);


--
-- Name: directus_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_activity_id_seq', 1919, true);


--
-- Name: directus_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_fields_id_seq', 320, true);


--
-- Name: directus_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_permissions_id_seq', 34, true);


--
-- Name: directus_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_presets_id_seq', 22, true);


--
-- Name: directus_relations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_relations_id_seq', 46, true);


--
-- Name: directus_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_revisions_id_seq', 1737, true);


--
-- Name: directus_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_settings_id_seq', 1, true);


--
-- Name: directus_webhooks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.directus_webhooks_id_seq', 1, false);


--
-- Name: emaildb_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.emaildb_config_id_seq', 1, false);


--
-- Name: faq_tela_sobre_categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.faq_tela_sobre_categoria_id_seq', 154, true);


--
-- Name: faq_tela_sobre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.faq_tela_sobre_id_seq', 228, true);


--
-- Name: login_erros_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.login_erros_id_seq', 592, true);


--
-- Name: login_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.login_logs_id_seq', 8280, true);


--
-- Name: minion_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.minion_jobs_id_seq', 78041, true);


--
-- Name: minion_locks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.minion_locks_id_seq', 8442, true);


--
-- Name: minion_workers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.minion_workers_id_seq', 221, true);


--
-- Name: noticias2tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.noticias2tags_id_seq', 20300, true);


--
-- Name: noticias_aberturas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.noticias_aberturas_id_seq', 416, true);


--
-- Name: noticias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.noticias_id_seq', 16381, true);


--
-- Name: notification_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notification_log_id_seq', 42500, true);


--
-- Name: notification_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notification_message_id_seq', 984, true);


--
-- Name: lgpdjus_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.lgpdjus_config_id_seq', 46, true);


--
-- Name: preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.preferences_id_seq', 6, true);


--
-- Name: questionnaires_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.questionnaires_id_seq', 12, true);


--
-- Name: quiz_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.quiz_config_id_seq', 49, true);


--
-- Name: rss_feeds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rss_feeds_id_seq', 879, true);


--
-- Name: rss_feeds_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rss_feeds_tags_id_seq', 42, true);


--
-- Name: tag_indexing_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tag_indexing_config_id_seq', 1098, true);


--
-- Name: tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tags_id_seq', 1749, true);


--
-- Name: tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tickets_id_seq', 1199, true);


--
-- Name: tickets_responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tickets_responses_id_seq', 795, true);


--
-- Name: blockchain_records blockchain_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_records
    ADD CONSTRAINT blockchain_records_pkey PRIMARY KEY (id);


--
-- Name: directus_activity directus_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_activity
    ADD CONSTRAINT directus_activity_pkey PRIMARY KEY (id);


--
-- Name: directus_collections directus_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_collections
    ADD CONSTRAINT directus_collections_pkey PRIMARY KEY (collection);


--
-- Name: directus_fields directus_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_fields
    ADD CONSTRAINT directus_fields_pkey PRIMARY KEY (id);


--
-- Name: directus_files directus_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_pkey PRIMARY KEY (id);


--
-- Name: directus_folders directus_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_pkey PRIMARY KEY (id);


--
-- Name: directus_migrations directus_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_migrations
    ADD CONSTRAINT directus_migrations_pkey PRIMARY KEY (version);


--
-- Name: directus_permissions directus_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_permissions
    ADD CONSTRAINT directus_permissions_pkey PRIMARY KEY (id);


--
-- Name: directus_presets directus_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_pkey PRIMARY KEY (id);


--
-- Name: directus_relations directus_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_relations
    ADD CONSTRAINT directus_relations_pkey PRIMARY KEY (id);


--
-- Name: directus_revisions directus_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_pkey PRIMARY KEY (id);


--
-- Name: directus_roles directus_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_roles
    ADD CONSTRAINT directus_roles_pkey PRIMARY KEY (id);


--
-- Name: directus_sessions directus_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_pkey PRIMARY KEY (token);


--
-- Name: directus_settings directus_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_pkey PRIMARY KEY (id);


--
-- Name: directus_users directus_users_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_email_unique UNIQUE (email);


--
-- Name: directus_users directus_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_pkey PRIMARY KEY (id);


--
-- Name: directus_webhooks directus_webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_webhooks
    ADD CONSTRAINT directus_webhooks_pkey PRIMARY KEY (id);


--
-- Name: emaildb_config emaildb_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_config
    ADD CONSTRAINT emaildb_config_pkey PRIMARY KEY (id);


--
-- Name: emaildb_queue emaildb_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_queue
    ADD CONSTRAINT emaildb_queue_pkey PRIMARY KEY (id);


--
-- Name: admin_big_numbers idx_218967_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_big_numbers
    ADD CONSTRAINT idx_218967_primary PRIMARY KEY (id);


--
-- Name: admin_clientes_segments idx_218980_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_clientes_segments
    ADD CONSTRAINT idx_218980_primary PRIMARY KEY (id);


--
-- Name: clientes idx_219091_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT idx_219091_primary PRIMARY KEY (id);


--
-- Name: clientes_active_sessions idx_219118_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_active_sessions
    ADD CONSTRAINT idx_219118_primary PRIMARY KEY (id);


--
-- Name: clientes_app_activity idx_219124_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity
    ADD CONSTRAINT idx_219124_primary PRIMARY KEY (id);


--
-- Name: clientes_app_notifications idx_219130_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_notifications
    ADD CONSTRAINT idx_219130_primary PRIMARY KEY (id);


--
-- Name: clientes_preferences idx_219164_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences
    ADD CONSTRAINT idx_219164_primary PRIMARY KEY (id);


--
-- Name: clientes_quiz_session idx_219170_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT idx_219170_primary PRIMARY KEY (id);


--
-- Name: clientes_reset_password idx_219180_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reset_password
    ADD CONSTRAINT idx_219180_primary PRIMARY KEY (id);


--
-- Name: configuracoes idx_219227_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes
    ADD CONSTRAINT idx_219227_primary PRIMARY KEY (id);


--
-- Name: delete_log idx_219246_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delete_log
    ADD CONSTRAINT idx_219246_primary PRIMARY KEY (id);


--
-- Name: faq_tela_sobre idx_219266_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre
    ADD CONSTRAINT idx_219266_primary PRIMARY KEY (id);


--
-- Name: faq_tela_sobre_categoria idx_219277_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre_categoria
    ADD CONSTRAINT idx_219277_primary PRIMARY KEY (id);


--
-- Name: login_erros idx_219294_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_erros
    ADD CONSTRAINT idx_219294_primary PRIMARY KEY (id);


--
-- Name: login_logs idx_219300_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs
    ADD CONSTRAINT idx_219300_primary PRIMARY KEY (id);


--
-- Name: media_upload idx_219308_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_upload
    ADD CONSTRAINT idx_219308_primary PRIMARY KEY (id);


--
-- Name: noticias idx_219316_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias
    ADD CONSTRAINT idx_219316_primary PRIMARY KEY (id);


--
-- Name: noticias2tags idx_219331_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias2tags
    ADD CONSTRAINT idx_219331_primary PRIMARY KEY (id);


--
-- Name: noticias_aberturas idx_219337_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_aberturas
    ADD CONSTRAINT idx_219337_primary PRIMARY KEY (id);


--
-- Name: notification_log idx_219356_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT idx_219356_primary PRIMARY KEY (id);


--
-- Name: notification_message idx_219362_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_message
    ADD CONSTRAINT idx_219362_primary PRIMARY KEY (id);


--
-- Name: preferences idx_219439_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT idx_219439_primary PRIMARY KEY (id);


--
-- Name: questionnaires idx_219455_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires
    ADD CONSTRAINT idx_219455_primary PRIMARY KEY (id);


--
-- Name: quiz_config idx_219466_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config
    ADD CONSTRAINT idx_219466_primary PRIMARY KEY (id);


--
-- Name: rss_feeds idx_219478_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds
    ADD CONSTRAINT idx_219478_primary PRIMARY KEY (id);


--
-- Name: tags idx_219516_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT idx_219516_primary PRIMARY KEY (id);


--
-- Name: tag_indexing_config idx_219535_primary; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_indexing_config
    ADD CONSTRAINT idx_219535_primary PRIMARY KEY (id);


--
-- Name: minion_jobs minion_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_jobs
    ADD CONSTRAINT minion_jobs_pkey PRIMARY KEY (id);


--
-- Name: minion_locks minion_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_locks
    ADD CONSTRAINT minion_locks_pkey PRIMARY KEY (id);


--
-- Name: minion_workers minion_workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.minion_workers
    ADD CONSTRAINT minion_workers_pkey PRIMARY KEY (id);


--
-- Name: mojo_migrations mojo_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mojo_migrations
    ADD CONSTRAINT mojo_migrations_pkey PRIMARY KEY (name);


--
-- Name: noticias noticias_hyperlink_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias
    ADD CONSTRAINT noticias_hyperlink_unique UNIQUE (hyperlink);


--
-- Name: lgpdjus_config lgpdjus_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lgpdjus_config
    ADD CONSTRAINT lgpdjus_config_pkey PRIMARY KEY (id);


--
-- Name: preferences preferences_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT preferences_name_unique UNIQUE (name);


--
-- Name: rss_feeds_tags rss_feeds_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags
    ADD CONSTRAINT rss_feeds_tags_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tickets_responses tickets_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets_responses
    ADD CONSTRAINT tickets_responses_pkey PRIMARY KEY (id);


--
-- Name: idx_219091_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_219091_email ON public.clientes USING btree (email);


--
-- Name: idx_219118_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219118_cliente_id ON public.clientes_active_sessions USING btree (cliente_id);


--
-- Name: idx_219124_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_219124_cliente_id ON public.clientes_app_activity USING btree (cliente_id);


--
-- Name: idx_219124_idx_last_tm_activity_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219124_idx_last_tm_activity_desc ON public.clientes_app_activity USING btree (last_tm_activity);


--
-- Name: idx_219130_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219130_cliente_id ON public.clientes_app_notifications USING btree (cliente_id);


--
-- Name: idx_219164_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219164_cliente_id ON public.clientes_preferences USING btree (cliente_id);


--
-- Name: idx_219164_preference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219164_preference_id ON public.clientes_preferences USING btree (preference_id);


--
-- Name: idx_219170_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219170_cliente_id ON public.clientes_quiz_session USING btree (cliente_id);


--
-- Name: idx_219180_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219180_cliente_id ON public.clientes_reset_password USING btree (cliente_id);


--
-- Name: idx_219294_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219294_cliente_id ON public.login_erros USING btree (cliente_id);


--
-- Name: idx_219300_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219300_cliente_id ON public.login_logs USING btree (cliente_id);


--
-- Name: idx_219308_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219308_cliente_id ON public.media_upload USING btree (cliente_id);


--
-- Name: idx_219356_ix_notification_log_by_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219356_ix_notification_log_by_time ON public.notification_log USING btree (created_at, cliente_id);


--
-- Name: idx_219356_notification_log_ibfk_1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219356_notification_log_ibfk_1 ON public.notification_log USING btree (cliente_id);


--
-- Name: idx_219356_notification_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219356_notification_message_id ON public.notification_log USING btree (notification_message_id);


--
-- Name: idx_219535_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_219535_tag_id ON public.tag_indexing_config USING btree (tag_id);


--
-- Name: idx_config_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_config_key ON public.lgpdjus_config USING btree (name) WHERE (valid_to = 'infinity'::timestamp with time zone);


--
-- Name: ix_blockchain_cliente_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_blockchain_cliente_id ON public.blockchain_records USING btree (cliente_id);


--
-- Name: ix_blockchain_uniq_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_blockchain_uniq_digest ON public.blockchain_records USING btree (digest);


--
-- Name: minion_jobs_expires_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_expires_idx ON public.minion_jobs USING btree (expires);


--
-- Name: minion_jobs_notes_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_notes_idx ON public.minion_jobs USING gin (notes);


--
-- Name: minion_jobs_parents_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_parents_idx ON public.minion_jobs USING gin (parents);


--
-- Name: minion_jobs_state_priority_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_jobs_state_priority_id_idx ON public.minion_jobs USING btree (state, priority DESC, id);


--
-- Name: minion_locks_name_expires_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX minion_locks_name_expires_idx ON public.minion_locks USING btree (name, expires);


--
-- Name: quiz_config tgr_on_quiz_config_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tgr_on_quiz_config_after_update AFTER INSERT OR DELETE OR UPDATE ON public.quiz_config FOR EACH ROW EXECUTE PROCEDURE public.f_tgr_quiz_config_after_update();


--
-- Name: blockchain_records blockchain_records_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_records
    ADD CONSTRAINT blockchain_records_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: blockchain_records blockchain_records_media_upload_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_records
    ADD CONSTRAINT blockchain_records_media_upload_id_fkey FOREIGN KEY (media_upload_id) REFERENCES public.media_upload(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: blockchain_records blockchain_records_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_records
    ADD CONSTRAINT blockchain_records_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: clientes_active_sessions clientes_active_sessions_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_active_sessions
    ADD CONSTRAINT clientes_active_sessions_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_app_activity clientes_app_activity_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_activity
    ADD CONSTRAINT clientes_app_activity_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_app_notifications clientes_app_notifications_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_app_notifications
    ADD CONSTRAINT clientes_app_notifications_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_preferences clientes_preferences_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences
    ADD CONSTRAINT clientes_preferences_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_preferences clientes_preferences_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_preferences
    ADD CONSTRAINT clientes_preferences_ibfk_2 FOREIGN KEY (preference_id) REFERENCES public.preferences(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: clientes_quiz_session clientes_quiz_session_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT clientes_quiz_session_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_quiz_session clientes_quiz_session_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT clientes_quiz_session_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_quiz_session clientes_quiz_session_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_quiz_session
    ADD CONSTRAINT clientes_quiz_session_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: clientes_reset_password clientes_reset_password_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_reset_password
    ADD CONSTRAINT clientes_reset_password_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_fields directus_fields_group_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_fields
    ADD CONSTRAINT directus_fields_group_foreign FOREIGN KEY ("group") REFERENCES public.directus_fields(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_files directus_files_folder_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_folder_foreign FOREIGN KEY (folder) REFERENCES public.directus_folders(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_files directus_files_modified_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_modified_by_foreign FOREIGN KEY (modified_by) REFERENCES public.directus_users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_files directus_files_uploaded_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_files
    ADD CONSTRAINT directus_files_uploaded_by_foreign FOREIGN KEY (uploaded_by) REFERENCES public.directus_users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_folders directus_folders_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_folders
    ADD CONSTRAINT directus_folders_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_folders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_permissions directus_permissions_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_permissions
    ADD CONSTRAINT directus_permissions_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_presets directus_presets_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_presets directus_presets_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_presets
    ADD CONSTRAINT directus_presets_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_revisions directus_revisions_activity_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_activity_foreign FOREIGN KEY (activity) REFERENCES public.directus_activity(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_revisions directus_revisions_parent_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_revisions
    ADD CONSTRAINT directus_revisions_parent_foreign FOREIGN KEY (parent) REFERENCES public.directus_revisions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_sessions directus_sessions_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_sessions
    ADD CONSTRAINT directus_sessions_user_foreign FOREIGN KEY ("user") REFERENCES public.directus_users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: directus_settings directus_settings_project_logo_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_project_logo_foreign FOREIGN KEY (project_logo) REFERENCES public.directus_files(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_settings directus_settings_public_background_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_background_foreign FOREIGN KEY (public_background) REFERENCES public.directus_files(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_settings directus_settings_public_foreground_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_settings
    ADD CONSTRAINT directus_settings_public_foreground_foreign FOREIGN KEY (public_foreground) REFERENCES public.directus_files(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: directus_users directus_users_role_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directus_users
    ADD CONSTRAINT directus_users_role_foreign FOREIGN KEY (role) REFERENCES public.directus_roles(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: emaildb_queue emaildb_queue_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emaildb_queue
    ADD CONSTRAINT emaildb_queue_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.emaildb_config(id);


--
-- Name: faq_tela_sobre faq_tela_sobre_fts_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faq_tela_sobre
    ADD CONSTRAINT faq_tela_sobre_fts_categoria_id_fkey FOREIGN KEY (fts_categoria_id) REFERENCES public.faq_tela_sobre_categoria(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: login_erros login_erros_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_erros
    ADD CONSTRAINT login_erros_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: login_logs login_logs_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_logs
    ADD CONSTRAINT login_logs_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_upload media_upload_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_upload
    ADD CONSTRAINT media_upload_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: noticias2tags noticias2tags_noticias_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias2tags
    ADD CONSTRAINT noticias2tags_noticias_id_fkey FOREIGN KEY (noticias_id) REFERENCES public.noticias(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: noticias2tags noticias2tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias2tags
    ADD CONSTRAINT noticias2tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: noticias noticias_rss_feed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias
    ADD CONSTRAINT noticias_rss_feed_id_fkey FOREIGN KEY (rss_feed_id) REFERENCES public.rss_feeds(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notification_log notification_log_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT notification_log_ibfk_1 FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notification_log notification_log_ibfk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_log
    ADD CONSTRAINT notification_log_ibfk_2 FOREIGN KEY (notification_message_id) REFERENCES public.notification_message(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: quiz_config quiz_config_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_config
    ADD CONSTRAINT quiz_config_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: rss_feeds_tags rss_feeds_tags_rss_feeds_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags
    ADD CONSTRAINT rss_feeds_tags_rss_feeds_id_fkey FOREIGN KEY (rss_feeds_id) REFERENCES public.rss_feeds(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: rss_feeds_tags rss_feeds_tags_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rss_feeds_tags
    ADD CONSTRAINT rss_feeds_tags_tags_id_fkey FOREIGN KEY (tags_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tag_indexing_config tag_indexing_config_ibfk_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_indexing_config
    ADD CONSTRAINT tag_indexing_config_ibfk_1 FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tickets tickets_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tickets tickets_cliente_pdf_media_upload_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_cliente_pdf_media_upload_id_fkey FOREIGN KEY (cliente_pdf_media_upload_id) REFERENCES public.media_upload(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tickets tickets_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tickets_responses tickets_responses_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets_responses
    ADD CONSTRAINT tickets_responses_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tickets_responses tickets_responses_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets_responses
    ADD CONSTRAINT tickets_responses_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tickets tickets_user_pdf_media_upload_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_user_pdf_media_upload_id_fkey FOREIGN KEY (user_pdf_media_upload_id) REFERENCES public.media_upload(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

commit;
