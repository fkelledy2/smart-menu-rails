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
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: admin_jwt_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_jwt_tokens (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    token_hash character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    scopes jsonb DEFAULT '[]'::jsonb NOT NULL,
    rate_limit_per_minute integer DEFAULT 60 NOT NULL,
    rate_limit_per_hour integer DEFAULT 1000 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    last_used_at timestamp(6) without time zone,
    usage_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT check_admin_jwt_tokens_scopes_is_array CHECK ((jsonb_typeof(scopes) = 'array'::text))
);


--
-- Name: admin_jwt_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_jwt_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_jwt_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_jwt_tokens_id_seq OWNED BY public.admin_jwt_tokens.id;


--
-- Name: alcohol_order_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alcohol_order_events (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    ordritem_id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    employee_id integer,
    customer_sessionid character varying,
    alcoholic boolean DEFAULT false NOT NULL,
    abv numeric(5,2),
    alcohol_classification character varying,
    age_check_acknowledged boolean DEFAULT false NOT NULL,
    acknowledged_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: alcohol_order_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alcohol_order_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alcohol_order_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alcohol_order_events_id_seq OWNED BY public.alcohol_order_events.id;


--
-- Name: alcohol_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alcohol_policies (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    allowed_days_of_week integer[] DEFAULT '{}'::integer[],
    allowed_time_ranges jsonb DEFAULT '[]'::jsonb,
    blackout_dates date[] DEFAULT '{}'::date[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: alcohol_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alcohol_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alcohol_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alcohol_policies_id_seq OWNED BY public.alcohol_policies.id;


--
-- Name: allergyns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allergyns (
    id bigint NOT NULL,
    name character varying,
    description text,
    symbol character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    status integer DEFAULT 0,
    sequence integer,
    restaurant_id bigint
);


--
-- Name: allergyns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.allergyns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allergyns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.allergyns_id_seq OWNED BY public.allergyns.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    published_at timestamp(6) without time zone,
    announcement_type character varying,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: beverage_pipeline_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beverage_pipeline_runs (
    id bigint NOT NULL,
    menu_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    status character varying DEFAULT 'running'::character varying NOT NULL,
    current_step character varying,
    error_summary text,
    started_at timestamp(6) without time zone,
    completed_at timestamp(6) without time zone,
    items_processed integer DEFAULT 0 NOT NULL,
    needs_review_count integer DEFAULT 0 NOT NULL,
    unresolved_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: beverage_pipeline_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beverage_pipeline_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beverage_pipeline_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beverage_pipeline_runs_id_seq OWNED BY public.beverage_pipeline_runs.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id bigint NOT NULL,
    email character varying,
    message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: crawl_source_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crawl_source_rules (
    id bigint NOT NULL,
    domain character varying NOT NULL,
    rule_type integer DEFAULT 0 NOT NULL,
    reason text,
    created_by_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: crawl_source_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crawl_source_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crawl_source_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crawl_source_rules_id_seq OWNED BY public.crawl_source_rules.id;


--
-- Name: crm_email_sends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crm_email_sends (
    id bigint NOT NULL,
    crm_lead_id bigint NOT NULL,
    sender_id bigint NOT NULL,
    to_email character varying NOT NULL,
    subject character varying NOT NULL,
    body_html text,
    body_text text,
    mailer_message_id character varying,
    sent_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: crm_email_sends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_email_sends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_email_sends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crm_email_sends_id_seq OWNED BY public.crm_email_sends.id;


--
-- Name: crm_lead_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crm_lead_audits (
    id bigint NOT NULL,
    crm_lead_id bigint NOT NULL,
    actor_id bigint,
    actor_type character varying DEFAULT 'user'::character varying NOT NULL,
    event character varying NOT NULL,
    field_name character varying,
    from_value text,
    to_value text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: crm_lead_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_lead_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_lead_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crm_lead_audits_id_seq OWNED BY public.crm_lead_audits.id;


--
-- Name: crm_lead_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crm_lead_notes (
    id bigint NOT NULL,
    crm_lead_id bigint NOT NULL,
    author_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: crm_lead_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_lead_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_lead_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crm_lead_notes_id_seq OWNED BY public.crm_lead_notes.id;


--
-- Name: crm_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crm_leads (
    id bigint NOT NULL,
    restaurant_name character varying NOT NULL,
    contact_name character varying,
    contact_email character varying,
    contact_phone character varying,
    stage character varying DEFAULT 'new'::character varying NOT NULL,
    assigned_to_id bigint,
    restaurant_id bigint,
    source character varying,
    notes_count integer DEFAULT 0 NOT NULL,
    last_activity_at timestamp(6) without time zone,
    converted_at timestamp(6) without time zone,
    lost_at timestamp(6) without time zone,
    lost_reason character varying,
    lost_reason_notes text,
    calendly_event_uuid character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: crm_leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crm_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crm_leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crm_leads_id_seq OWNED BY public.crm_leads.id;


--
-- Name: demo_bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demo_bookings (
    id bigint NOT NULL,
    restaurant_name character varying NOT NULL,
    contact_name character varying NOT NULL,
    email character varying NOT NULL,
    phone character varying,
    restaurant_type character varying,
    location_count character varying,
    interests text,
    calendly_event_id character varying,
    conversion_status character varying DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: demo_bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.demo_bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: demo_bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.demo_bookings_id_seq OWNED BY public.demo_bookings.id;


--
-- Name: dining_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dining_sessions (
    id bigint NOT NULL,
    smartmenu_id bigint NOT NULL,
    tablesetting_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    session_token character varying(64) NOT NULL,
    ip_address character varying,
    user_agent_hash character varying(64),
    active boolean DEFAULT true NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    last_activity_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dining_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dining_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dining_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dining_sessions_id_seq OWNED BY public.dining_sessions.id;


--
-- Name: discovered_restaurants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discovered_restaurants (
    id bigint NOT NULL,
    city_name character varying NOT NULL,
    city_place_id character varying,
    google_place_id character varying NOT NULL,
    name character varying NOT NULL,
    website_url character varying,
    status integer DEFAULT 0 NOT NULL,
    confidence_score numeric(5,4),
    discovered_at timestamp(6) without time zone,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    restaurant_id bigint,
    establishment_types character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    address1 character varying,
    address2 character varying,
    city character varying,
    state character varying,
    postcode character varying,
    country_code character varying,
    currency character varying,
    preferred_phone character varying,
    preferred_email character varying,
    image_context character varying,
    image_style_profile text
);


--
-- Name: discovered_restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discovered_restaurants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discovered_restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discovered_restaurants_id_seq OWNED BY public.discovered_restaurants.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employees (
    id bigint NOT NULL,
    name character varying,
    eid character varying,
    image character varying,
    status integer,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    role integer,
    email character varying,
    user_id bigint NOT NULL,
    archived boolean DEFAULT false,
    sequence integer
);


--
-- Name: menuitems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitems (
    id bigint NOT NULL,
    name character varying,
    description text,
    status integer,
    sequence integer,
    calories integer,
    price double precision,
    menusection_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    preptime integer DEFAULT 0,
    archived boolean DEFAULT false,
    image_data text,
    itemtype integer DEFAULT 0,
    sizesupport boolean DEFAULT false,
    unitcost double precision DEFAULT 0.0,
    tasting_optional boolean DEFAULT false NOT NULL,
    tasting_supplement_cents integer,
    tasting_supplement_currency character varying,
    course_order integer,
    hidden boolean DEFAULT false NOT NULL,
    tasting_carrier boolean DEFAULT false NOT NULL,
    abv numeric(5,2),
    alcohol_classification character varying,
    alcohol_notes text,
    sommelier_classification_confidence numeric(5,4),
    sommelier_parsed_fields jsonb DEFAULT '{}'::jsonb NOT NULL,
    sommelier_parse_confidence numeric(5,4),
    sommelier_needs_review boolean DEFAULT false NOT NULL,
    image_prompt text,
    ordritems_count integer DEFAULT 0
);


--
-- Name: menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menus (
    id bigint NOT NULL,
    name character varying,
    description text,
    status integer,
    sequence integer,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "displayImages" boolean DEFAULT false,
    "allowOrdering" boolean DEFAULT false,
    "inventoryTracking" boolean DEFAULT false,
    archived boolean DEFAULT false,
    image_data text,
    imagecontext character varying,
    "displayImagesInPopup" boolean DEFAULT false,
    covercharge double precision DEFAULT 0.0,
    menu_import_id bigint,
    "voiceOrderingEnabled" boolean DEFAULT false,
    owner_restaurant_id bigint,
    menuitems_count integer DEFAULT 0,
    menusections_count integer DEFAULT 0,
    archived_at timestamp(6) without time zone,
    archived_reason character varying,
    archived_by_id bigint
);


--
-- Name: menusections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menusections (
    id bigint NOT NULL,
    name character varying,
    description text,
    image character varying,
    status integer,
    sequence integer,
    menu_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    image_data text,
    fromhour integer DEFAULT 0,
    frommin integer DEFAULT 0,
    tohour integer DEFAULT 23,
    tomin integer DEFAULT 59,
    restricted boolean DEFAULT false,
    tasting_menu boolean DEFAULT false NOT NULL,
    tasting_price_cents integer,
    tasting_currency character varying,
    price_per character varying DEFAULT 'person'::character varying,
    min_party_size integer,
    max_party_size integer,
    includes_description text,
    allow_substitutions boolean DEFAULT false NOT NULL,
    allow_pairing boolean DEFAULT false NOT NULL,
    pairing_price_cents integer,
    pairing_currency character varying,
    menuitems_count integer DEFAULT 0
);


--
-- Name: ordritems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordritems (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ordritemprice double precision DEFAULT 0.0,
    status integer DEFAULT 0,
    ordr_station_ticket_id bigint,
    line_key character varying NOT NULL,
    size_name character varying,
    quantity integer DEFAULT 1 NOT NULL,
    CONSTRAINT ordritems_quantity_max CHECK ((quantity <= 99)),
    CONSTRAINT ordritems_quantity_positive CHECK ((quantity > 0))
);


--
-- Name: ordrs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordrs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- Name: ordrs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordrs (
    id integer DEFAULT nextval('public.ordrs_id_seq'::regclass) NOT NULL,
    "orderedAt" timestamp without time zone,
    "deliveredAt" timestamp without time zone,
    "paidAt" timestamp without time zone,
    nett double precision,
    tip double precision,
    service double precision,
    tax double precision,
    gross double precision,
    employee_id integer,
    tablesetting_id bigint NOT NULL,
    menu_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status integer,
    "billRequestedAt" timestamp(6) without time zone,
    ordercapacity integer DEFAULT 0,
    covercharge double precision DEFAULT 0.0,
    paymentlink character varying,
    paymentstatus integer DEFAULT 0,
    last_projected_order_event_sequence bigint DEFAULT 0 NOT NULL,
    ordritems_count integer DEFAULT 0,
    ordrparticipants_count integer DEFAULT 0,
    payment_on_file boolean DEFAULT false NOT NULL,
    payment_method_ref character varying,
    payment_provider character varying,
    payment_on_file_at timestamp(6) without time zone,
    viewed_bill_at timestamp(6) without time zone,
    auto_pay_enabled boolean DEFAULT false NOT NULL,
    auto_pay_consent_at timestamp(6) without time zone,
    auto_pay_attempted_at timestamp(6) without time zone,
    auto_pay_status character varying,
    auto_pay_failure_reason text
);


--
-- Name: restaurants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurants (
    id bigint NOT NULL,
    name character varying,
    description text,
    address1 character varying,
    address2 character varying,
    state character varying,
    city character varying,
    postcode character varying,
    country character varying,
    status integer,
    capacity integer,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    genid character varying,
    "displayImages" boolean DEFAULT false,
    "allowOrdering" boolean DEFAULT false,
    "inventoryTracking" boolean DEFAULT false,
    currency character varying,
    archived boolean DEFAULT false,
    latitude double precision,
    longitude double precision,
    sequence integer,
    image_data text,
    imagecontext character varying,
    wifissid character varying,
    "wifiEncryptionType" integer DEFAULT 0,
    "wifiPassword" character varying,
    "wifiHidden" boolean DEFAULT false,
    spotifyuserid character varying,
    spotifyaccesstoken character varying,
    spotifyrefreshtoken character varying,
    "displayImagesInPopup" boolean DEFAULT false,
    image_style_profile text,
    allow_alcohol boolean DEFAULT false NOT NULL,
    timezone character varying DEFAULT 'UTC'::character varying,
    menus_count integer DEFAULT 0,
    employees_count integer DEFAULT 0,
    ordrs_count integer DEFAULT 0,
    tablesettings_count integer DEFAULT 0,
    ocr_menu_imports_count integer DEFAULT 0,
    archived_at timestamp(6) without time zone,
    archived_reason character varying,
    archived_by_id bigint,
    google_place_id character varying,
    claim_status integer DEFAULT 0 NOT NULL,
    preview_enabled boolean DEFAULT false NOT NULL,
    preview_published_at timestamp(6) without time zone,
    preview_indexable boolean DEFAULT false NOT NULL,
    establishment_types character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    provisioned_by integer DEFAULT 0,
    source_url character varying,
    ordering_enabled boolean DEFAULT false NOT NULL,
    payments_enabled boolean DEFAULT false NOT NULL,
    whiskey_ambassador_enabled boolean DEFAULT false NOT NULL,
    max_whiskey_flights integer DEFAULT 5 NOT NULL,
    payment_provider character varying DEFAULT 'stripe'::character varying,
    payment_provider_status integer DEFAULT 0 NOT NULL,
    square_checkout_mode integer DEFAULT 0 NOT NULL,
    square_location_id character varying,
    square_merchant_id character varying,
    square_application_id character varying,
    square_oauth_revoked_at timestamp(6) without time zone,
    platform_fee_type integer DEFAULT 0 NOT NULL,
    platform_fee_percent numeric(5,2),
    platform_fee_fixed_cents integer,
    payment_gating_enabled boolean DEFAULT false NOT NULL
);


--
-- Name: tablesettings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tablesettings (
    id bigint NOT NULL,
    name character varying,
    description text,
    status integer,
    capacity integer,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tabletype integer,
    archived boolean DEFAULT false,
    sequence integer
);


--
-- Name: dw_orders_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.dw_orders_mv AS
 SELECT o.id AS order_id,
    o."orderedAt" AS ordered_at,
    o."paidAt" AS paid_at,
    round((o.nett)::numeric, 2) AS nett_amount,
    round((o.gross)::numeric, 2) AS gross_amount,
    round((o.tax)::numeric, 2) AS tax_amount,
    round((o.tip)::numeric, 2) AS tip_amount,
    round((o.covercharge)::numeric, 2) AS covercharge_amount,
    o.status,
    r.id AS restaurant_id,
    r.name AS restaurant_name,
    r.city,
    r.country,
    r.currency,
    m.id AS menu_id,
    m.name AS menu_name,
    e.id AS employee_id,
    e.role,
    t.id AS tablesetting_id,
    t.name AS table_name,
    t.capacity AS table_capacity,
    t.tabletype AS table_type,
    COALESCE(sum(oi.quantity), (0)::bigint) AS total_quantity,
    COALESCE(sum((oi.ordritemprice * (oi.quantity)::double precision)), (0)::double precision) AS items_revenue,
    COALESCE(avg(oi.quantity), (0)::numeric) AS avg_quantity_per_item,
    COALESCE(max(oi.quantity), 0) AS max_item_quantity
   FROM (((((((public.ordrs o
     JOIN public.restaurants r ON ((o.restaurant_id = r.id)))
     JOIN public.menus m ON ((o.menu_id = m.id)))
     JOIN public.employees e ON ((o.employee_id = e.id)))
     JOIN public.tablesettings t ON ((o.tablesetting_id = t.id)))
     JOIN public.ordritems oi ON ((oi.ordr_id = o.id)))
     JOIN public.menuitems mi ON ((oi.menuitem_id = mi.id)))
     JOIN public.menusections ms ON ((mi.menusection_id = ms.id)))
  GROUP BY o.id, o."orderedAt", o."deliveredAt", o."paidAt", o.nett, o.gross, o.tax, o.tip, o.covercharge, o.status, r.id, r.name, r.city, r.country, r.currency, m.id, m.name, e.id, e.role, t.id, t.name, t.capacity, t.tabletype
  ORDER BY o.id DESC
  WITH NO DATA;


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- Name: explore_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.explore_pages (
    id bigint NOT NULL,
    country_slug character varying NOT NULL,
    country_name character varying NOT NULL,
    city_slug character varying NOT NULL,
    city_name character varying NOT NULL,
    category_slug character varying,
    category_name character varying,
    restaurant_count integer DEFAULT 0 NOT NULL,
    meta_title text,
    meta_description text,
    last_refreshed_at timestamp(6) without time zone,
    published boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: explore_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.explore_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: explore_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.explore_pages_id_seq OWNED BY public.explore_pages.id;


--
-- Name: features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.features (
    id bigint NOT NULL,
    key character varying,
    "descriptionKey" character varying,
    status integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.features_id_seq OWNED BY public.features.id;


--
-- Name: features_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.features_plans (
    id bigint NOT NULL,
    plan_id bigint NOT NULL,
    feature_id bigint NOT NULL,
    "featurePlanNote" character varying,
    status integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: features_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.features_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: features_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.features_plans_id_seq OWNED BY public.features_plans.id;


--
-- Name: flavor_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flavor_profiles (
    id bigint NOT NULL,
    profilable_type character varying NOT NULL,
    profilable_id bigint NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    structure_metrics jsonb DEFAULT '{}'::jsonb NOT NULL,
    provenance character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flavor_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flavor_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flavor_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flavor_profiles_id_seq OWNED BY public.flavor_profiles.id;


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: friendly_id_slugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendly_id_slugs (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    sluggable_id integer NOT NULL,
    sluggable_type character varying(50),
    scope character varying,
    created_at timestamp(6) without time zone
);


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.friendly_id_slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.friendly_id_slugs_id_seq OWNED BY public.friendly_id_slugs.id;


--
-- Name: genimages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genimages (
    id bigint NOT NULL,
    image_data text,
    name character varying,
    description text,
    restaurant_id bigint NOT NULL,
    menu_id bigint,
    menusection_id bigint,
    menuitem_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    prompt_fingerprint character varying
);


--
-- Name: genimages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genimages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genimages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genimages_id_seq OWNED BY public.genimages.id;


--
-- Name: hero_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hero_images (
    id bigint NOT NULL,
    image_url character varying NOT NULL,
    alt_text character varying,
    sequence integer DEFAULT 0,
    status integer DEFAULT 0 NOT NULL,
    source_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: hero_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hero_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hero_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hero_images_id_seq OWNED BY public.hero_images.id;


--
-- Name: impersonation_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impersonation_audits (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    impersonated_user_id bigint NOT NULL,
    started_at timestamp(6) without time zone NOT NULL,
    ended_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone NOT NULL,
    ip_address character varying,
    user_agent character varying,
    ended_reason character varying,
    reason text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: impersonation_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.impersonation_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impersonation_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.impersonation_audits_id_seq OWNED BY public.impersonation_audits.id;


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredients (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    restaurant_id bigint,
    parent_ingredient_id bigint,
    unit_of_measure character varying,
    current_cost_per_unit numeric(10,4),
    supplier_id bigint,
    category character varying,
    is_shared boolean DEFAULT false
);


--
-- Name: ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredients_id_seq OWNED BY public.ingredients.id;


--
-- Name: inventories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventories (
    id bigint NOT NULL,
    startinginventory integer,
    currentinventory integer,
    resethour integer,
    menuitem_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    status integer DEFAULT 0,
    sequence integer
);


--
-- Name: inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventories_id_seq OWNED BY public.inventories.id;


--
-- Name: jwt_token_usage_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jwt_token_usage_logs (
    id bigint NOT NULL,
    jwt_token_id bigint NOT NULL,
    endpoint character varying NOT NULL,
    http_method character varying NOT NULL,
    ip_address character varying,
    response_status integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: jwt_token_usage_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jwt_token_usage_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jwt_token_usage_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jwt_token_usage_logs_id_seq OWNED BY public.jwt_token_usage_logs.id;


--
-- Name: ledger_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_events (
    id bigint NOT NULL,
    entity_type integer DEFAULT 0 NOT NULL,
    entity_id bigint,
    event_type integer DEFAULT 0 NOT NULL,
    amount_cents integer,
    currency character varying,
    provider integer DEFAULT 0 NOT NULL,
    provider_event_id character varying NOT NULL,
    provider_event_type character varying,
    raw_event_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ledger_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ledger_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ledger_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ledger_events_id_seq OWNED BY public.ledger_events.id;


--
-- Name: local_guides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.local_guides (
    id bigint NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    city character varying NOT NULL,
    country character varying NOT NULL,
    category character varying,
    content text NOT NULL,
    content_source text,
    referenced_restaurants jsonb DEFAULT '[]'::jsonb,
    faq_data jsonb DEFAULT '[]'::jsonb,
    status integer DEFAULT 0 NOT NULL,
    published_at timestamp(6) without time zone,
    regenerated_at timestamp(6) without time zone,
    approved_by_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: local_guides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.local_guides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: local_guides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.local_guides_id_seq OWNED BY public.local_guides.id;


--
-- Name: marketing_qr_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketing_qr_codes (
    id bigint NOT NULL,
    token character varying NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    holding_url character varying,
    restaurant_id bigint,
    menu_id bigint,
    tablesetting_id bigint,
    smartmenu_id bigint,
    created_by_user_id bigint NOT NULL,
    name character varying,
    campaign character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: marketing_qr_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marketing_qr_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marketing_qr_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marketing_qr_codes_id_seq OWNED BY public.marketing_qr_codes.id;


--
-- Name: memory_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memory_metrics (
    id bigint NOT NULL,
    heap_size bigint NOT NULL,
    heap_free bigint,
    objects_allocated bigint,
    gc_count integer,
    rss_memory bigint,
    "timestamp" timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: memory_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memory_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memory_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memory_metrics_id_seq OWNED BY public.memory_metrics.id;


--
-- Name: menu_edit_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_edit_sessions (
    id bigint NOT NULL,
    menu_id bigint NOT NULL,
    user_id bigint NOT NULL,
    session_id character varying NOT NULL,
    locked_fields json DEFAULT '[]'::json,
    started_at timestamp(6) without time zone,
    last_activity_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menu_edit_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_edit_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_edit_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_edit_sessions_id_seq OWNED BY public.menu_edit_sessions.id;


--
-- Name: menu_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_imports (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    user_id bigint NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menu_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_imports_id_seq OWNED BY public.menu_imports.id;


--
-- Name: menu_item_product_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_item_product_links (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    product_id bigint NOT NULL,
    resolution_confidence numeric(5,4),
    explanations text,
    locked boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menu_item_product_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_item_product_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_item_product_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_item_product_links_id_seq OWNED BY public.menu_item_product_links.id;


--
-- Name: menu_item_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_item_search_documents (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    menu_id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    locale character varying NOT NULL,
    document_text text DEFAULT ''::text NOT NULL,
    content_hash character varying NOT NULL,
    indexed_at timestamp(6) without time zone,
    embedding public.vector(384),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    document_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple'::regconfig, COALESCE(document_text, ''::text))) STORED
);


--
-- Name: menu_item_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_item_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_item_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_item_search_documents_id_seq OWNED BY public.menu_item_search_documents.id;


--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_items (
    id bigint NOT NULL,
    name character varying,
    description text,
    price numeric,
    menu_section_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "position" integer,
    metadata jsonb
);


--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_items_id_seq OWNED BY public.menu_items.id;


--
-- Name: menu_performance_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.menu_performance_mv AS
 SELECT r.id AS restaurant_id,
    m.id AS menu_id,
    m.name AS menu_name,
    ms.id AS menusection_id,
    ms.name AS category_name,
    mi.id AS menuitem_id,
    mi.name AS item_name,
    mi.price AS item_price,
    date_trunc('day'::text, o.created_at) AS date,
    date_trunc('month'::text, o.created_at) AS month,
    count(oi.id) AS times_ordered,
    COALESCE(sum(oi.quantity), (0)::bigint) AS total_quantity,
    COALESCE(sum((oi.ordritemprice * (oi.quantity)::double precision)), (0)::double precision) AS total_revenue,
    COALESCE(avg(oi.ordritemprice), (0)::double precision) AS avg_item_revenue,
    row_number() OVER (PARTITION BY r.id, (date_trunc('month'::text, o.created_at)) ORDER BY COALESCE(sum(oi.quantity), (0)::bigint) DESC) AS popularity_rank,
    row_number() OVER (PARTITION BY r.id, (date_trunc('month'::text, o.created_at)) ORDER BY COALESCE(sum((oi.ordritemprice * (oi.quantity)::double precision)), (0)::double precision) DESC) AS revenue_rank
   FROM (((((public.restaurants r
     JOIN public.menus m ON ((r.id = m.restaurant_id)))
     JOIN public.menusections ms ON ((m.id = ms.menu_id)))
     JOIN public.menuitems mi ON ((ms.id = mi.menusection_id)))
     LEFT JOIN public.ordritems oi ON ((mi.id = oi.menuitem_id)))
     LEFT JOIN public.ordrs o ON (((oi.ordr_id = o.id) AND (o.status = ANY (ARRAY[35, 40])))))
  GROUP BY r.id, m.id, m.name, ms.id, ms.name, mi.id, mi.name, mi.price, (date_trunc('day'::text, o.created_at)), (date_trunc('month'::text, o.created_at))
  WITH NO DATA;


--
-- Name: menu_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_sections (
    id bigint NOT NULL,
    name character varying,
    description text,
    "position" integer,
    menu_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menu_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_sections_id_seq OWNED BY public.menu_sections.id;


--
-- Name: menu_source_change_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_source_change_reviews (
    id bigint NOT NULL,
    menu_source_id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    detected_at timestamp(6) without time zone NOT NULL,
    previous_fingerprint character varying,
    new_fingerprint character varying,
    previous_etag character varying,
    new_etag character varying,
    previous_last_modified timestamp(6) without time zone,
    new_last_modified timestamp(6) without time zone,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    diff_content text,
    diff_status integer DEFAULT 0 NOT NULL
);


--
-- Name: menu_source_change_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_source_change_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_source_change_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_source_change_reviews_id_seq OWNED BY public.menu_source_change_reviews.id;


--
-- Name: menu_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_sources (
    id bigint NOT NULL,
    restaurant_id bigint,
    discovered_restaurant_id bigint,
    source_url character varying NOT NULL,
    source_type integer DEFAULT 0 NOT NULL,
    last_checked_at timestamp(6) without time zone,
    last_fingerprint character varying,
    etag character varying,
    last_modified timestamp(6) without time zone,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying
);


--
-- Name: menu_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_sources_id_seq OWNED BY public.menu_sources.id;


--
-- Name: menu_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_versions (
    id bigint NOT NULL,
    menu_id bigint NOT NULL,
    version_number integer NOT NULL,
    snapshot_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_by_user_id bigint,
    is_active boolean DEFAULT false NOT NULL,
    starts_at timestamp(6) without time zone,
    ends_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menu_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_versions_id_seq OWNED BY public.menu_versions.id;


--
-- Name: menuavailabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuavailabilities (
    id bigint NOT NULL,
    dayofweek integer,
    starthour integer,
    startmin integer,
    endhour integer,
    endmin integer,
    menu_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status integer,
    sequence integer,
    archived boolean DEFAULT false
);


--
-- Name: menuavailabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuavailabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuavailabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuavailabilities_id_seq OWNED BY public.menuavailabilities.id;


--
-- Name: menuitem_allergyn_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitem_allergyn_mappings (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    allergyn_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuitem_allergyn_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitem_allergyn_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitem_allergyn_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitem_allergyn_mappings_id_seq OWNED BY public.menuitem_allergyn_mappings.id;


--
-- Name: menuitem_costs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitem_costs (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    ingredient_cost numeric(10,4) DEFAULT 0.0,
    labor_cost numeric(10,4) DEFAULT 0.0,
    packaging_cost numeric(10,4) DEFAULT 0.0,
    overhead_cost numeric(10,4) DEFAULT 0.0,
    cost_source character varying DEFAULT 'manual'::character varying,
    is_active boolean DEFAULT true,
    effective_date date NOT NULL,
    notes text,
    created_by_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuitem_costs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitem_costs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitem_costs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitem_costs_id_seq OWNED BY public.menuitem_costs.id;


--
-- Name: menuitem_ingredient_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitem_ingredient_mappings (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuitem_ingredient_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitem_ingredient_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitem_ingredient_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitem_ingredient_mappings_id_seq OWNED BY public.menuitem_ingredient_mappings.id;


--
-- Name: menuitem_ingredient_quantities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitem_ingredient_quantities (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    quantity numeric(10,4) NOT NULL,
    unit character varying NOT NULL,
    cost_per_unit numeric(10,4),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuitem_ingredient_quantities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitem_ingredient_quantities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitem_ingredient_quantities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitem_ingredient_quantities_id_seq OWNED BY public.menuitem_ingredient_quantities.id;


--
-- Name: menuitem_size_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitem_size_mappings (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    size_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    price double precision DEFAULT 0.0
);


--
-- Name: menuitem_size_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitem_size_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitem_size_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitem_size_mappings_id_seq OWNED BY public.menuitem_size_mappings.id;


--
-- Name: menuitem_tag_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitem_tag_mappings (
    id bigint NOT NULL,
    menuitem_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuitem_tag_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitem_tag_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitem_tag_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitem_tag_mappings_id_seq OWNED BY public.menuitem_tag_mappings.id;


--
-- Name: menuitemlocales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuitemlocales (
    id bigint NOT NULL,
    locale character varying,
    status integer,
    name character varying,
    description character varying,
    menuitem_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuitemlocales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitemlocales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitemlocales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitemlocales_id_seq OWNED BY public.menuitemlocales.id;


--
-- Name: menuitems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuitems_id_seq OWNED BY public.menuitems.id;


--
-- Name: menulocales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menulocales (
    id bigint NOT NULL,
    locale character varying,
    status integer,
    name character varying,
    description character varying,
    menu_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menulocales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menulocales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menulocales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menulocales_id_seq OWNED BY public.menulocales.id;


--
-- Name: menuparticipants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menuparticipants (
    id bigint NOT NULL,
    sessionid character varying,
    preferredlocale character varying,
    smartmenu_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menuparticipants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menuparticipants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menuparticipants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menuparticipants_id_seq OWNED BY public.menuparticipants.id;


--
-- Name: menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menus_id_seq OWNED BY public.menus.id;


--
-- Name: menusectionlocales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menusectionlocales (
    id bigint NOT NULL,
    locale character varying,
    status integer,
    name character varying,
    description character varying,
    menusection_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menusectionlocales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menusectionlocales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menusectionlocales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menusectionlocales_id_seq OWNED BY public.menusectionlocales.id;


--
-- Name: menusections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menusections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menusections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menusections_id_seq OWNED BY public.menusections.id;


--
-- Name: metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metrics (
    id bigint NOT NULL,
    "numberOfRestaurants" integer,
    "numberOfMenus" integer,
    "numberOfMenuItems" integer,
    "numberOfOrders" integer,
    "totalOrderValue" double precision,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.metrics_id_seq OWNED BY public.metrics.id;


--
-- Name: noticed_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticed_events (
    id bigint NOT NULL,
    type character varying,
    record_type character varying,
    record_id bigint,
    params jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    notifications_count integer
);


--
-- Name: noticed_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticed_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticed_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticed_events_id_seq OWNED BY public.noticed_events.id;


--
-- Name: noticed_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticed_notifications (
    id bigint NOT NULL,
    type character varying,
    event_id bigint NOT NULL,
    recipient_type character varying NOT NULL,
    recipient_id bigint NOT NULL,
    read_at timestamp without time zone,
    seen_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: noticed_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.noticed_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: noticed_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.noticed_notifications_id_seq OWNED BY public.noticed_notifications.id;


--
-- Name: ocr_menu_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ocr_menu_imports (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    name character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    total_pages integer,
    processed_pages integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    menu_id bigint,
    completed_at timestamp(6) without time zone,
    failed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    source_locale character varying,
    ai_mode integer DEFAULT 0 NOT NULL
);


--
-- Name: ocr_menu_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ocr_menu_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ocr_menu_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ocr_menu_imports_id_seq OWNED BY public.ocr_menu_imports.id;


--
-- Name: ocr_menu_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ocr_menu_items (
    id bigint NOT NULL,
    ocr_menu_section_id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    price numeric(10,2),
    allergens text[] DEFAULT '{}'::text[],
    sequence integer DEFAULT 0 NOT NULL,
    is_confirmed boolean DEFAULT false NOT NULL,
    is_vegetarian boolean DEFAULT false,
    is_vegan boolean DEFAULT false,
    is_gluten_free boolean DEFAULT false,
    metadata jsonb DEFAULT '{}'::jsonb,
    page_reference character varying,
    menu_item_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_dairy_free boolean DEFAULT false NOT NULL,
    menuitem_id bigint,
    image_prompt text,
    estimated_ingredient_cost numeric(10,4),
    estimated_labor_cost numeric(10,4),
    estimated_packaging_cost numeric(10,4),
    estimated_overhead_cost numeric(10,4),
    cost_estimation_confidence numeric(5,2),
    ai_cost_notes text
);


--
-- Name: ocr_menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ocr_menu_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ocr_menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ocr_menu_items_id_seq OWNED BY public.ocr_menu_items.id;


--
-- Name: ocr_menu_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ocr_menu_sections (
    id bigint NOT NULL,
    ocr_menu_import_id bigint NOT NULL,
    name character varying NOT NULL,
    sequence integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    is_confirmed boolean DEFAULT false NOT NULL,
    page_reference character varying,
    menu_section_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text,
    menusection_id bigint
);


--
-- Name: ocr_menu_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ocr_menu_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ocr_menu_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ocr_menu_sections_id_seq OWNED BY public.ocr_menu_sections.id;


--
-- Name: old_passwords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.old_passwords (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    encrypted_password character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: old_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.old_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: old_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.old_passwords_id_seq OWNED BY public.old_passwords.id;


--
-- Name: onboarding_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.onboarding_sessions (
    id bigint NOT NULL,
    user_id bigint,
    status integer DEFAULT 0 NOT NULL,
    wizard_data text,
    restaurant_id bigint,
    menu_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: onboarding_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.onboarding_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: onboarding_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.onboarding_sessions_id_seq OWNED BY public.onboarding_sessions.id;


--
-- Name: order_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_events (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    sequence bigint NOT NULL,
    event_type character varying NOT NULL,
    entity_type character varying NOT NULL,
    entity_id bigint,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    source character varying NOT NULL,
    idempotency_key character varying,
    occurred_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: order_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_events_id_seq OWNED BY public.order_events.id;


--
-- Name: ordr_split_item_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordr_split_item_assignments (
    id bigint NOT NULL,
    ordr_split_plan_id bigint NOT NULL,
    ordr_split_payment_id bigint NOT NULL,
    ordritem_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ordr_split_item_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordr_split_item_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordr_split_item_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordr_split_item_assignments_id_seq OWNED BY public.ordr_split_item_assignments.id;


--
-- Name: ordr_split_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordr_split_payments (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    ordrparticipant_id bigint,
    amount_cents integer NOT NULL,
    currency character varying NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    provider_checkout_session_id character varying,
    provider_payment_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    provider integer DEFAULT 0 NOT NULL,
    idempotency_key character varying,
    tip_cents integer DEFAULT 0 NOT NULL,
    payer_ref character varying,
    ordr_split_plan_id bigint,
    split_method integer,
    "position" integer,
    base_amount_cents integer DEFAULT 0 NOT NULL,
    tax_amount_cents integer DEFAULT 0 NOT NULL,
    tip_amount_cents integer DEFAULT 0 NOT NULL,
    service_charge_amount_cents integer DEFAULT 0 NOT NULL,
    percentage_basis_points integer,
    locked_at timestamp(6) without time zone
);


--
-- Name: ordr_split_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordr_split_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordr_split_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordr_split_payments_id_seq OWNED BY public.ordr_split_payments.id;


--
-- Name: ordr_split_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordr_split_plans (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    split_method integer DEFAULT 0 NOT NULL,
    plan_status integer DEFAULT 0 NOT NULL,
    participant_count integer DEFAULT 0 NOT NULL,
    frozen_at timestamp(6) without time zone,
    created_by_user_id bigint,
    updated_by_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ordr_split_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordr_split_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordr_split_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordr_split_plans_id_seq OWNED BY public.ordr_split_plans.id;


--
-- Name: ordr_station_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordr_station_tickets (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    station integer NOT NULL,
    status integer DEFAULT 20 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sequence integer DEFAULT 1 NOT NULL,
    submitted_at timestamp(6) without time zone
);


--
-- Name: ordr_station_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordr_station_tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordr_station_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordr_station_tickets_id_seq OWNED BY public.ordr_station_tickets.id;


--
-- Name: ordractions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordractions (
    id bigint NOT NULL,
    action integer,
    ordrparticipant_id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    ordritem_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ordractions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordractions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordractions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordractions_id_seq OWNED BY public.ordractions.id;


--
-- Name: ordritemnotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordritemnotes (
    id bigint NOT NULL,
    note character varying,
    ordritem_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ordritemnotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordritemnotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordritemnotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordritemnotes_id_seq OWNED BY public.ordritemnotes.id;


--
-- Name: ordritems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordritems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordritems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordritems_id_seq OWNED BY public.ordritems.id;


--
-- Name: ordrnotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordrnotes (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    content text NOT NULL,
    category integer DEFAULT 0 NOT NULL,
    priority integer DEFAULT 1 NOT NULL,
    visible_to_kitchen boolean DEFAULT true,
    visible_to_servers boolean DEFAULT true,
    visible_to_customers boolean DEFAULT false,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ordrnotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordrnotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordrnotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordrnotes_id_seq OWNED BY public.ordrnotes.id;


--
-- Name: ordrparticipant_allergyn_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordrparticipant_allergyn_filters (
    id bigint NOT NULL,
    ordrparticipant_id bigint NOT NULL,
    allergyn_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ordrparticipant_allergyn_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordrparticipant_allergyn_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordrparticipant_allergyn_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordrparticipant_allergyn_filters_id_seq OWNED BY public.ordrparticipant_allergyn_filters.id;


--
-- Name: ordrparticipants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordrparticipants (
    id bigint NOT NULL,
    sessionid character varying,
    role integer,
    ordr_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying,
    ordritem_id bigint,
    employee_id bigint,
    preferredlocale character varying
);


--
-- Name: ordrparticipants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ordrparticipants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordrparticipants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ordrparticipants_id_seq OWNED BY public.ordrparticipants.id;


--
-- Name: pairing_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pairing_recommendations (
    id bigint NOT NULL,
    drink_menuitem_id bigint NOT NULL,
    food_menuitem_id bigint NOT NULL,
    complement_score numeric(5,4) DEFAULT 0.0,
    contrast_score numeric(5,4) DEFAULT 0.0,
    score numeric(5,4) DEFAULT 0.0,
    rationale text,
    risk_flags jsonb DEFAULT '[]'::jsonb NOT NULL,
    pairing_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pairing_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pairing_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pairing_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pairing_recommendations_id_seq OWNED BY public.pairing_recommendations.id;


--
-- Name: pay_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_charges (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    subscription_id bigint,
    processor_id character varying NOT NULL,
    amount integer NOT NULL,
    currency character varying,
    application_fee_amount integer,
    amount_refunded integer,
    metadata jsonb,
    data jsonb,
    stripe_account character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying
);


--
-- Name: pay_charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_charges_id_seq OWNED BY public.pay_charges.id;


--
-- Name: pay_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_customers (
    id bigint NOT NULL,
    owner_type character varying,
    owner_id bigint,
    processor character varying NOT NULL,
    processor_id character varying,
    "default" boolean,
    data jsonb,
    stripe_account character varying,
    deleted_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying
);


--
-- Name: pay_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_customers_id_seq OWNED BY public.pay_customers.id;


--
-- Name: pay_merchants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_merchants (
    id bigint NOT NULL,
    owner_type character varying,
    owner_id bigint,
    processor character varying NOT NULL,
    processor_id character varying,
    "default" boolean,
    data jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying
);


--
-- Name: pay_merchants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_merchants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_merchants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_merchants_id_seq OWNED BY public.pay_merchants.id;


--
-- Name: pay_payment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_payment_methods (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    processor_id character varying NOT NULL,
    "default" boolean,
    payment_method_type character varying,
    data jsonb,
    stripe_account character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying
);


--
-- Name: pay_payment_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_payment_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_payment_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_payment_methods_id_seq OWNED BY public.pay_payment_methods.id;


--
-- Name: pay_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_subscriptions (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    name character varying NOT NULL,
    processor_id character varying NOT NULL,
    processor_plan character varying NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    status character varying NOT NULL,
    current_period_start timestamp without time zone,
    current_period_end timestamp without time zone,
    trial_ends_at timestamp without time zone,
    ends_at timestamp without time zone,
    metered boolean,
    pause_behavior character varying,
    pause_starts_at timestamp without time zone,
    pause_resumes_at timestamp without time zone,
    application_fee_percent numeric(8,2),
    metadata jsonb,
    data jsonb,
    stripe_account character varying,
    payment_method_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying
);


--
-- Name: pay_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_subscriptions_id_seq OWNED BY public.pay_subscriptions.id;


--
-- Name: pay_webhooks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pay_webhooks (
    id bigint NOT NULL,
    processor character varying,
    event_type character varying,
    event jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pay_webhooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pay_webhooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pay_webhooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pay_webhooks_id_seq OWNED BY public.pay_webhooks.id;


--
-- Name: payment_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_attempts (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    provider integer DEFAULT 0 NOT NULL,
    provider_payment_id character varying,
    amount_cents integer NOT NULL,
    currency character varying NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    charge_pattern integer DEFAULT 0 NOT NULL,
    merchant_model integer DEFAULT 0 NOT NULL,
    platform_fee_cents integer,
    provider_fee_cents integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    idempotency_key character varying,
    tip_cents integer DEFAULT 0 NOT NULL,
    provider_checkout_url character varying
);


--
-- Name: payment_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_attempts_id_seq OWNED BY public.payment_attempts.id;


--
-- Name: payment_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_profiles (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    merchant_model integer DEFAULT 0 NOT NULL,
    primary_provider integer DEFAULT 0 NOT NULL,
    fallback_providers jsonb DEFAULT '{}'::jsonb NOT NULL,
    default_country character varying,
    default_currency character varying,
    fee_model jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: payment_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_profiles_id_seq OWNED BY public.payment_profiles.id;


--
-- Name: payment_refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_refunds (
    id bigint NOT NULL,
    payment_attempt_id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    provider integer DEFAULT 0 NOT NULL,
    provider_refund_id character varying,
    amount_cents integer,
    currency character varying,
    status integer DEFAULT 0 NOT NULL,
    provider_response_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: payment_refunds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_refunds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_refunds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_refunds_id_seq OWNED BY public.payment_refunds.id;


--
-- Name: performance_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.performance_metrics (
    id bigint NOT NULL,
    endpoint character varying NOT NULL,
    response_time double precision NOT NULL,
    memory_usage integer,
    status_code integer NOT NULL,
    user_id bigint,
    controller character varying,
    action character varying,
    "timestamp" timestamp(6) without time zone NOT NULL,
    additional_data json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: performance_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.performance_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: performance_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.performance_metrics_id_seq OWNED BY public.performance_metrics.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id bigint NOT NULL,
    key character varying,
    "descriptionKey" character varying,
    attribute1 character varying,
    attribute2 character varying,
    attribute3 character varying,
    attribute4 character varying,
    attribute5 character varying,
    attribut6 character varying,
    status integer,
    favourite boolean,
    "pricePerMonth" numeric,
    "pricePerYear" numeric,
    action integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    itemspermenu integer DEFAULT 0,
    languages integer DEFAULT 0,
    locations integer DEFAULT 0,
    menusperlocation integer DEFAULT 0,
    stripe_price_id_month character varying,
    stripe_price_id_year character varying
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: product_enrichments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_enrichments (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    source character varying NOT NULL,
    external_id character varying,
    payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    fetched_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: product_enrichments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_enrichments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_enrichments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_enrichments_id_seq OWNED BY public.product_enrichments.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    product_type character varying NOT NULL,
    canonical_name character varying NOT NULL,
    attributes_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: profit_margin_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profit_margin_targets (
    id bigint NOT NULL,
    restaurant_id bigint,
    menusection_id bigint,
    menuitem_id bigint,
    target_margin_percentage numeric(5,2) NOT NULL,
    minimum_margin_percentage numeric(5,2),
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: profit_margin_targets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profit_margin_targets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profit_margin_targets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profit_margin_targets_id_seq OWNED BY public.profit_margin_targets.id;


--
-- Name: provider_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provider_accounts (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    provider integer DEFAULT 0 NOT NULL,
    provider_account_id character varying,
    account_type character varying,
    country character varying,
    currency character varying,
    status integer DEFAULT 0 NOT NULL,
    capabilities jsonb DEFAULT '{}'::jsonb NOT NULL,
    payouts_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    access_token text,
    refresh_token text,
    token_expires_at timestamp(6) without time zone,
    environment character varying DEFAULT 'production'::character varying NOT NULL,
    scopes text,
    connected_at timestamp(6) without time zone,
    disconnected_at timestamp(6) without time zone
);


--
-- Name: provider_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.provider_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provider_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.provider_accounts_id_seq OWNED BY public.provider_accounts.id;


--
-- Name: push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_subscriptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    endpoint character varying NOT NULL,
    p256dh_key text NOT NULL,
    auth_key text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.push_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.push_subscriptions_id_seq OWNED BY public.push_subscriptions.id;


--
-- Name: receipt_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receipt_deliveries (
    id bigint NOT NULL,
    ordr_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    created_by_user_id bigint,
    recipient_email character varying,
    recipient_phone character varying,
    delivery_method character varying DEFAULT 'email'::character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    sent_at timestamp(6) without time zone,
    error_message text,
    retry_count integer DEFAULT 0 NOT NULL,
    secure_token character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: receipt_deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.receipt_deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: receipt_deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.receipt_deliveries_id_seq OWNED BY public.receipt_deliveries.id;


--
-- Name: resource_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_locks (
    id bigint NOT NULL,
    resource_type character varying NOT NULL,
    resource_id bigint NOT NULL,
    field_name character varying,
    user_id bigint NOT NULL,
    session_id character varying NOT NULL,
    acquired_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: resource_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resource_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resource_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resource_locks_id_seq OWNED BY public.resource_locks.id;


--
-- Name: restaurant_analytics_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.restaurant_analytics_mv AS
 SELECT r.id AS restaurant_id,
    r.name AS restaurant_name,
    r.currency,
    date_trunc('day'::text, o.created_at) AS date,
    date_trunc('week'::text, o.created_at) AS week,
    date_trunc('month'::text, o.created_at) AS month,
    EXTRACT(hour FROM o.created_at) AS hour,
    EXTRACT(dow FROM o.created_at) AS day_of_week,
    count(DISTINCT o.id) AS total_orders,
    count(DISTINCT
        CASE
            WHEN (o.status = ANY (ARRAY[35, 40])) THEN o.id
            ELSE NULL::integer
        END) AS completed_orders,
    count(DISTINCT
        CASE
            WHEN (o.status = '-1'::integer) THEN o.id
            ELSE NULL::integer
        END) AS cancelled_orders,
    COALESCE(sum(
        CASE
            WHEN (o.status = ANY (ARRAY[35, 40])) THEN (oi.ordritemprice * (oi.quantity)::double precision)
            ELSE NULL::double precision
        END), (0)::double precision) AS total_revenue,
    COALESCE((sum(
        CASE
            WHEN (o.status = ANY (ARRAY[35, 40])) THEN (oi.ordritemprice * (oi.quantity)::double precision)
            ELSE NULL::double precision
        END) / (NULLIF(count(DISTINCT
        CASE
            WHEN (o.status = ANY (ARRAY[35, 40])) THEN o.id
            ELSE NULL::integer
        END), 0))::double precision), (0)::double precision) AS avg_order_value,
    count(DISTINCT o.tablesetting_id) AS unique_tables,
    count(DISTINCT
        CASE
            WHEN (repeat_customers.order_count > 1) THEN o.tablesetting_id
            ELSE NULL::bigint
        END) AS repeat_customers
   FROM (((public.restaurants r
     LEFT JOIN public.ordrs o ON ((r.id = o.restaurant_id)))
     LEFT JOIN public.ordritems oi ON ((o.id = oi.ordr_id)))
     LEFT JOIN ( SELECT ordrs.tablesetting_id,
            ordrs.restaurant_id,
            count(*) AS order_count
           FROM public.ordrs
          WHERE (ordrs.tablesetting_id IS NOT NULL)
          GROUP BY ordrs.tablesetting_id, ordrs.restaurant_id) repeat_customers ON (((o.tablesetting_id = repeat_customers.tablesetting_id) AND (o.restaurant_id = repeat_customers.restaurant_id))))
  GROUP BY r.id, r.name, r.currency, (date_trunc('day'::text, o.created_at)), (date_trunc('week'::text, o.created_at)), (date_trunc('month'::text, o.created_at)), (EXTRACT(hour FROM o.created_at)), (EXTRACT(dow FROM o.created_at))
  WITH NO DATA;


--
-- Name: restaurant_claim_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_claim_requests (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    initiated_by_user_id bigint,
    status integer DEFAULT 0 NOT NULL,
    verification_method integer DEFAULT 0 NOT NULL,
    claimant_email character varying NOT NULL,
    claimant_name character varying,
    evidence text,
    review_notes text,
    verified_at timestamp(6) without time zone,
    reviewed_by_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: restaurant_claim_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurant_claim_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurant_claim_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurant_claim_requests_id_seq OWNED BY public.restaurant_claim_requests.id;


--
-- Name: restaurant_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_menus (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    menu_id bigint NOT NULL,
    sequence integer,
    status integer DEFAULT 1 NOT NULL,
    availability_override_enabled boolean DEFAULT false NOT NULL,
    availability_state integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived_at timestamp(6) without time zone,
    archived_reason character varying,
    archived_by_id bigint
);


--
-- Name: restaurant_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurant_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurant_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurant_menus_id_seq OWNED BY public.restaurant_menus.id;


--
-- Name: restaurant_onboardings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_onboardings (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    status integer DEFAULT 0,
    progress_steps jsonb DEFAULT '{}'::jsonb,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: restaurant_onboardings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurant_onboardings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurant_onboardings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurant_onboardings_id_seq OWNED BY public.restaurant_onboardings.id;


--
-- Name: restaurant_removal_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_removal_requests (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    requested_by_email character varying NOT NULL,
    source integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    reason text,
    admin_notes text,
    actioned_at timestamp(6) without time zone,
    actioned_by_user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: restaurant_removal_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurant_removal_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurant_removal_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurant_removal_requests_id_seq OWNED BY public.restaurant_removal_requests.id;


--
-- Name: restaurant_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_subscriptions (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    stripe_customer_id character varying,
    stripe_subscription_id character varying,
    payment_method_on_file boolean DEFAULT false NOT NULL,
    trial_ends_at timestamp(6) without time zone,
    current_period_end timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: restaurant_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurant_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurant_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurant_subscriptions_id_seq OWNED BY public.restaurant_subscriptions.id;


--
-- Name: restaurantavailabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurantavailabilities (
    id bigint NOT NULL,
    dayofweek integer,
    starthour integer,
    startmin integer,
    endhour integer,
    endmin integer,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status integer,
    sequence integer,
    archived boolean DEFAULT false
);


--
-- Name: restaurantavailabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurantavailabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurantavailabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurantavailabilities_id_seq OWNED BY public.restaurantavailabilities.id;


--
-- Name: restaurantlocales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurantlocales (
    id bigint NOT NULL,
    locale character varying,
    status integer,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    dfault boolean,
    sequence integer DEFAULT 0 NOT NULL
);


--
-- Name: restaurantlocales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurantlocales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurantlocales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurantlocales_id_seq OWNED BY public.restaurantlocales.id;


--
-- Name: restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restaurants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restaurants_id_seq OWNED BY public.restaurants.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    provider character varying,
    uid character varying,
    access_token character varying,
    access_token_secret character varying,
    refresh_token character varying,
    expires_at timestamp(6) without time zone,
    auth text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: similar_product_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.similar_product_recommendations (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    recommended_product_id bigint NOT NULL,
    score numeric(5,4) DEFAULT 0.0,
    rationale text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: similar_product_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.similar_product_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: similar_product_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.similar_product_recommendations_id_seq OWNED BY public.similar_product_recommendations.id;


--
-- Name: sizes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sizes (
    id bigint NOT NULL,
    size integer,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    status integer DEFAULT 0,
    sequence integer,
    restaurant_id bigint,
    category character varying DEFAULT 'general'::character varying NOT NULL
);


--
-- Name: sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sizes_id_seq OWNED BY public.sizes.id;


--
-- Name: slow_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slow_queries (
    id bigint NOT NULL,
    sql text NOT NULL,
    duration double precision NOT NULL,
    query_name character varying,
    backtrace text,
    "timestamp" timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: slow_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.slow_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: slow_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.slow_queries_id_seq OWNED BY public.slow_queries.id;


--
-- Name: smartmenus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.smartmenus (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    restaurant_id bigint NOT NULL,
    menu_id bigint,
    tablesetting_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    public_token character varying(64) NOT NULL
);


--
-- Name: smartmenus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.smartmenus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: smartmenus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.smartmenus_id_seq OWNED BY public.smartmenus.id;


--
-- Name: staff_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_invitations (
    id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    invited_by_id bigint NOT NULL,
    email character varying NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    token character varying NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    accepted_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: staff_invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_invitations_id_seq OWNED BY public.staff_invitations.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    first_name character varying,
    last_name character varying,
    announcements_last_read_at timestamp(6) without time zone,
    admin boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    plan_id bigint,
    confirmation_token character varying,
    confirmed_at timestamp(6) without time zone,
    confirmation_sent_at timestamp(6) without time zone,
    unconfirmed_email character varying,
    restaurants_count integer DEFAULT 0,
    employees_count integer DEFAULT 0,
    super_admin boolean DEFAULT false NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp(6) without time zone,
    password_changed_at timestamp(6) without time zone,
    encrypted_password_salt character varying,
    encrypted_password_iv character varying,
    session_limitable integer,
    unique_session_id character varying,
    last_activity_at timestamp(6) without time zone,
    expired_at timestamp(6) without time zone
);


--
-- Name: system_analytics_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.system_analytics_mv AS
 SELECT date_trunc('day'::text, created_at) AS date,
    date_trunc('week'::text, created_at) AS week,
    date_trunc('month'::text, created_at) AS month,
    count(DISTINCT
        CASE
            WHEN (entity_type = 'restaurant'::text) THEN entity_id
            ELSE NULL::bigint
        END) AS new_restaurants,
    count(DISTINCT
        CASE
            WHEN (entity_type = 'user'::text) THEN entity_id
            ELSE NULL::bigint
        END) AS new_users,
    count(DISTINCT
        CASE
            WHEN (entity_type = 'menu'::text) THEN entity_id
            ELSE NULL::bigint
        END) AS new_menus,
    count(DISTINCT
        CASE
            WHEN (entity_type = 'menuitem'::text) THEN entity_id
            ELSE NULL::bigint
        END) AS new_menuitems,
    count(DISTINCT
        CASE
            WHEN (entity_type = 'order'::text) THEN entity_id
            ELSE NULL::bigint
        END) AS total_orders,
    COALESCE(sum(
        CASE
            WHEN (entity_type = 'order'::text) THEN revenue
            ELSE NULL::double precision
        END), (0)::double precision) AS total_revenue,
    count(DISTINCT
        CASE
            WHEN (entity_type = 'active_restaurant'::text) THEN entity_id
            ELSE NULL::bigint
        END) AS active_restaurants
   FROM ( SELECT restaurants.id AS entity_id,
            'restaurant'::text AS entity_type,
            restaurants.created_at,
            0 AS revenue
           FROM public.restaurants
        UNION ALL
         SELECT users.id AS entity_id,
            'user'::text AS entity_type,
            users.created_at,
            0 AS revenue
           FROM public.users
        UNION ALL
         SELECT menus.id AS entity_id,
            'menu'::text AS entity_type,
            menus.created_at,
            0 AS revenue
           FROM public.menus
        UNION ALL
         SELECT menuitems.id AS entity_id,
            'menuitem'::text AS entity_type,
            menuitems.created_at,
            0 AS revenue
           FROM public.menuitems
        UNION ALL
         SELECT o.id AS entity_id,
            'order'::text AS entity_type,
            o.created_at,
            COALESCE(sum((oi.ordritemprice * (oi.quantity)::double precision)), (0)::double precision) AS revenue
           FROM (public.ordrs o
             LEFT JOIN public.ordritems oi ON ((o.id = oi.ordr_id)))
          WHERE (o.status = ANY (ARRAY[35, 40]))
          GROUP BY o.id, o.created_at
        UNION ALL
         SELECT DISTINCT r.id AS entity_id,
            'active_restaurant'::text AS entity_type,
            o.created_at,
            0 AS revenue
           FROM (public.restaurants r
             JOIN public.ordrs o ON ((r.id = o.restaurant_id)))
          WHERE (o.created_at >= (CURRENT_DATE - '30 days'::interval))) combined_data
  GROUP BY (date_trunc('day'::text, created_at)), (date_trunc('week'::text, created_at)), (date_trunc('month'::text, created_at))
  WITH NO DATA;


--
-- Name: tablesettings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tablesettings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tablesettings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tablesettings_id_seq OWNED BY public.tablesettings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    typs integer,
    archived boolean DEFAULT false
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
-- Name: taxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taxes (
    id bigint NOT NULL,
    name character varying,
    taxtype integer,
    taxpercentage double precision,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    archived boolean DEFAULT false,
    status integer DEFAULT 0
);


--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taxes_id_seq OWNED BY public.taxes.id;


--
-- Name: testimonials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.testimonials (
    id bigint NOT NULL,
    sequence integer,
    status integer,
    testimonial character varying,
    user_id bigint NOT NULL,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: testimonials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.testimonials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: testimonials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.testimonials_id_seq OWNED BY public.testimonials.id;


--
-- Name: tips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tips (
    id bigint NOT NULL,
    percentage double precision,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived boolean DEFAULT false,
    sequence integer,
    status integer DEFAULT 0
);


--
-- Name: tips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tips_id_seq OWNED BY public.tips.id;


--
-- Name: tracks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracks (
    id bigint NOT NULL,
    externalid character varying,
    name character varying,
    description text,
    image character varying,
    sequence integer,
    restaurant_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    artist character varying,
    explicit boolean,
    is_playable boolean,
    status integer
);


--
-- Name: tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracks_id_seq OWNED BY public.tracks.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    session_id character varying NOT NULL,
    resource_type character varying,
    resource_id bigint,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    last_activity_at timestamp(6) without time zone,
    metadata json DEFAULT '{}'::json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: userplans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.userplans (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: userplans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.userplans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: userplans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.userplans_id_seq OWNED BY public.userplans.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: video_analytics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_analytics (
    id bigint NOT NULL,
    video_id character varying NOT NULL,
    session_id character varying,
    event_type character varying NOT NULL,
    timestamp_seconds integer,
    ip_address inet,
    user_agent text,
    referrer character varying,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: video_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.video_analytics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: video_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.video_analytics_id_seq OWNED BY public.video_analytics.id;


--
-- Name: voice_commands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voice_commands (
    id bigint NOT NULL,
    smartmenu_id bigint NOT NULL,
    session_id character varying NOT NULL,
    status character varying DEFAULT 'queued'::character varying NOT NULL,
    locale character varying,
    transcript text,
    intent jsonb,
    result jsonb,
    error_message text,
    context jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: voice_commands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.voice_commands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: voice_commands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.voice_commands_id_seq OWNED BY public.voice_commands.id;


--
-- Name: whiskey_flights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.whiskey_flights (
    id bigint NOT NULL,
    menu_id bigint NOT NULL,
    theme_key character varying NOT NULL,
    title character varying NOT NULL,
    narrative text,
    items jsonb DEFAULT '[]'::jsonb NOT NULL,
    source character varying DEFAULT 'ai'::character varying NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    total_price double precision,
    custom_price double precision,
    generated_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: whiskey_flights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.whiskey_flights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: whiskey_flights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.whiskey_flights_id_seq OWNED BY public.whiskey_flights.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: admin_jwt_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_jwt_tokens ALTER COLUMN id SET DEFAULT nextval('public.admin_jwt_tokens_id_seq'::regclass);


--
-- Name: alcohol_order_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_order_events ALTER COLUMN id SET DEFAULT nextval('public.alcohol_order_events_id_seq'::regclass);


--
-- Name: alcohol_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_policies ALTER COLUMN id SET DEFAULT nextval('public.alcohol_policies_id_seq'::regclass);


--
-- Name: allergyns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allergyns ALTER COLUMN id SET DEFAULT nextval('public.allergyns_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: beverage_pipeline_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beverage_pipeline_runs ALTER COLUMN id SET DEFAULT nextval('public.beverage_pipeline_runs_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: crawl_source_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crawl_source_rules ALTER COLUMN id SET DEFAULT nextval('public.crawl_source_rules_id_seq'::regclass);


--
-- Name: crm_email_sends id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_email_sends ALTER COLUMN id SET DEFAULT nextval('public.crm_email_sends_id_seq'::regclass);


--
-- Name: crm_lead_audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_audits ALTER COLUMN id SET DEFAULT nextval('public.crm_lead_audits_id_seq'::regclass);


--
-- Name: crm_lead_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_notes ALTER COLUMN id SET DEFAULT nextval('public.crm_lead_notes_id_seq'::regclass);


--
-- Name: crm_leads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_leads ALTER COLUMN id SET DEFAULT nextval('public.crm_leads_id_seq'::regclass);


--
-- Name: demo_bookings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demo_bookings ALTER COLUMN id SET DEFAULT nextval('public.demo_bookings_id_seq'::regclass);


--
-- Name: dining_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dining_sessions ALTER COLUMN id SET DEFAULT nextval('public.dining_sessions_id_seq'::regclass);


--
-- Name: discovered_restaurants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovered_restaurants ALTER COLUMN id SET DEFAULT nextval('public.discovered_restaurants_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- Name: explore_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.explore_pages ALTER COLUMN id SET DEFAULT nextval('public.explore_pages_id_seq'::regclass);


--
-- Name: features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.features ALTER COLUMN id SET DEFAULT nextval('public.features_id_seq'::regclass);


--
-- Name: features_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.features_plans ALTER COLUMN id SET DEFAULT nextval('public.features_plans_id_seq'::regclass);


--
-- Name: flavor_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flavor_profiles ALTER COLUMN id SET DEFAULT nextval('public.flavor_profiles_id_seq'::regclass);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: friendly_id_slugs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs ALTER COLUMN id SET DEFAULT nextval('public.friendly_id_slugs_id_seq'::regclass);


--
-- Name: genimages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genimages ALTER COLUMN id SET DEFAULT nextval('public.genimages_id_seq'::regclass);


--
-- Name: hero_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hero_images ALTER COLUMN id SET DEFAULT nextval('public.hero_images_id_seq'::regclass);


--
-- Name: impersonation_audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_audits ALTER COLUMN id SET DEFAULT nextval('public.impersonation_audits_id_seq'::regclass);


--
-- Name: ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients ALTER COLUMN id SET DEFAULT nextval('public.ingredients_id_seq'::regclass);


--
-- Name: inventories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories ALTER COLUMN id SET DEFAULT nextval('public.inventories_id_seq'::regclass);


--
-- Name: jwt_token_usage_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_token_usage_logs ALTER COLUMN id SET DEFAULT nextval('public.jwt_token_usage_logs_id_seq'::regclass);


--
-- Name: ledger_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_events ALTER COLUMN id SET DEFAULT nextval('public.ledger_events_id_seq'::regclass);


--
-- Name: local_guides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.local_guides ALTER COLUMN id SET DEFAULT nextval('public.local_guides_id_seq'::regclass);


--
-- Name: marketing_qr_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes ALTER COLUMN id SET DEFAULT nextval('public.marketing_qr_codes_id_seq'::regclass);


--
-- Name: memory_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_metrics ALTER COLUMN id SET DEFAULT nextval('public.memory_metrics_id_seq'::regclass);


--
-- Name: menu_edit_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_edit_sessions ALTER COLUMN id SET DEFAULT nextval('public.menu_edit_sessions_id_seq'::regclass);


--
-- Name: menu_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_imports ALTER COLUMN id SET DEFAULT nextval('public.menu_imports_id_seq'::regclass);


--
-- Name: menu_item_product_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_item_product_links ALTER COLUMN id SET DEFAULT nextval('public.menu_item_product_links_id_seq'::regclass);


--
-- Name: menu_item_search_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_item_search_documents ALTER COLUMN id SET DEFAULT nextval('public.menu_item_search_documents_id_seq'::regclass);


--
-- Name: menu_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_items ALTER COLUMN id SET DEFAULT nextval('public.menu_items_id_seq'::regclass);


--
-- Name: menu_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sections ALTER COLUMN id SET DEFAULT nextval('public.menu_sections_id_seq'::regclass);


--
-- Name: menu_source_change_reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_source_change_reviews ALTER COLUMN id SET DEFAULT nextval('public.menu_source_change_reviews_id_seq'::regclass);


--
-- Name: menu_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sources ALTER COLUMN id SET DEFAULT nextval('public.menu_sources_id_seq'::regclass);


--
-- Name: menu_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_versions ALTER COLUMN id SET DEFAULT nextval('public.menu_versions_id_seq'::regclass);


--
-- Name: menuavailabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuavailabilities ALTER COLUMN id SET DEFAULT nextval('public.menuavailabilities_id_seq'::regclass);


--
-- Name: menuitem_allergyn_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_allergyn_mappings ALTER COLUMN id SET DEFAULT nextval('public.menuitem_allergyn_mappings_id_seq'::regclass);


--
-- Name: menuitem_costs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_costs ALTER COLUMN id SET DEFAULT nextval('public.menuitem_costs_id_seq'::regclass);


--
-- Name: menuitem_ingredient_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_mappings ALTER COLUMN id SET DEFAULT nextval('public.menuitem_ingredient_mappings_id_seq'::regclass);


--
-- Name: menuitem_ingredient_quantities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_quantities ALTER COLUMN id SET DEFAULT nextval('public.menuitem_ingredient_quantities_id_seq'::regclass);


--
-- Name: menuitem_size_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_size_mappings ALTER COLUMN id SET DEFAULT nextval('public.menuitem_size_mappings_id_seq'::regclass);


--
-- Name: menuitem_tag_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_tag_mappings ALTER COLUMN id SET DEFAULT nextval('public.menuitem_tag_mappings_id_seq'::regclass);


--
-- Name: menuitemlocales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitemlocales ALTER COLUMN id SET DEFAULT nextval('public.menuitemlocales_id_seq'::regclass);


--
-- Name: menuitems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitems ALTER COLUMN id SET DEFAULT nextval('public.menuitems_id_seq'::regclass);


--
-- Name: menulocales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menulocales ALTER COLUMN id SET DEFAULT nextval('public.menulocales_id_seq'::regclass);


--
-- Name: menuparticipants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuparticipants ALTER COLUMN id SET DEFAULT nextval('public.menuparticipants_id_seq'::regclass);


--
-- Name: menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus ALTER COLUMN id SET DEFAULT nextval('public.menus_id_seq'::regclass);


--
-- Name: menusectionlocales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menusectionlocales ALTER COLUMN id SET DEFAULT nextval('public.menusectionlocales_id_seq'::regclass);


--
-- Name: menusections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menusections ALTER COLUMN id SET DEFAULT nextval('public.menusections_id_seq'::regclass);


--
-- Name: metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metrics ALTER COLUMN id SET DEFAULT nextval('public.metrics_id_seq'::regclass);


--
-- Name: noticed_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticed_events ALTER COLUMN id SET DEFAULT nextval('public.noticed_events_id_seq'::regclass);


--
-- Name: noticed_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticed_notifications ALTER COLUMN id SET DEFAULT nextval('public.noticed_notifications_id_seq'::regclass);


--
-- Name: ocr_menu_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_imports ALTER COLUMN id SET DEFAULT nextval('public.ocr_menu_imports_id_seq'::regclass);


--
-- Name: ocr_menu_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_items ALTER COLUMN id SET DEFAULT nextval('public.ocr_menu_items_id_seq'::regclass);


--
-- Name: ocr_menu_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_sections ALTER COLUMN id SET DEFAULT nextval('public.ocr_menu_sections_id_seq'::regclass);


--
-- Name: old_passwords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.old_passwords ALTER COLUMN id SET DEFAULT nextval('public.old_passwords_id_seq'::regclass);


--
-- Name: onboarding_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onboarding_sessions ALTER COLUMN id SET DEFAULT nextval('public.onboarding_sessions_id_seq'::regclass);


--
-- Name: order_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_events ALTER COLUMN id SET DEFAULT nextval('public.order_events_id_seq'::regclass);


--
-- Name: ordr_split_item_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_item_assignments ALTER COLUMN id SET DEFAULT nextval('public.ordr_split_item_assignments_id_seq'::regclass);


--
-- Name: ordr_split_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_payments ALTER COLUMN id SET DEFAULT nextval('public.ordr_split_payments_id_seq'::regclass);


--
-- Name: ordr_split_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_plans ALTER COLUMN id SET DEFAULT nextval('public.ordr_split_plans_id_seq'::regclass);


--
-- Name: ordr_station_tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_station_tickets ALTER COLUMN id SET DEFAULT nextval('public.ordr_station_tickets_id_seq'::regclass);


--
-- Name: ordractions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordractions ALTER COLUMN id SET DEFAULT nextval('public.ordractions_id_seq'::regclass);


--
-- Name: ordritemnotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritemnotes ALTER COLUMN id SET DEFAULT nextval('public.ordritemnotes_id_seq'::regclass);


--
-- Name: ordritems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritems ALTER COLUMN id SET DEFAULT nextval('public.ordritems_id_seq'::regclass);


--
-- Name: ordrnotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrnotes ALTER COLUMN id SET DEFAULT nextval('public.ordrnotes_id_seq'::regclass);


--
-- Name: ordrparticipant_allergyn_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipant_allergyn_filters ALTER COLUMN id SET DEFAULT nextval('public.ordrparticipant_allergyn_filters_id_seq'::regclass);


--
-- Name: ordrparticipants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipants ALTER COLUMN id SET DEFAULT nextval('public.ordrparticipants_id_seq'::regclass);


--
-- Name: pairing_recommendations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pairing_recommendations ALTER COLUMN id SET DEFAULT nextval('public.pairing_recommendations_id_seq'::regclass);


--
-- Name: pay_charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_charges ALTER COLUMN id SET DEFAULT nextval('public.pay_charges_id_seq'::regclass);


--
-- Name: pay_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_customers ALTER COLUMN id SET DEFAULT nextval('public.pay_customers_id_seq'::regclass);


--
-- Name: pay_merchants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_merchants ALTER COLUMN id SET DEFAULT nextval('public.pay_merchants_id_seq'::regclass);


--
-- Name: pay_payment_methods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_payment_methods ALTER COLUMN id SET DEFAULT nextval('public.pay_payment_methods_id_seq'::regclass);


--
-- Name: pay_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.pay_subscriptions_id_seq'::regclass);


--
-- Name: pay_webhooks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_webhooks ALTER COLUMN id SET DEFAULT nextval('public.pay_webhooks_id_seq'::regclass);


--
-- Name: payment_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempts ALTER COLUMN id SET DEFAULT nextval('public.payment_attempts_id_seq'::regclass);


--
-- Name: payment_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_profiles ALTER COLUMN id SET DEFAULT nextval('public.payment_profiles_id_seq'::regclass);


--
-- Name: payment_refunds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_refunds ALTER COLUMN id SET DEFAULT nextval('public.payment_refunds_id_seq'::regclass);


--
-- Name: performance_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_metrics ALTER COLUMN id SET DEFAULT nextval('public.performance_metrics_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: product_enrichments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichments ALTER COLUMN id SET DEFAULT nextval('public.product_enrichments_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: profit_margin_targets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_margin_targets ALTER COLUMN id SET DEFAULT nextval('public.profit_margin_targets_id_seq'::regclass);


--
-- Name: provider_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_accounts ALTER COLUMN id SET DEFAULT nextval('public.provider_accounts_id_seq'::regclass);


--
-- Name: push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.push_subscriptions_id_seq'::regclass);


--
-- Name: receipt_deliveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_deliveries ALTER COLUMN id SET DEFAULT nextval('public.receipt_deliveries_id_seq'::regclass);


--
-- Name: resource_locks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_locks ALTER COLUMN id SET DEFAULT nextval('public.resource_locks_id_seq'::regclass);


--
-- Name: restaurant_claim_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claim_requests ALTER COLUMN id SET DEFAULT nextval('public.restaurant_claim_requests_id_seq'::regclass);


--
-- Name: restaurant_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_menus ALTER COLUMN id SET DEFAULT nextval('public.restaurant_menus_id_seq'::regclass);


--
-- Name: restaurant_onboardings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_onboardings ALTER COLUMN id SET DEFAULT nextval('public.restaurant_onboardings_id_seq'::regclass);


--
-- Name: restaurant_removal_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_removal_requests ALTER COLUMN id SET DEFAULT nextval('public.restaurant_removal_requests_id_seq'::regclass);


--
-- Name: restaurant_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.restaurant_subscriptions_id_seq'::regclass);


--
-- Name: restaurantavailabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantavailabilities ALTER COLUMN id SET DEFAULT nextval('public.restaurantavailabilities_id_seq'::regclass);


--
-- Name: restaurantlocales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantlocales ALTER COLUMN id SET DEFAULT nextval('public.restaurantlocales_id_seq'::regclass);


--
-- Name: restaurants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurants ALTER COLUMN id SET DEFAULT nextval('public.restaurants_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: similar_product_recommendations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.similar_product_recommendations ALTER COLUMN id SET DEFAULT nextval('public.similar_product_recommendations_id_seq'::regclass);


--
-- Name: sizes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sizes ALTER COLUMN id SET DEFAULT nextval('public.sizes_id_seq'::regclass);


--
-- Name: slow_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slow_queries ALTER COLUMN id SET DEFAULT nextval('public.slow_queries_id_seq'::regclass);


--
-- Name: smartmenus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smartmenus ALTER COLUMN id SET DEFAULT nextval('public.smartmenus_id_seq'::regclass);


--
-- Name: staff_invitations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitations ALTER COLUMN id SET DEFAULT nextval('public.staff_invitations_id_seq'::regclass);


--
-- Name: tablesettings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tablesettings ALTER COLUMN id SET DEFAULT nextval('public.tablesettings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: taxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes ALTER COLUMN id SET DEFAULT nextval('public.taxes_id_seq'::regclass);


--
-- Name: testimonials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.testimonials ALTER COLUMN id SET DEFAULT nextval('public.testimonials_id_seq'::regclass);


--
-- Name: tips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tips ALTER COLUMN id SET DEFAULT nextval('public.tips_id_seq'::regclass);


--
-- Name: tracks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracks ALTER COLUMN id SET DEFAULT nextval('public.tracks_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: userplans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userplans ALTER COLUMN id SET DEFAULT nextval('public.userplans_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: video_analytics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_analytics ALTER COLUMN id SET DEFAULT nextval('public.video_analytics_id_seq'::regclass);


--
-- Name: voice_commands id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_commands ALTER COLUMN id SET DEFAULT nextval('public.voice_commands_id_seq'::regclass);


--
-- Name: whiskey_flights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whiskey_flights ALTER COLUMN id SET DEFAULT nextval('public.whiskey_flights_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: admin_jwt_tokens admin_jwt_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_jwt_tokens
    ADD CONSTRAINT admin_jwt_tokens_pkey PRIMARY KEY (id);


--
-- Name: alcohol_order_events alcohol_order_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_order_events
    ADD CONSTRAINT alcohol_order_events_pkey PRIMARY KEY (id);


--
-- Name: alcohol_policies alcohol_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_policies
    ADD CONSTRAINT alcohol_policies_pkey PRIMARY KEY (id);


--
-- Name: allergyns allergyns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allergyns
    ADD CONSTRAINT allergyns_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: beverage_pipeline_runs beverage_pipeline_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beverage_pipeline_runs
    ADD CONSTRAINT beverage_pipeline_runs_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: crawl_source_rules crawl_source_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crawl_source_rules
    ADD CONSTRAINT crawl_source_rules_pkey PRIMARY KEY (id);


--
-- Name: crm_email_sends crm_email_sends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_email_sends
    ADD CONSTRAINT crm_email_sends_pkey PRIMARY KEY (id);


--
-- Name: crm_lead_audits crm_lead_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_audits
    ADD CONSTRAINT crm_lead_audits_pkey PRIMARY KEY (id);


--
-- Name: crm_lead_notes crm_lead_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_notes
    ADD CONSTRAINT crm_lead_notes_pkey PRIMARY KEY (id);


--
-- Name: crm_leads crm_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_leads
    ADD CONSTRAINT crm_leads_pkey PRIMARY KEY (id);


--
-- Name: demo_bookings demo_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demo_bookings
    ADD CONSTRAINT demo_bookings_pkey PRIMARY KEY (id);


--
-- Name: dining_sessions dining_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dining_sessions
    ADD CONSTRAINT dining_sessions_pkey PRIMARY KEY (id);


--
-- Name: discovered_restaurants discovered_restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovered_restaurants
    ADD CONSTRAINT discovered_restaurants_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: explore_pages explore_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.explore_pages
    ADD CONSTRAINT explore_pages_pkey PRIMARY KEY (id);


--
-- Name: features features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);


--
-- Name: features_plans features_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.features_plans
    ADD CONSTRAINT features_plans_pkey PRIMARY KEY (id);


--
-- Name: flavor_profiles flavor_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flavor_profiles
    ADD CONSTRAINT flavor_profiles_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: friendly_id_slugs friendly_id_slugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs
    ADD CONSTRAINT friendly_id_slugs_pkey PRIMARY KEY (id);


--
-- Name: genimages genimages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genimages
    ADD CONSTRAINT genimages_pkey PRIMARY KEY (id);


--
-- Name: hero_images hero_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hero_images
    ADD CONSTRAINT hero_images_pkey PRIMARY KEY (id);


--
-- Name: impersonation_audits impersonation_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_audits
    ADD CONSTRAINT impersonation_audits_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: inventories inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);


--
-- Name: jwt_token_usage_logs jwt_token_usage_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_token_usage_logs
    ADD CONSTRAINT jwt_token_usage_logs_pkey PRIMARY KEY (id);


--
-- Name: ledger_events ledger_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_events
    ADD CONSTRAINT ledger_events_pkey PRIMARY KEY (id);


--
-- Name: local_guides local_guides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.local_guides
    ADD CONSTRAINT local_guides_pkey PRIMARY KEY (id);


--
-- Name: marketing_qr_codes marketing_qr_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes
    ADD CONSTRAINT marketing_qr_codes_pkey PRIMARY KEY (id);


--
-- Name: memory_metrics memory_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_metrics
    ADD CONSTRAINT memory_metrics_pkey PRIMARY KEY (id);


--
-- Name: menu_edit_sessions menu_edit_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_edit_sessions
    ADD CONSTRAINT menu_edit_sessions_pkey PRIMARY KEY (id);


--
-- Name: menu_imports menu_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_imports
    ADD CONSTRAINT menu_imports_pkey PRIMARY KEY (id);


--
-- Name: menu_item_product_links menu_item_product_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_item_product_links
    ADD CONSTRAINT menu_item_product_links_pkey PRIMARY KEY (id);


--
-- Name: menu_item_search_documents menu_item_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_item_search_documents
    ADD CONSTRAINT menu_item_search_documents_pkey PRIMARY KEY (id);


--
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: menu_sections menu_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sections
    ADD CONSTRAINT menu_sections_pkey PRIMARY KEY (id);


--
-- Name: menu_source_change_reviews menu_source_change_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_source_change_reviews
    ADD CONSTRAINT menu_source_change_reviews_pkey PRIMARY KEY (id);


--
-- Name: menu_sources menu_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sources
    ADD CONSTRAINT menu_sources_pkey PRIMARY KEY (id);


--
-- Name: menu_versions menu_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_versions
    ADD CONSTRAINT menu_versions_pkey PRIMARY KEY (id);


--
-- Name: menuavailabilities menuavailabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuavailabilities
    ADD CONSTRAINT menuavailabilities_pkey PRIMARY KEY (id);


--
-- Name: menuitem_allergyn_mappings menuitem_allergyn_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_allergyn_mappings
    ADD CONSTRAINT menuitem_allergyn_mappings_pkey PRIMARY KEY (id);


--
-- Name: menuitem_costs menuitem_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_costs
    ADD CONSTRAINT menuitem_costs_pkey PRIMARY KEY (id);


--
-- Name: menuitem_ingredient_mappings menuitem_ingredient_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_mappings
    ADD CONSTRAINT menuitem_ingredient_mappings_pkey PRIMARY KEY (id);


--
-- Name: menuitem_ingredient_quantities menuitem_ingredient_quantities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_quantities
    ADD CONSTRAINT menuitem_ingredient_quantities_pkey PRIMARY KEY (id);


--
-- Name: menuitem_size_mappings menuitem_size_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_size_mappings
    ADD CONSTRAINT menuitem_size_mappings_pkey PRIMARY KEY (id);


--
-- Name: menuitem_tag_mappings menuitem_tag_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_tag_mappings
    ADD CONSTRAINT menuitem_tag_mappings_pkey PRIMARY KEY (id);


--
-- Name: menuitemlocales menuitemlocales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitemlocales
    ADD CONSTRAINT menuitemlocales_pkey PRIMARY KEY (id);


--
-- Name: menuitems menuitems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitems
    ADD CONSTRAINT menuitems_pkey PRIMARY KEY (id);


--
-- Name: menulocales menulocales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menulocales
    ADD CONSTRAINT menulocales_pkey PRIMARY KEY (id);


--
-- Name: menuparticipants menuparticipants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuparticipants
    ADD CONSTRAINT menuparticipants_pkey PRIMARY KEY (id);


--
-- Name: menus menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: menusectionlocales menusectionlocales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menusectionlocales
    ADD CONSTRAINT menusectionlocales_pkey PRIMARY KEY (id);


--
-- Name: menusections menusections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menusections
    ADD CONSTRAINT menusections_pkey PRIMARY KEY (id);


--
-- Name: metrics metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metrics
    ADD CONSTRAINT metrics_pkey PRIMARY KEY (id);


--
-- Name: noticed_events noticed_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticed_events
    ADD CONSTRAINT noticed_events_pkey PRIMARY KEY (id);


--
-- Name: noticed_notifications noticed_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticed_notifications
    ADD CONSTRAINT noticed_notifications_pkey PRIMARY KEY (id);


--
-- Name: ocr_menu_imports ocr_menu_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_imports
    ADD CONSTRAINT ocr_menu_imports_pkey PRIMARY KEY (id);


--
-- Name: ocr_menu_items ocr_menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_items
    ADD CONSTRAINT ocr_menu_items_pkey PRIMARY KEY (id);


--
-- Name: ocr_menu_sections ocr_menu_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_sections
    ADD CONSTRAINT ocr_menu_sections_pkey PRIMARY KEY (id);


--
-- Name: old_passwords old_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.old_passwords
    ADD CONSTRAINT old_passwords_pkey PRIMARY KEY (id);


--
-- Name: onboarding_sessions onboarding_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onboarding_sessions
    ADD CONSTRAINT onboarding_sessions_pkey PRIMARY KEY (id);


--
-- Name: order_events order_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_events
    ADD CONSTRAINT order_events_pkey PRIMARY KEY (id);


--
-- Name: ordr_split_item_assignments ordr_split_item_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_item_assignments
    ADD CONSTRAINT ordr_split_item_assignments_pkey PRIMARY KEY (id);


--
-- Name: ordr_split_payments ordr_split_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_payments
    ADD CONSTRAINT ordr_split_payments_pkey PRIMARY KEY (id);


--
-- Name: ordr_split_plans ordr_split_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_plans
    ADD CONSTRAINT ordr_split_plans_pkey PRIMARY KEY (id);


--
-- Name: ordr_station_tickets ordr_station_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_station_tickets
    ADD CONSTRAINT ordr_station_tickets_pkey PRIMARY KEY (id);


--
-- Name: ordractions ordractions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordractions
    ADD CONSTRAINT ordractions_pkey PRIMARY KEY (id);


--
-- Name: ordritemnotes ordritemnotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritemnotes
    ADD CONSTRAINT ordritemnotes_pkey PRIMARY KEY (id);


--
-- Name: ordritems ordritems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritems
    ADD CONSTRAINT ordritems_pkey PRIMARY KEY (id);


--
-- Name: ordrnotes ordrnotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrnotes
    ADD CONSTRAINT ordrnotes_pkey PRIMARY KEY (id);


--
-- Name: ordrparticipant_allergyn_filters ordrparticipant_allergyn_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipant_allergyn_filters
    ADD CONSTRAINT ordrparticipant_allergyn_filters_pkey PRIMARY KEY (id);


--
-- Name: ordrparticipants ordrparticipants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipants
    ADD CONSTRAINT ordrparticipants_pkey PRIMARY KEY (id);


--
-- Name: ordrs ordrs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrs
    ADD CONSTRAINT ordrs_pkey PRIMARY KEY (id);


--
-- Name: pairing_recommendations pairing_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pairing_recommendations
    ADD CONSTRAINT pairing_recommendations_pkey PRIMARY KEY (id);


--
-- Name: pay_charges pay_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_charges
    ADD CONSTRAINT pay_charges_pkey PRIMARY KEY (id);


--
-- Name: pay_customers pay_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_customers
    ADD CONSTRAINT pay_customers_pkey PRIMARY KEY (id);


--
-- Name: pay_merchants pay_merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_merchants
    ADD CONSTRAINT pay_merchants_pkey PRIMARY KEY (id);


--
-- Name: pay_payment_methods pay_payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_payment_methods
    ADD CONSTRAINT pay_payment_methods_pkey PRIMARY KEY (id);


--
-- Name: pay_subscriptions pay_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_subscriptions
    ADD CONSTRAINT pay_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: pay_webhooks pay_webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_webhooks
    ADD CONSTRAINT pay_webhooks_pkey PRIMARY KEY (id);


--
-- Name: payment_attempts payment_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempts
    ADD CONSTRAINT payment_attempts_pkey PRIMARY KEY (id);


--
-- Name: payment_profiles payment_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_profiles
    ADD CONSTRAINT payment_profiles_pkey PRIMARY KEY (id);


--
-- Name: payment_refunds payment_refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_refunds
    ADD CONSTRAINT payment_refunds_pkey PRIMARY KEY (id);


--
-- Name: performance_metrics performance_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_metrics
    ADD CONSTRAINT performance_metrics_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: product_enrichments product_enrichments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichments
    ADD CONSTRAINT product_enrichments_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: profit_margin_targets profit_margin_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_margin_targets
    ADD CONSTRAINT profit_margin_targets_pkey PRIMARY KEY (id);


--
-- Name: provider_accounts provider_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_accounts
    ADD CONSTRAINT provider_accounts_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: receipt_deliveries receipt_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_deliveries
    ADD CONSTRAINT receipt_deliveries_pkey PRIMARY KEY (id);


--
-- Name: resource_locks resource_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_locks
    ADD CONSTRAINT resource_locks_pkey PRIMARY KEY (id);


--
-- Name: restaurant_claim_requests restaurant_claim_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claim_requests
    ADD CONSTRAINT restaurant_claim_requests_pkey PRIMARY KEY (id);


--
-- Name: restaurant_menus restaurant_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_menus
    ADD CONSTRAINT restaurant_menus_pkey PRIMARY KEY (id);


--
-- Name: restaurant_onboardings restaurant_onboardings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_onboardings
    ADD CONSTRAINT restaurant_onboardings_pkey PRIMARY KEY (id);


--
-- Name: restaurant_removal_requests restaurant_removal_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_removal_requests
    ADD CONSTRAINT restaurant_removal_requests_pkey PRIMARY KEY (id);


--
-- Name: restaurant_subscriptions restaurant_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_subscriptions
    ADD CONSTRAINT restaurant_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: restaurantavailabilities restaurantavailabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantavailabilities
    ADD CONSTRAINT restaurantavailabilities_pkey PRIMARY KEY (id);


--
-- Name: restaurantlocales restaurantlocales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantlocales
    ADD CONSTRAINT restaurantlocales_pkey PRIMARY KEY (id);


--
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: similar_product_recommendations similar_product_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.similar_product_recommendations
    ADD CONSTRAINT similar_product_recommendations_pkey PRIMARY KEY (id);


--
-- Name: sizes sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sizes
    ADD CONSTRAINT sizes_pkey PRIMARY KEY (id);


--
-- Name: slow_queries slow_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slow_queries
    ADD CONSTRAINT slow_queries_pkey PRIMARY KEY (id);


--
-- Name: smartmenus smartmenus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smartmenus
    ADD CONSTRAINT smartmenus_pkey PRIMARY KEY (id);


--
-- Name: staff_invitations staff_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitations
    ADD CONSTRAINT staff_invitations_pkey PRIMARY KEY (id);


--
-- Name: tablesettings tablesettings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tablesettings
    ADD CONSTRAINT tablesettings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: testimonials testimonials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.testimonials
    ADD CONSTRAINT testimonials_pkey PRIMARY KEY (id);


--
-- Name: tips tips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tips
    ADD CONSTRAINT tips_pkey PRIMARY KEY (id);


--
-- Name: tracks tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: userplans userplans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userplans
    ADD CONSTRAINT userplans_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: video_analytics video_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_analytics
    ADD CONSTRAINT video_analytics_pkey PRIMARY KEY (id);


--
-- Name: voice_commands voice_commands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_commands
    ADD CONSTRAINT voice_commands_pkey PRIMARY KEY (id);


--
-- Name: whiskey_flights whiskey_flights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whiskey_flights
    ADD CONSTRAINT whiskey_flights_pkey PRIMARY KEY (id);


--
-- Name: idx_effective_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_effective_dates ON public.profit_margin_targets USING btree (effective_from, effective_to);


--
-- Name: idx_explore_pages_unique_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_explore_pages_unique_path ON public.explore_pages USING btree (country_slug, city_slug, category_slug);


--
-- Name: idx_flavor_profiles_profilable; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_flavor_profiles_profilable ON public.flavor_profiles USING btree (profilable_type, profilable_id);


--
-- Name: idx_menu_item_search_docs_embedding_ivfflat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_item_search_docs_embedding_ivfflat ON public.menu_item_search_documents USING ivfflat (embedding public.vector_cosine_ops) WITH (lists='50');


--
-- Name: idx_menu_item_search_docs_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_item_search_docs_tsv ON public.menu_item_search_documents USING gin (document_tsv);


--
-- Name: idx_menu_item_search_docs_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_menu_item_search_docs_unique ON public.menu_item_search_documents USING btree (menu_id, menuitem_id, locale);


--
-- Name: idx_menu_performance_popularity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_performance_popularity ON public.menu_performance_mv USING btree (restaurant_id, month, popularity_rank);


--
-- Name: idx_menu_performance_restaurant_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_performance_restaurant_date ON public.menu_performance_mv USING btree (restaurant_id, date);


--
-- Name: idx_menu_performance_restaurant_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_performance_restaurant_month ON public.menu_performance_mv USING btree (restaurant_id, month);


--
-- Name: idx_menu_performance_revenue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_performance_revenue ON public.menu_performance_mv USING btree (restaurant_id, month, revenue_rank);


--
-- Name: idx_menuitem_ingredient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menuitem_ingredient ON public.menuitem_ingredient_quantities USING btree (menuitem_id, ingredient_id);


--
-- Name: idx_on_city_name_status_discovered_at_524af6544b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_city_name_status_discovered_at_524af6544b ON public.discovered_restaurants USING btree (city_name, status, discovered_at);


--
-- Name: idx_on_impersonated_user_id_started_at_39d81181ba; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_impersonated_user_id_started_at_39d81181ba ON public.impersonation_audits USING btree (impersonated_user_id, started_at);


--
-- Name: idx_on_recommended_product_id_d9294a2c90; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_recommended_product_id_d9294a2c90 ON public.similar_product_recommendations USING btree (recommended_product_id);


--
-- Name: idx_on_smartmenu_id_session_id_created_at_dc50bab09c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_smartmenu_id_session_id_created_at_dc50bab09c ON public.voice_commands USING btree (smartmenu_id, session_id, created_at);


--
-- Name: idx_pairings_drink_food; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_pairings_drink_food ON public.pairing_recommendations USING btree (drink_menuitem_id, food_menuitem_id);


--
-- Name: idx_restaurant_analytics_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restaurant_analytics_date ON public.restaurant_analytics_mv USING btree (date);


--
-- Name: idx_restaurant_analytics_restaurant_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restaurant_analytics_restaurant_date ON public.restaurant_analytics_mv USING btree (restaurant_id, date);


--
-- Name: idx_restaurant_analytics_restaurant_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restaurant_analytics_restaurant_month ON public.restaurant_analytics_mv USING btree (restaurant_id, month);


--
-- Name: idx_restaurants_geo_preview; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restaurants_geo_preview ON public.restaurants USING btree (city, country, preview_enabled);


--
-- Name: idx_restaurants_preview_claim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_restaurants_preview_claim ON public.restaurants USING btree (preview_enabled, claim_status);


--
-- Name: idx_similar_products_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_similar_products_pair ON public.similar_product_recommendations USING btree (product_id, recommended_product_id);


--
-- Name: idx_split_item_assignments_on_payment_and_item; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_split_item_assignments_on_payment_and_item ON public.ordr_split_item_assignments USING btree (ordr_split_payment_id, ordritem_id);


--
-- Name: idx_split_item_assignments_on_plan_and_item; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_split_item_assignments_on_plan_and_item ON public.ordr_split_item_assignments USING btree (ordr_split_plan_id, ordritem_id);


--
-- Name: idx_staff_invitations_restaurant_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_invitations_restaurant_email ON public.staff_invitations USING btree (restaurant_id, email);


--
-- Name: idx_system_analytics_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_analytics_date ON public.system_analytics_mv USING btree (date);


--
-- Name: idx_system_analytics_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_analytics_month ON public.system_analytics_mv USING btree (month);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_admin_jwt_tokens_on_admin_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_jwt_tokens_on_admin_user_id ON public.admin_jwt_tokens USING btree (admin_user_id);


--
-- Name: index_admin_jwt_tokens_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_jwt_tokens_on_expires_at ON public.admin_jwt_tokens USING btree (expires_at);


--
-- Name: index_admin_jwt_tokens_on_restaurant_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_jwt_tokens_on_restaurant_active ON public.admin_jwt_tokens USING btree (restaurant_id, revoked_at);


--
-- Name: index_admin_jwt_tokens_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_jwt_tokens_on_restaurant_id ON public.admin_jwt_tokens USING btree (restaurant_id);


--
-- Name: index_admin_jwt_tokens_on_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_jwt_tokens_on_token_hash ON public.admin_jwt_tokens USING btree (token_hash);


--
-- Name: index_alcohol_events_on_ordr_ack; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_events_on_ordr_ack ON public.alcohol_order_events USING btree (ordr_id, age_check_acknowledged);


--
-- Name: index_alcohol_order_events_on_customer_sessionid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_order_events_on_customer_sessionid ON public.alcohol_order_events USING btree (customer_sessionid);


--
-- Name: index_alcohol_order_events_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_order_events_on_employee_id ON public.alcohol_order_events USING btree (employee_id);


--
-- Name: index_alcohol_order_events_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_order_events_on_menuitem_id ON public.alcohol_order_events USING btree (menuitem_id);


--
-- Name: index_alcohol_order_events_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_order_events_on_ordr_id ON public.alcohol_order_events USING btree (ordr_id);


--
-- Name: index_alcohol_order_events_on_ordritem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_order_events_on_ordritem_id ON public.alcohol_order_events USING btree (ordritem_id);


--
-- Name: index_alcohol_order_events_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_order_events_on_restaurant_id ON public.alcohol_order_events USING btree (restaurant_id);


--
-- Name: index_alcohol_policies_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alcohol_policies_on_restaurant_id ON public.alcohol_policies USING btree (restaurant_id);


--
-- Name: index_allergyns_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allergyns_on_restaurant_id ON public.allergyns USING btree (restaurant_id);


--
-- Name: index_allergyns_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allergyns_on_restaurant_status_active ON public.allergyns USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_beverage_pipeline_runs_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beverage_pipeline_runs_on_menu_id ON public.beverage_pipeline_runs USING btree (menu_id);


--
-- Name: index_beverage_pipeline_runs_on_menu_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beverage_pipeline_runs_on_menu_id_and_status ON public.beverage_pipeline_runs USING btree (menu_id, status);


--
-- Name: index_beverage_pipeline_runs_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beverage_pipeline_runs_on_restaurant_id ON public.beverage_pipeline_runs USING btree (restaurant_id);


--
-- Name: index_contacts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_created_at ON public.contacts USING btree (created_at);


--
-- Name: index_contacts_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_email ON public.contacts USING btree (email);


--
-- Name: index_crawl_source_rules_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crawl_source_rules_on_created_by_user_id ON public.crawl_source_rules USING btree (created_by_user_id);


--
-- Name: index_crawl_source_rules_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_crawl_source_rules_on_domain ON public.crawl_source_rules USING btree (domain);


--
-- Name: index_crawl_source_rules_on_rule_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crawl_source_rules_on_rule_type ON public.crawl_source_rules USING btree (rule_type);


--
-- Name: index_crm_email_sends_on_crm_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_email_sends_on_crm_lead_id ON public.crm_email_sends USING btree (crm_lead_id);


--
-- Name: index_crm_email_sends_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_email_sends_on_sender_id ON public.crm_email_sends USING btree (sender_id);


--
-- Name: index_crm_lead_audits_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_lead_audits_on_actor_id ON public.crm_lead_audits USING btree (actor_id);


--
-- Name: index_crm_lead_audits_on_crm_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_lead_audits_on_crm_lead_id ON public.crm_lead_audits USING btree (crm_lead_id);


--
-- Name: index_crm_lead_notes_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_lead_notes_on_author_id ON public.crm_lead_notes USING btree (author_id);


--
-- Name: index_crm_lead_notes_on_crm_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_lead_notes_on_crm_lead_id ON public.crm_lead_notes USING btree (crm_lead_id);


--
-- Name: index_crm_leads_on_assigned_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_leads_on_assigned_to_id ON public.crm_leads USING btree (assigned_to_id);


--
-- Name: index_crm_leads_on_calendly_event_uuid_partial; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_crm_leads_on_calendly_event_uuid_partial ON public.crm_leads USING btree (calendly_event_uuid) WHERE (calendly_event_uuid IS NOT NULL);


--
-- Name: index_crm_leads_on_last_activity_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_leads_on_last_activity_at ON public.crm_leads USING btree (last_activity_at);


--
-- Name: index_crm_leads_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_leads_on_restaurant_id ON public.crm_leads USING btree (restaurant_id);


--
-- Name: index_crm_leads_on_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crm_leads_on_stage ON public.crm_leads USING btree (stage);


--
-- Name: index_demo_bookings_on_conversion_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_demo_bookings_on_conversion_status ON public.demo_bookings USING btree (conversion_status);


--
-- Name: index_demo_bookings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_demo_bookings_on_created_at ON public.demo_bookings USING btree (created_at);


--
-- Name: index_demo_bookings_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_demo_bookings_on_email ON public.demo_bookings USING btree (email);


--
-- Name: index_dining_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dining_sessions_on_expires_at ON public.dining_sessions USING btree (expires_at);


--
-- Name: index_dining_sessions_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dining_sessions_on_restaurant_id ON public.dining_sessions USING btree (restaurant_id);


--
-- Name: index_dining_sessions_on_session_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dining_sessions_on_session_token ON public.dining_sessions USING btree (session_token);


--
-- Name: index_dining_sessions_on_smartmenu_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dining_sessions_on_smartmenu_active ON public.dining_sessions USING btree (smartmenu_id, active);


--
-- Name: index_dining_sessions_on_smartmenu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dining_sessions_on_smartmenu_id ON public.dining_sessions USING btree (smartmenu_id);


--
-- Name: index_dining_sessions_on_tablesetting_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dining_sessions_on_tablesetting_active ON public.dining_sessions USING btree (tablesetting_id, active);


--
-- Name: index_dining_sessions_on_tablesetting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dining_sessions_on_tablesetting_id ON public.dining_sessions USING btree (tablesetting_id);


--
-- Name: index_discovered_restaurants_on_country_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discovered_restaurants_on_country_code ON public.discovered_restaurants USING btree (country_code);


--
-- Name: index_discovered_restaurants_on_google_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discovered_restaurants_on_google_place_id ON public.discovered_restaurants USING btree (google_place_id);


--
-- Name: index_discovered_restaurants_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discovered_restaurants_on_restaurant_id ON public.discovered_restaurants USING btree (restaurant_id);


--
-- Name: index_employees_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_email ON public.employees USING btree (email);


--
-- Name: index_employees_on_restaurant_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_restaurant_created_at ON public.employees USING btree (restaurant_id, created_at);


--
-- Name: index_employees_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_restaurant_id ON public.employees USING btree (restaurant_id);


--
-- Name: index_employees_on_restaurant_role_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_restaurant_role_status ON public.employees USING btree (restaurant_id, role, status) WHERE (archived = false);


--
-- Name: index_employees_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_restaurant_status_active ON public.employees USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_employees_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_user_id ON public.employees USING btree (user_id);


--
-- Name: index_explore_pages_on_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_explore_pages_on_published ON public.explore_pages USING btree (published);


--
-- Name: index_explore_pages_on_restaurant_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_explore_pages_on_restaurant_count ON public.explore_pages USING btree (restaurant_count);


--
-- Name: index_features_plans_on_feature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_features_plans_on_feature_id ON public.features_plans USING btree (feature_id);


--
-- Name: index_features_plans_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_features_plans_on_plan_id ON public.features_plans USING btree (plan_id);


--
-- Name: index_features_plans_on_plan_id_and_feature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_features_plans_on_plan_id_and_feature_id ON public.features_plans USING btree (plan_id, feature_id);


--
-- Name: index_flavor_profiles_on_profilable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flavor_profiles_on_profilable ON public.flavor_profiles USING btree (profilable_type, profilable_id);


--
-- Name: index_flavor_profiles_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flavor_profiles_on_tags ON public.flavor_profiles USING gin (tags);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type ON public.friendly_id_slugs USING btree (slug, sluggable_type);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope ON public.friendly_id_slugs USING btree (slug, sluggable_type, scope);


--
-- Name: index_friendly_id_slugs_on_sluggable_type_and_sluggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_sluggable_type_and_sluggable_id ON public.friendly_id_slugs USING btree (sluggable_type, sluggable_id);


--
-- Name: index_genimages_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genimages_on_menu_id ON public.genimages USING btree (menu_id);


--
-- Name: index_genimages_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genimages_on_menuitem_id ON public.genimages USING btree (menuitem_id);


--
-- Name: index_genimages_on_menusection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genimages_on_menusection_id ON public.genimages USING btree (menusection_id);


--
-- Name: index_genimages_on_prompt_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genimages_on_prompt_fingerprint ON public.genimages USING btree (prompt_fingerprint);


--
-- Name: index_genimages_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genimages_on_restaurant_id ON public.genimages USING btree (restaurant_id);


--
-- Name: index_genimages_on_restaurant_menu_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genimages_on_restaurant_menu_item ON public.genimages USING btree (restaurant_id, menu_id, menuitem_id);


--
-- Name: index_hero_images_on_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hero_images_on_sequence ON public.hero_images USING btree (sequence);


--
-- Name: index_hero_images_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hero_images_on_status ON public.hero_images USING btree (status);


--
-- Name: index_impersonation_audits_on_admin_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_audits_on_admin_user_id ON public.impersonation_audits USING btree (admin_user_id);


--
-- Name: index_impersonation_audits_on_admin_user_id_and_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_audits_on_admin_user_id_and_started_at ON public.impersonation_audits USING btree (admin_user_id, started_at);


--
-- Name: index_impersonation_audits_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_audits_on_expires_at ON public.impersonation_audits USING btree (expires_at);


--
-- Name: index_impersonation_audits_on_impersonated_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impersonation_audits_on_impersonated_user_id ON public.impersonation_audits USING btree (impersonated_user_id);


--
-- Name: index_ingredients_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredients_on_category ON public.ingredients USING btree (category);


--
-- Name: index_ingredients_on_is_shared; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredients_on_is_shared ON public.ingredients USING btree (is_shared);


--
-- Name: index_ingredients_on_parent_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredients_on_parent_ingredient_id ON public.ingredients USING btree (parent_ingredient_id);


--
-- Name: index_ingredients_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredients_on_restaurant_id ON public.ingredients USING btree (restaurant_id);


--
-- Name: index_inventories_on_archived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_archived ON public.inventories USING btree (archived);


--
-- Name: index_inventories_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_menuitem_id ON public.inventories USING btree (menuitem_id);


--
-- Name: index_inventories_on_menuitem_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_menuitem_status_active ON public.inventories USING btree (menuitem_id, status) WHERE (archived = false);


--
-- Name: index_inventories_on_menuitem_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_menuitem_updated_at ON public.inventories USING btree (menuitem_id, updated_at);


--
-- Name: index_inventories_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_status ON public.inventories USING btree (status);


--
-- Name: index_jwt_token_usage_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jwt_token_usage_logs_on_created_at ON public.jwt_token_usage_logs USING btree (created_at);


--
-- Name: index_jwt_token_usage_logs_on_token_and_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jwt_token_usage_logs_on_token_and_time ON public.jwt_token_usage_logs USING btree (jwt_token_id, created_at);


--
-- Name: index_ledger_events_on_entity_type_and_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_events_on_entity_type_and_entity_id ON public.ledger_events USING btree (entity_type, entity_id);


--
-- Name: index_ledger_events_on_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_events_on_occurred_at ON public.ledger_events USING btree (occurred_at);


--
-- Name: index_ledger_events_on_provider_and_provider_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ledger_events_on_provider_and_provider_event_id ON public.ledger_events USING btree (provider, provider_event_id);


--
-- Name: index_local_guides_on_approved_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_local_guides_on_approved_by_user_id ON public.local_guides USING btree (approved_by_user_id);


--
-- Name: index_local_guides_on_city_and_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_local_guides_on_city_and_category ON public.local_guides USING btree (city, category);


--
-- Name: index_local_guides_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_local_guides_on_slug ON public.local_guides USING btree (slug);


--
-- Name: index_local_guides_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_local_guides_on_status ON public.local_guides USING btree (status);


--
-- Name: index_marketing_qr_codes_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marketing_qr_codes_on_created_by_user_id ON public.marketing_qr_codes USING btree (created_by_user_id);


--
-- Name: index_marketing_qr_codes_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marketing_qr_codes_on_restaurant_id ON public.marketing_qr_codes USING btree (restaurant_id);


--
-- Name: index_marketing_qr_codes_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_marketing_qr_codes_on_status ON public.marketing_qr_codes USING btree (status);


--
-- Name: index_marketing_qr_codes_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_marketing_qr_codes_on_token ON public.marketing_qr_codes USING btree (token);


--
-- Name: index_memory_metrics_on_rss_memory_and_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memory_metrics_on_rss_memory_and_timestamp ON public.memory_metrics USING btree (rss_memory, "timestamp");


--
-- Name: index_memory_metrics_on_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memory_metrics_on_timestamp ON public.memory_metrics USING btree ("timestamp");


--
-- Name: index_menu_edit_sessions_on_last_activity_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_edit_sessions_on_last_activity_at ON public.menu_edit_sessions USING btree (last_activity_at);


--
-- Name: index_menu_edit_sessions_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_edit_sessions_on_menu_id ON public.menu_edit_sessions USING btree (menu_id);


--
-- Name: index_menu_edit_sessions_on_menu_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menu_edit_sessions_on_menu_id_and_user_id ON public.menu_edit_sessions USING btree (menu_id, user_id);


--
-- Name: index_menu_edit_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_edit_sessions_on_session_id ON public.menu_edit_sessions USING btree (session_id);


--
-- Name: index_menu_edit_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_edit_sessions_on_user_id ON public.menu_edit_sessions USING btree (user_id);


--
-- Name: index_menu_imports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_imports_on_created_at ON public.menu_imports USING btree (created_at);


--
-- Name: index_menu_imports_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_imports_on_restaurant_id ON public.menu_imports USING btree (restaurant_id);


--
-- Name: index_menu_imports_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_imports_on_status ON public.menu_imports USING btree (status);


--
-- Name: index_menu_imports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_imports_on_user_id ON public.menu_imports USING btree (user_id);


--
-- Name: index_menu_item_product_links_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_item_product_links_on_menuitem_id ON public.menu_item_product_links USING btree (menuitem_id);


--
-- Name: index_menu_item_product_links_on_menuitem_id_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menu_item_product_links_on_menuitem_id_and_product_id ON public.menu_item_product_links USING btree (menuitem_id, product_id);


--
-- Name: index_menu_item_product_links_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_item_product_links_on_product_id ON public.menu_item_product_links USING btree (product_id);


--
-- Name: index_menu_item_search_documents_on_menu_id_and_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_item_search_documents_on_menu_id_and_locale ON public.menu_item_search_documents USING btree (menu_id, locale);


--
-- Name: index_menu_item_search_documents_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_item_search_documents_on_restaurant_id ON public.menu_item_search_documents USING btree (restaurant_id);


--
-- Name: index_menu_items_on_menu_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_items_on_menu_section_id ON public.menu_items USING btree (menu_section_id);


--
-- Name: index_menu_sections_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_sections_on_menu_id ON public.menu_sections USING btree (menu_id);


--
-- Name: index_menu_source_change_reviews_on_detected_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_source_change_reviews_on_detected_at ON public.menu_source_change_reviews USING btree (detected_at);


--
-- Name: index_menu_source_change_reviews_on_menu_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_source_change_reviews_on_menu_source_id ON public.menu_source_change_reviews USING btree (menu_source_id);


--
-- Name: index_menu_source_change_reviews_on_menu_source_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_source_change_reviews_on_menu_source_id_and_status ON public.menu_source_change_reviews USING btree (menu_source_id, status);


--
-- Name: index_menu_sources_on_discovered_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_sources_on_discovered_restaurant_id ON public.menu_sources USING btree (discovered_restaurant_id);


--
-- Name: index_menu_sources_on_discovered_restaurant_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_sources_on_discovered_restaurant_id_and_status ON public.menu_sources USING btree (discovered_restaurant_id, status);


--
-- Name: index_menu_sources_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_sources_on_restaurant_id ON public.menu_sources USING btree (restaurant_id);


--
-- Name: index_menu_sources_on_restaurant_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_sources_on_restaurant_id_and_status ON public.menu_sources USING btree (restaurant_id, status);


--
-- Name: index_menu_sources_on_source_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_sources_on_source_url ON public.menu_sources USING btree (source_url);


--
-- Name: index_menu_versions_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_versions_on_created_by_user_id ON public.menu_versions USING btree (created_by_user_id);


--
-- Name: index_menu_versions_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_versions_on_menu_id ON public.menu_versions USING btree (menu_id);


--
-- Name: index_menu_versions_on_menu_id_and_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_versions_on_menu_id_and_is_active ON public.menu_versions USING btree (menu_id, is_active);


--
-- Name: index_menu_versions_on_menu_id_and_starts_at_and_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_versions_on_menu_id_and_starts_at_and_ends_at ON public.menu_versions USING btree (menu_id, starts_at, ends_at);


--
-- Name: index_menu_versions_on_menu_id_and_version_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menu_versions_on_menu_id_and_version_number ON public.menu_versions USING btree (menu_id, version_number);


--
-- Name: index_menuavailabilities_on_menu_and_dayofweek; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menuavailabilities_on_menu_and_dayofweek ON public.menuavailabilities USING btree (menu_id, dayofweek);


--
-- Name: index_menuavailabilities_on_menu_day_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuavailabilities_on_menu_day_time ON public.menuavailabilities USING btree (menu_id, dayofweek, starthour) WHERE (archived = false);


--
-- Name: index_menuavailabilities_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuavailabilities_on_menu_id ON public.menuavailabilities USING btree (menu_id);


--
-- Name: index_menuitem_allergyn_mappings_on_allergyn_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_allergyn_mappings_on_allergyn_id ON public.menuitem_allergyn_mappings USING btree (allergyn_id);


--
-- Name: index_menuitem_allergyn_mappings_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_allergyn_mappings_on_menuitem_id ON public.menuitem_allergyn_mappings USING btree (menuitem_id);


--
-- Name: index_menuitem_allergyn_on_allergyn_menuitem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_allergyn_on_allergyn_menuitem ON public.menuitem_allergyn_mappings USING btree (allergyn_id, menuitem_id);


--
-- Name: index_menuitem_costs_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_costs_on_created_by_user_id ON public.menuitem_costs USING btree (created_by_user_id);


--
-- Name: index_menuitem_costs_on_effective_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_costs_on_effective_date ON public.menuitem_costs USING btree (effective_date);


--
-- Name: index_menuitem_costs_on_menuitem_id_and_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_costs_on_menuitem_id_and_is_active ON public.menuitem_costs USING btree (menuitem_id, is_active);


--
-- Name: index_menuitem_ingredient_mappings_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_ingredient_mappings_on_ingredient_id ON public.menuitem_ingredient_mappings USING btree (ingredient_id);


--
-- Name: index_menuitem_ingredient_mappings_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_ingredient_mappings_on_menuitem_id ON public.menuitem_ingredient_mappings USING btree (menuitem_id);


--
-- Name: index_menuitem_ingredient_on_ingredient_menuitem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_ingredient_on_ingredient_menuitem ON public.menuitem_ingredient_mappings USING btree (ingredient_id, menuitem_id);


--
-- Name: index_menuitem_ingredient_quantities_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_ingredient_quantities_on_ingredient_id ON public.menuitem_ingredient_quantities USING btree (ingredient_id);


--
-- Name: index_menuitem_ingredient_quantities_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_ingredient_quantities_on_menuitem_id ON public.menuitem_ingredient_quantities USING btree (menuitem_id);


--
-- Name: index_menuitem_size_mappings_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_size_mappings_on_menuitem_id ON public.menuitem_size_mappings USING btree (menuitem_id);


--
-- Name: index_menuitem_size_mappings_on_size_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_size_mappings_on_size_id ON public.menuitem_size_mappings USING btree (size_id);


--
-- Name: index_menuitem_size_on_size_menuitem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_size_on_size_menuitem ON public.menuitem_size_mappings USING btree (size_id, menuitem_id);


--
-- Name: index_menuitem_tag_mappings_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_tag_mappings_on_menuitem_id ON public.menuitem_tag_mappings USING btree (menuitem_id);


--
-- Name: index_menuitem_tag_mappings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_tag_mappings_on_tag_id ON public.menuitem_tag_mappings USING btree (tag_id);


--
-- Name: index_menuitem_tag_on_tag_menuitem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitem_tag_on_tag_menuitem ON public.menuitem_tag_mappings USING btree (tag_id, menuitem_id);


--
-- Name: index_menuitemlocales_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitemlocales_on_menuitem_id ON public.menuitemlocales USING btree (menuitem_id);


--
-- Name: index_menuitemlocales_on_menuitem_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitemlocales_on_menuitem_locale ON public.menuitemlocales USING btree (menuitem_id, locale);


--
-- Name: index_menuitemlocales_on_menuitem_locale_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitemlocales_on_menuitem_locale_status ON public.menuitemlocales USING btree (menuitem_id, locale, status);


--
-- Name: index_menuitems_on_alcohol_classification; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_alcohol_classification ON public.menuitems USING btree (alcohol_classification);


--
-- Name: index_menuitems_on_archived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_archived ON public.menuitems USING btree (archived);


--
-- Name: index_menuitems_on_course_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_course_order ON public.menuitems USING btree (course_order);


--
-- Name: index_menuitems_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_created_at ON public.menuitems USING btree (created_at);


--
-- Name: index_menuitems_on_hidden; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_hidden ON public.menuitems USING btree (hidden);


--
-- Name: index_menuitems_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_lower_name ON public.menuitems USING btree (lower((name)::text) varchar_pattern_ops);


--
-- Name: index_menuitems_on_menusection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_menusection_id ON public.menuitems USING btree (menusection_id);


--
-- Name: index_menuitems_on_menusection_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_menusection_sequence ON public.menuitems USING btree (menusection_id, sequence);


--
-- Name: index_menuitems_on_menusection_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_menusection_status ON public.menuitems USING btree (menusection_id, status);


--
-- Name: index_menuitems_on_section_and_carrier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_section_and_carrier ON public.menuitems USING btree (menusection_id, tasting_carrier);


--
-- Name: index_menuitems_on_section_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_section_status_active ON public.menuitems USING btree (menusection_id, status) WHERE (archived = false);


--
-- Name: index_menuitems_on_section_status_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_section_status_sequence ON public.menuitems USING btree (menusection_id, status, sequence) WHERE (archived = false);


--
-- Name: index_menuitems_on_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_sequence ON public.menuitems USING btree (sequence);


--
-- Name: index_menuitems_on_sommelier_needs_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_sommelier_needs_review ON public.menuitems USING btree (sommelier_needs_review);


--
-- Name: index_menuitems_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_status ON public.menuitems USING btree (status);


--
-- Name: index_menuitems_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuitems_on_updated_at ON public.menuitems USING btree (updated_at);


--
-- Name: index_menulocales_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menulocales_on_menu_id ON public.menulocales USING btree (menu_id);


--
-- Name: index_menulocales_on_menu_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menulocales_on_menu_locale ON public.menulocales USING btree (menu_id, locale);


--
-- Name: index_menuparticipants_on_session_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuparticipants_on_session_locale ON public.menuparticipants USING btree (sessionid, preferredlocale);


--
-- Name: index_menuparticipants_on_session_smartmenu; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menuparticipants_on_session_smartmenu ON public.menuparticipants USING btree (sessionid, smartmenu_id);


--
-- Name: index_menuparticipants_on_sessionid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuparticipants_on_sessionid ON public.menuparticipants USING btree (sessionid);


--
-- Name: index_menuparticipants_on_smartmenu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menuparticipants_on_smartmenu_id ON public.menuparticipants USING btree (smartmenu_id);


--
-- Name: index_menus_on_archived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_archived ON public.menus USING btree (archived);


--
-- Name: index_menus_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_archived_by_id ON public.menus USING btree (archived_by_id);


--
-- Name: index_menus_on_menu_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_menu_import_id ON public.menus USING btree (menu_import_id);


--
-- Name: index_menus_on_menuitems_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_menuitems_count ON public.menus USING btree (menuitems_count);


--
-- Name: index_menus_on_owner_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_owner_restaurant_id ON public.menus USING btree (owner_restaurant_id);


--
-- Name: index_menus_on_restaurant_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_restaurant_created_at ON public.menus USING btree (restaurant_id, created_at);


--
-- Name: index_menus_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_restaurant_id ON public.menus USING btree (restaurant_id);


--
-- Name: index_menus_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_restaurant_status_active ON public.menus USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_menus_on_restaurant_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_restaurant_updated_at ON public.menus USING btree (restaurant_id, updated_at);


--
-- Name: index_menus_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_status ON public.menus USING btree (status);


--
-- Name: index_menusectionlocales_on_menusection_and_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menusectionlocales_on_menusection_and_locale ON public.menusectionlocales USING btree (menusection_id, locale);


--
-- Name: index_menusectionlocales_on_menusection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusectionlocales_on_menusection_id ON public.menusectionlocales USING btree (menusection_id);


--
-- Name: index_menusectionlocales_on_menusection_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusectionlocales_on_menusection_status ON public.menusectionlocales USING btree (menusection_id, status);


--
-- Name: index_menusections_on_menu_and_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusections_on_menu_and_sequence ON public.menusections USING btree (menu_id, sequence);


--
-- Name: index_menusections_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusections_on_menu_id ON public.menusections USING btree (menu_id);


--
-- Name: index_menusections_on_menu_status_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusections_on_menu_status_sequence ON public.menusections USING btree (menu_id, status, sequence) WHERE (archived = false);


--
-- Name: index_menusections_on_menuitems_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusections_on_menuitems_count ON public.menusections USING btree (menuitems_count);


--
-- Name: index_menusections_on_tasting_menu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menusections_on_tasting_menu ON public.menusections USING btree (tasting_menu);


--
-- Name: index_metrics_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metrics_on_created_at ON public.metrics USING btree (created_at);


--
-- Name: index_noticed_events_on_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_noticed_events_on_record ON public.noticed_events USING btree (record_type, record_id);


--
-- Name: index_noticed_notifications_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_noticed_notifications_on_event_id ON public.noticed_notifications USING btree (event_id);


--
-- Name: index_noticed_notifications_on_recipient; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_noticed_notifications_on_recipient ON public.noticed_notifications USING btree (recipient_type, recipient_id);


--
-- Name: index_ocr_imports_on_restaurant_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_imports_on_restaurant_status_created ON public.ocr_menu_imports USING btree (restaurant_id, status, created_at);


--
-- Name: index_ocr_menu_imports_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_imports_on_menu_id ON public.ocr_menu_imports USING btree (menu_id);


--
-- Name: index_ocr_menu_imports_on_restaurant_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_imports_on_restaurant_and_status ON public.ocr_menu_imports USING btree (restaurant_id, status);


--
-- Name: index_ocr_menu_imports_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_imports_on_restaurant_id ON public.ocr_menu_imports USING btree (restaurant_id);


--
-- Name: index_ocr_menu_imports_on_source_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_imports_on_source_locale ON public.ocr_menu_imports USING btree (source_locale);


--
-- Name: index_ocr_menu_imports_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_imports_on_status ON public.ocr_menu_imports USING btree (status);


--
-- Name: index_ocr_menu_items_on_allergens; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_allergens ON public.ocr_menu_items USING gin (allergens);


--
-- Name: index_ocr_menu_items_on_is_confirmed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_is_confirmed ON public.ocr_menu_items USING btree (is_confirmed);


--
-- Name: index_ocr_menu_items_on_is_gluten_free; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_is_gluten_free ON public.ocr_menu_items USING btree (is_gluten_free);


--
-- Name: index_ocr_menu_items_on_is_vegan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_is_vegan ON public.ocr_menu_items USING btree (is_vegan);


--
-- Name: index_ocr_menu_items_on_is_vegetarian; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_is_vegetarian ON public.ocr_menu_items USING btree (is_vegetarian);


--
-- Name: index_ocr_menu_items_on_menu_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_menu_item_id ON public.ocr_menu_items USING btree (menu_item_id);


--
-- Name: index_ocr_menu_items_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_menuitem_id ON public.ocr_menu_items USING btree (menuitem_id);


--
-- Name: index_ocr_menu_items_on_ocr_menu_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_ocr_menu_section_id ON public.ocr_menu_items USING btree (ocr_menu_section_id);


--
-- Name: index_ocr_menu_items_on_section_and_confirmed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_section_and_confirmed ON public.ocr_menu_items USING btree (ocr_menu_section_id, is_confirmed);


--
-- Name: index_ocr_menu_items_on_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_items_on_sequence ON public.ocr_menu_items USING btree (sequence);


--
-- Name: index_ocr_menu_sections_on_import_and_confirmed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_sections_on_import_and_confirmed ON public.ocr_menu_sections USING btree (ocr_menu_import_id, is_confirmed);


--
-- Name: index_ocr_menu_sections_on_is_confirmed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_sections_on_is_confirmed ON public.ocr_menu_sections USING btree (is_confirmed);


--
-- Name: index_ocr_menu_sections_on_menu_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_sections_on_menu_section_id ON public.ocr_menu_sections USING btree (menu_section_id);


--
-- Name: index_ocr_menu_sections_on_menusection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_sections_on_menusection_id ON public.ocr_menu_sections USING btree (menusection_id);


--
-- Name: index_ocr_menu_sections_on_ocr_menu_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_sections_on_ocr_menu_import_id ON public.ocr_menu_sections USING btree (ocr_menu_import_id);


--
-- Name: index_ocr_menu_sections_on_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ocr_menu_sections_on_sequence ON public.ocr_menu_sections USING btree (sequence);


--
-- Name: index_old_passwords_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_old_passwords_on_user_id ON public.old_passwords USING btree (user_id);


--
-- Name: index_onboarding_sessions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_onboarding_sessions_on_created_at ON public.onboarding_sessions USING btree (created_at);


--
-- Name: index_onboarding_sessions_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_onboarding_sessions_on_menu_id ON public.onboarding_sessions USING btree (menu_id);


--
-- Name: index_onboarding_sessions_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_onboarding_sessions_on_restaurant_id ON public.onboarding_sessions USING btree (restaurant_id);


--
-- Name: index_onboarding_sessions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_onboarding_sessions_on_status ON public.onboarding_sessions USING btree (status);


--
-- Name: index_onboarding_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_onboarding_sessions_on_user_id ON public.onboarding_sessions USING btree (user_id);


--
-- Name: index_order_events_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_events_on_ordr_id ON public.order_events USING btree (ordr_id);


--
-- Name: index_order_events_on_ordr_id_and_created_at_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_events_on_ordr_id_and_created_at_and_id ON public.order_events USING btree (ordr_id, created_at, id);


--
-- Name: index_order_events_on_ordr_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_order_events_on_ordr_id_and_idempotency_key ON public.order_events USING btree (ordr_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: index_order_events_on_ordr_id_and_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_order_events_on_ordr_id_and_sequence ON public.order_events USING btree (ordr_id, sequence);


--
-- Name: index_ordr_split_item_assignments_on_ordr_split_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_item_assignments_on_ordr_split_payment_id ON public.ordr_split_item_assignments USING btree (ordr_split_payment_id);


--
-- Name: index_ordr_split_item_assignments_on_ordr_split_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_item_assignments_on_ordr_split_plan_id ON public.ordr_split_item_assignments USING btree (ordr_split_plan_id);


--
-- Name: index_ordr_split_item_assignments_on_ordritem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_item_assignments_on_ordritem_id ON public.ordr_split_item_assignments USING btree (ordritem_id);


--
-- Name: index_ordr_split_payments_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ordr_split_payments_on_idempotency_key ON public.ordr_split_payments USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: index_ordr_split_payments_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_payments_on_ordr_id ON public.ordr_split_payments USING btree (ordr_id);


--
-- Name: index_ordr_split_payments_on_ordr_split_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_payments_on_ordr_split_plan_id ON public.ordr_split_payments USING btree (ordr_split_plan_id);


--
-- Name: index_ordr_split_payments_on_ordr_split_plan_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ordr_split_payments_on_ordr_split_plan_id_and_position ON public.ordr_split_payments USING btree (ordr_split_plan_id, "position");


--
-- Name: index_ordr_split_payments_on_ordrparticipant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_payments_on_ordrparticipant_id ON public.ordr_split_payments USING btree (ordrparticipant_id);


--
-- Name: index_ordr_split_payments_on_provider_and_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ordr_split_payments_on_provider_and_payment_id ON public.ordr_split_payments USING btree (provider, provider_payment_id) WHERE (provider_payment_id IS NOT NULL);


--
-- Name: index_ordr_split_payments_on_provider_checkout_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ordr_split_payments_on_provider_checkout_session_id ON public.ordr_split_payments USING btree (provider_checkout_session_id);


--
-- Name: index_ordr_split_payments_on_provider_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_payments_on_provider_payment_id ON public.ordr_split_payments USING btree (provider_payment_id);


--
-- Name: index_ordr_split_plans_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_plans_on_created_by_user_id ON public.ordr_split_plans USING btree (created_by_user_id);


--
-- Name: index_ordr_split_plans_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ordr_split_plans_on_ordr_id ON public.ordr_split_plans USING btree (ordr_id);


--
-- Name: index_ordr_split_plans_on_plan_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_plans_on_plan_status ON public.ordr_split_plans USING btree (plan_status);


--
-- Name: index_ordr_split_plans_on_updated_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_split_plans_on_updated_by_user_id ON public.ordr_split_plans USING btree (updated_by_user_id);


--
-- Name: index_ordr_station_tickets_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_station_tickets_on_ordr_id ON public.ordr_station_tickets USING btree (ordr_id);


--
-- Name: index_ordr_station_tickets_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordr_station_tickets_on_restaurant_id ON public.ordr_station_tickets USING btree (restaurant_id);


--
-- Name: index_ordractions_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordractions_on_ordr_id ON public.ordractions USING btree (ordr_id);


--
-- Name: index_ordractions_on_ordritem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordractions_on_ordritem_id ON public.ordractions USING btree (ordritem_id);


--
-- Name: index_ordractions_on_ordrparticipant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordractions_on_ordrparticipant_id ON public.ordractions USING btree (ordrparticipant_id);


--
-- Name: index_ordractions_on_participant_ordr_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordractions_on_participant_ordr_action ON public.ordractions USING btree (ordrparticipant_id, ordr_id, action);


--
-- Name: index_ordritemnotes_on_ordritem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritemnotes_on_ordritem_id ON public.ordritemnotes USING btree (ordritem_id);


--
-- Name: index_ordritems_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_created_at ON public.ordritems USING btree (created_at);


--
-- Name: index_ordritems_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_menuitem_id ON public.ordritems USING btree (menuitem_id);


--
-- Name: index_ordritems_on_menuitem_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_menuitem_status ON public.ordritems USING btree (menuitem_id, status);


--
-- Name: index_ordritems_on_merge_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_merge_lookup ON public.ordritems USING btree (ordr_id, menuitem_id, size_name, status);


--
-- Name: index_ordritems_on_ordr_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_ordr_created_at ON public.ordritems USING btree (ordr_id, created_at);


--
-- Name: index_ordritems_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_ordr_id ON public.ordritems USING btree (ordr_id);


--
-- Name: index_ordritems_on_ordr_id_and_line_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ordritems_on_ordr_id_and_line_key ON public.ordritems USING btree (ordr_id, line_key);


--
-- Name: index_ordritems_on_ordr_station_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_ordr_station_ticket_id ON public.ordritems USING btree (ordr_station_ticket_id);


--
-- Name: index_ordritems_on_ordr_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_ordr_status ON public.ordritems USING btree (ordr_id, status);


--
-- Name: index_ordritems_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordritems_on_status ON public.ordritems USING btree (status);


--
-- Name: index_ordrnotes_on_category_and_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrnotes_on_category_and_priority ON public.ordrnotes USING btree (category, priority);


--
-- Name: index_ordrnotes_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrnotes_on_employee_id ON public.ordrnotes USING btree (employee_id);


--
-- Name: index_ordrnotes_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrnotes_on_ordr_id ON public.ordrnotes USING btree (ordr_id);


--
-- Name: index_ordrnotes_on_ordr_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrnotes_on_ordr_id_and_created_at ON public.ordrnotes USING btree (ordr_id, created_at);


--
-- Name: index_ordrparticipant_allergyn_filters_on_allergyn_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipant_allergyn_filters_on_allergyn_id ON public.ordrparticipant_allergyn_filters USING btree (allergyn_id);


--
-- Name: index_ordrparticipant_allergyn_filters_on_ordrparticipant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipant_allergyn_filters_on_ordrparticipant_id ON public.ordrparticipant_allergyn_filters USING btree (ordrparticipant_id);


--
-- Name: index_ordrparticipant_allergyn_on_participant_allergyn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipant_allergyn_on_participant_allergyn ON public.ordrparticipant_allergyn_filters USING btree (ordrparticipant_id, allergyn_id);


--
-- Name: index_ordrparticipants_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipants_on_employee_id ON public.ordrparticipants USING btree (employee_id);


--
-- Name: index_ordrparticipants_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipants_on_ordr_id ON public.ordrparticipants USING btree (ordr_id);


--
-- Name: index_ordrparticipants_on_ordr_role_employee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipants_on_ordr_role_employee ON public.ordrparticipants USING btree (ordr_id, role, employee_id);


--
-- Name: index_ordrparticipants_on_ordr_role_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipants_on_ordr_role_session ON public.ordrparticipants USING btree (ordr_id, role, sessionid);


--
-- Name: index_ordrparticipants_on_ordritem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipants_on_ordritem_id ON public.ordrparticipants USING btree (ordritem_id);


--
-- Name: index_ordrparticipants_on_session_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrparticipants_on_session_locale ON public.ordrparticipants USING btree (sessionid, preferredlocale);


--
-- Name: index_ordrs_on_auto_pay_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_auto_pay_enabled ON public.ordrs USING btree (auto_pay_enabled) WHERE (auto_pay_enabled = true);


--
-- Name: index_ordrs_on_auto_pay_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_auto_pay_status ON public.ordrs USING btree (auto_pay_status);


--
-- Name: index_ordrs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_created_at ON public.ordrs USING btree (created_at);


--
-- Name: index_ordrs_on_employee_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_employee_created_at ON public.ordrs USING btree (employee_id, created_at);


--
-- Name: index_ordrs_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_employee_id ON public.ordrs USING btree (employee_id);


--
-- Name: index_ordrs_on_last_projected_order_event_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_last_projected_order_event_sequence ON public.ordrs USING btree (last_projected_order_event_sequence);


--
-- Name: index_ordrs_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_menu_id ON public.ordrs USING btree (menu_id);


--
-- Name: index_ordrs_on_menu_table_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_menu_table_status ON public.ordrs USING btree (menu_id, tablesetting_id, status);


--
-- Name: index_ordrs_on_ordritems_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_ordritems_count ON public.ordrs USING btree (ordritems_count);


--
-- Name: index_ordrs_on_payment_on_file; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_payment_on_file ON public.ordrs USING btree (payment_on_file) WHERE (payment_on_file = true);


--
-- Name: index_ordrs_on_restaurant_created_gross; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_restaurant_created_gross ON public.ordrs USING btree (restaurant_id, created_at, gross);


--
-- Name: index_ordrs_on_restaurant_created_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_restaurant_created_status ON public.ordrs USING btree (restaurant_id, created_at, status);


--
-- Name: index_ordrs_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_restaurant_id ON public.ordrs USING btree (restaurant_id);


--
-- Name: index_ordrs_on_restaurant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_restaurant_status ON public.ordrs USING btree (restaurant_id, status);


--
-- Name: index_ordrs_on_restaurant_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_restaurant_status_created ON public.ordrs USING btree (restaurant_id, status, created_at);


--
-- Name: index_ordrs_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_status ON public.ordrs USING btree (status);


--
-- Name: index_ordrs_on_table_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_table_status_created ON public.ordrs USING btree (tablesetting_id, status, created_at);


--
-- Name: index_ordrs_on_tablesetting_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_tablesetting_and_status ON public.ordrs USING btree (tablesetting_id, status);


--
-- Name: index_ordrs_on_tablesetting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_tablesetting_id ON public.ordrs USING btree (tablesetting_id);


--
-- Name: index_ordrs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ordrs_on_updated_at ON public.ordrs USING btree (updated_at);


--
-- Name: index_pairing_recommendations_on_drink_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pairing_recommendations_on_drink_menuitem_id ON public.pairing_recommendations USING btree (drink_menuitem_id);


--
-- Name: index_pairing_recommendations_on_food_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pairing_recommendations_on_food_menuitem_id ON public.pairing_recommendations USING btree (food_menuitem_id);


--
-- Name: index_pay_charges_on_customer_id_and_processor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_charges_on_customer_id_and_processor_id ON public.pay_charges USING btree (customer_id, processor_id);


--
-- Name: index_pay_charges_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_charges_on_subscription_id ON public.pay_charges USING btree (subscription_id);


--
-- Name: index_pay_customers_on_processor_and_processor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_customers_on_processor_and_processor_id ON public.pay_customers USING btree (processor, processor_id);


--
-- Name: index_pay_merchants_on_owner_type_and_owner_id_and_processor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_merchants_on_owner_type_and_owner_id_and_processor ON public.pay_merchants USING btree (owner_type, owner_id, processor);


--
-- Name: index_pay_merchants_on_processor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_merchants_on_processor_id ON public.pay_merchants USING btree (processor_id);


--
-- Name: index_pay_payment_methods_on_customer_id_and_processor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_payment_methods_on_customer_id_and_processor_id ON public.pay_payment_methods USING btree (customer_id, processor_id);


--
-- Name: index_pay_subscriptions_on_customer_id_and_processor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pay_subscriptions_on_customer_id_and_processor_id ON public.pay_subscriptions USING btree (customer_id, processor_id);


--
-- Name: index_pay_subscriptions_on_metered; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_subscriptions_on_metered ON public.pay_subscriptions USING btree (metered);


--
-- Name: index_pay_subscriptions_on_pause_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_subscriptions_on_pause_starts_at ON public.pay_subscriptions USING btree (pause_starts_at);


--
-- Name: index_pay_subscriptions_on_payment_method_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pay_subscriptions_on_payment_method_id ON public.pay_subscriptions USING btree (payment_method_id);


--
-- Name: index_payment_attempts_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_attempts_on_idempotency_key ON public.payment_attempts USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: index_payment_attempts_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_attempts_on_ordr_id ON public.payment_attempts USING btree (ordr_id);


--
-- Name: index_payment_attempts_on_ordr_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_attempts_on_ordr_id_and_created_at ON public.payment_attempts USING btree (ordr_id, created_at);


--
-- Name: index_payment_attempts_on_provider_and_provider_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_attempts_on_provider_and_provider_payment_id ON public.payment_attempts USING btree (provider, provider_payment_id) WHERE (provider_payment_id IS NOT NULL);


--
-- Name: index_payment_attempts_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_attempts_on_restaurant_id ON public.payment_attempts USING btree (restaurant_id);


--
-- Name: index_payment_attempts_on_restaurant_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_attempts_on_restaurant_id_and_created_at ON public.payment_attempts USING btree (restaurant_id, created_at);


--
-- Name: index_payment_profiles_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_profiles_on_restaurant_id ON public.payment_profiles USING btree (restaurant_id);


--
-- Name: index_payment_refunds_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_refunds_on_ordr_id ON public.payment_refunds USING btree (ordr_id);


--
-- Name: index_payment_refunds_on_payment_attempt_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_refunds_on_payment_attempt_id ON public.payment_refunds USING btree (payment_attempt_id);


--
-- Name: index_payment_refunds_on_payment_attempt_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_refunds_on_payment_attempt_id_and_created_at ON public.payment_refunds USING btree (payment_attempt_id, created_at);


--
-- Name: index_payment_refunds_on_provider_and_provider_refund_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_refunds_on_provider_and_provider_refund_id ON public.payment_refunds USING btree (provider, provider_refund_id) WHERE (provider_refund_id IS NOT NULL);


--
-- Name: index_payment_refunds_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_refunds_on_restaurant_id ON public.payment_refunds USING btree (restaurant_id);


--
-- Name: index_performance_metrics_on_endpoint_and_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_on_endpoint_and_timestamp ON public.performance_metrics USING btree (endpoint, "timestamp");


--
-- Name: index_performance_metrics_on_response_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_on_response_time ON public.performance_metrics USING btree (response_time);


--
-- Name: index_performance_metrics_on_status_code_and_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_on_status_code_and_timestamp ON public.performance_metrics USING btree (status_code, "timestamp");


--
-- Name: index_performance_metrics_on_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_on_timestamp ON public.performance_metrics USING btree ("timestamp");


--
-- Name: index_performance_metrics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_on_user_id ON public.performance_metrics USING btree (user_id);


--
-- Name: index_plans_on_stripe_price_id_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_stripe_price_id_month ON public.plans USING btree (stripe_price_id_month);


--
-- Name: index_plans_on_stripe_price_id_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_stripe_price_id_year ON public.plans USING btree (stripe_price_id_year);


--
-- Name: index_product_enrichments_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enrichments_on_product_id ON public.product_enrichments USING btree (product_id);


--
-- Name: index_product_enrichments_on_product_id_and_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enrichments_on_product_id_and_source ON public.product_enrichments USING btree (product_id, source);


--
-- Name: index_product_enrichments_on_source_and_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enrichments_on_source_and_external_id ON public.product_enrichments USING btree (source, external_id);


--
-- Name: index_products_on_product_type_and_canonical_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_product_type_and_canonical_name ON public.products USING btree (product_type, canonical_name);


--
-- Name: index_profit_margin_targets_on_menuitem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profit_margin_targets_on_menuitem_id ON public.profit_margin_targets USING btree (menuitem_id);


--
-- Name: index_profit_margin_targets_on_menusection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profit_margin_targets_on_menusection_id ON public.profit_margin_targets USING btree (menusection_id);


--
-- Name: index_profit_margin_targets_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profit_margin_targets_on_restaurant_id ON public.profit_margin_targets USING btree (restaurant_id);


--
-- Name: index_provider_accounts_on_provider_and_provider_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_provider_accounts_on_provider_and_provider_account_id ON public.provider_accounts USING btree (provider, provider_account_id);


--
-- Name: index_provider_accounts_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_accounts_on_restaurant_id ON public.provider_accounts USING btree (restaurant_id);


--
-- Name: index_provider_accounts_on_restaurant_id_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provider_accounts_on_restaurant_id_and_provider ON public.provider_accounts USING btree (restaurant_id, provider);


--
-- Name: index_push_subscriptions_on_endpoint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_push_subscriptions_on_endpoint ON public.push_subscriptions USING btree (endpoint);


--
-- Name: index_push_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_push_subscriptions_on_user_id ON public.push_subscriptions USING btree (user_id);


--
-- Name: index_push_subscriptions_on_user_id_and_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_push_subscriptions_on_user_id_and_active ON public.push_subscriptions USING btree (user_id, active);


--
-- Name: index_receipt_deliveries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_receipt_deliveries_on_created_at ON public.receipt_deliveries USING btree (created_at);


--
-- Name: index_receipt_deliveries_on_ordr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_receipt_deliveries_on_ordr_id ON public.receipt_deliveries USING btree (ordr_id);


--
-- Name: index_receipt_deliveries_on_ordr_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_receipt_deliveries_on_ordr_id_and_status ON public.receipt_deliveries USING btree (ordr_id, status);


--
-- Name: index_receipt_deliveries_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_receipt_deliveries_on_restaurant_id ON public.receipt_deliveries USING btree (restaurant_id);


--
-- Name: index_receipt_deliveries_on_secure_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_receipt_deliveries_on_secure_token ON public.receipt_deliveries USING btree (secure_token);


--
-- Name: index_resource_locks_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_resource_locks_on_expires_at ON public.resource_locks USING btree (expires_at);


--
-- Name: index_resource_locks_on_resource_and_field; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_resource_locks_on_resource_and_field ON public.resource_locks USING btree (resource_type, resource_id, field_name);


--
-- Name: index_resource_locks_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_resource_locks_on_session_id ON public.resource_locks USING btree (session_id);


--
-- Name: index_resource_locks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_resource_locks_on_user_id ON public.resource_locks USING btree (user_id);


--
-- Name: index_restaurant_claim_requests_on_initiated_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_claim_requests_on_initiated_by_user_id ON public.restaurant_claim_requests USING btree (initiated_by_user_id);


--
-- Name: index_restaurant_claim_requests_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_claim_requests_on_restaurant_id ON public.restaurant_claim_requests USING btree (restaurant_id);


--
-- Name: index_restaurant_claim_requests_on_restaurant_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_claim_requests_on_restaurant_id_and_status ON public.restaurant_claim_requests USING btree (restaurant_id, status);


--
-- Name: index_restaurant_claim_requests_on_reviewed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_claim_requests_on_reviewed_by_user_id ON public.restaurant_claim_requests USING btree (reviewed_by_user_id);


--
-- Name: index_restaurant_menus_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_menus_on_archived_by_id ON public.restaurant_menus USING btree (archived_by_id);


--
-- Name: index_restaurant_menus_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_menus_on_menu_id ON public.restaurant_menus USING btree (menu_id);


--
-- Name: index_restaurant_menus_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_menus_on_restaurant_id ON public.restaurant_menus USING btree (restaurant_id);


--
-- Name: index_restaurant_menus_on_restaurant_id_and_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_restaurant_menus_on_restaurant_id_and_menu_id ON public.restaurant_menus USING btree (restaurant_id, menu_id);


--
-- Name: index_restaurant_onboardings_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_onboardings_on_restaurant_id ON public.restaurant_onboardings USING btree (restaurant_id);


--
-- Name: index_restaurant_removal_requests_on_actioned_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_removal_requests_on_actioned_by_user_id ON public.restaurant_removal_requests USING btree (actioned_by_user_id);


--
-- Name: index_restaurant_removal_requests_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_removal_requests_on_restaurant_id ON public.restaurant_removal_requests USING btree (restaurant_id);


--
-- Name: index_restaurant_removal_requests_on_restaurant_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_removal_requests_on_restaurant_id_and_status ON public.restaurant_removal_requests USING btree (restaurant_id, status);


--
-- Name: index_restaurant_subscriptions_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_restaurant_subscriptions_on_restaurant_id ON public.restaurant_subscriptions USING btree (restaurant_id);


--
-- Name: index_restaurant_subscriptions_on_stripe_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_subscriptions_on_stripe_customer_id ON public.restaurant_subscriptions USING btree (stripe_customer_id);


--
-- Name: index_restaurant_subscriptions_on_stripe_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurant_subscriptions_on_stripe_subscription_id ON public.restaurant_subscriptions USING btree (stripe_subscription_id);


--
-- Name: index_restaurantavailabilities_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurantavailabilities_on_restaurant_id ON public.restaurantavailabilities USING btree (restaurant_id);


--
-- Name: index_restaurantlocales_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurantlocales_on_restaurant_id ON public.restaurantlocales USING btree (restaurant_id);


--
-- Name: index_restaurantlocales_on_restaurant_id_and_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurantlocales_on_restaurant_id_and_sequence ON public.restaurantlocales USING btree (restaurant_id, sequence);


--
-- Name: index_restaurantlocales_on_restaurant_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurantlocales_on_restaurant_locale ON public.restaurantlocales USING btree (restaurant_id, locale);


--
-- Name: index_restaurantlocales_on_restaurant_status_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurantlocales_on_restaurant_status_default ON public.restaurantlocales USING btree (restaurant_id, status, dfault);


--
-- Name: index_restaurants_on_archived_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_archived_by_id ON public.restaurants USING btree (archived_by_id);


--
-- Name: index_restaurants_on_claim_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_claim_status ON public.restaurants USING btree (claim_status);


--
-- Name: index_restaurants_on_employees_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_employees_count ON public.restaurants USING btree (employees_count);


--
-- Name: index_restaurants_on_google_place_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_restaurants_on_google_place_id ON public.restaurants USING btree (google_place_id);


--
-- Name: index_restaurants_on_menus_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_menus_count ON public.restaurants USING btree (menus_count);


--
-- Name: index_restaurants_on_preview_published_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_preview_published_at ON public.restaurants USING btree (preview_published_at);


--
-- Name: index_restaurants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_user_id ON public.restaurants USING btree (user_id);


--
-- Name: index_restaurants_on_user_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_restaurants_on_user_status_active ON public.restaurants USING btree (user_id, status) WHERE (archived = false);


--
-- Name: index_services_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_on_user_id ON public.services USING btree (user_id);


--
-- Name: index_similar_product_recommendations_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_similar_product_recommendations_on_product_id ON public.similar_product_recommendations USING btree (product_id);


--
-- Name: index_sizes_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sizes_on_restaurant_id ON public.sizes USING btree (restaurant_id);


--
-- Name: index_sizes_on_restaurant_id_and_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sizes_on_restaurant_id_and_category ON public.sizes USING btree (restaurant_id, category);


--
-- Name: index_sizes_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sizes_on_restaurant_status_active ON public.sizes USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_slow_queries_on_duration_and_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slow_queries_on_duration_and_timestamp ON public.slow_queries USING btree (duration, "timestamp");


--
-- Name: index_slow_queries_on_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slow_queries_on_timestamp ON public.slow_queries USING btree ("timestamp");


--
-- Name: index_smartmenus_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_smartmenus_on_menu_id ON public.smartmenus USING btree (menu_id);


--
-- Name: index_smartmenus_on_public_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_smartmenus_on_public_token ON public.smartmenus USING btree (public_token);


--
-- Name: index_smartmenus_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_smartmenus_on_restaurant_id ON public.smartmenus USING btree (restaurant_id);


--
-- Name: index_smartmenus_on_restaurant_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_smartmenus_on_restaurant_slug ON public.smartmenus USING btree (restaurant_id, slug);


--
-- Name: index_smartmenus_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_smartmenus_on_slug ON public.smartmenus USING btree (slug);


--
-- Name: index_smartmenus_on_tablesetting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_smartmenus_on_tablesetting_id ON public.smartmenus USING btree (tablesetting_id);


--
-- Name: index_staff_invitations_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_invitations_on_invited_by_id ON public.staff_invitations USING btree (invited_by_id);


--
-- Name: index_staff_invitations_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_invitations_on_restaurant_id ON public.staff_invitations USING btree (restaurant_id);


--
-- Name: index_staff_invitations_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_invitations_on_status ON public.staff_invitations USING btree (status);


--
-- Name: index_staff_invitations_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_staff_invitations_on_token ON public.staff_invitations USING btree (token);


--
-- Name: index_station_tickets_on_order_station_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_station_tickets_on_order_station_sequence ON public.ordr_station_tickets USING btree (ordr_id, station, sequence);


--
-- Name: index_station_tickets_on_restaurant_station_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_station_tickets_on_restaurant_station_status ON public.ordr_station_tickets USING btree (restaurant_id, station, status);


--
-- Name: index_tablesettings_on_restaurant_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tablesettings_on_restaurant_created_at ON public.tablesettings USING btree (restaurant_id, created_at);


--
-- Name: index_tablesettings_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tablesettings_on_restaurant_id ON public.tablesettings USING btree (restaurant_id);


--
-- Name: index_tablesettings_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tablesettings_on_restaurant_status_active ON public.tablesettings USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_taxes_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_restaurant_id ON public.taxes USING btree (restaurant_id);


--
-- Name: index_taxes_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_restaurant_status_active ON public.taxes USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_testimonials_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_testimonials_on_restaurant_id ON public.testimonials USING btree (restaurant_id);


--
-- Name: index_testimonials_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_testimonials_on_user_id ON public.testimonials USING btree (user_id);


--
-- Name: index_tips_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tips_on_restaurant_id ON public.tips USING btree (restaurant_id);


--
-- Name: index_tips_on_restaurant_status_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tips_on_restaurant_status_active ON public.tips USING btree (restaurant_id, status) WHERE (archived = false);


--
-- Name: index_tracks_on_restaurant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracks_on_restaurant_id ON public.tracks USING btree (restaurant_id);


--
-- Name: index_user_sessions_on_last_activity_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_last_activity_at ON public.user_sessions USING btree (last_activity_at);


--
-- Name: index_user_sessions_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_resource_type_and_resource_id ON public.user_sessions USING btree (resource_type, resource_id);


--
-- Name: index_user_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_sessions_on_session_id ON public.user_sessions USING btree (session_id);


--
-- Name: index_user_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: index_user_sessions_on_user_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_user_id_and_status ON public.user_sessions USING btree (user_id, status);


--
-- Name: index_userplans_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_userplans_on_plan_id ON public.userplans USING btree (plan_id);


--
-- Name: index_userplans_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_userplans_on_user_id ON public.userplans USING btree (user_id);


--
-- Name: index_users_on_admin_and_super_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_admin_and_super_admin ON public.users USING btree (admin, super_admin);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_plan_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_plan_admin ON public.users USING btree (plan_id, admin);


--
-- Name: index_users_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_plan_id ON public.users USING btree (plan_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_video_analytics_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_analytics_on_event_type ON public.video_analytics USING btree (event_type);


--
-- Name: index_video_analytics_on_video_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_analytics_on_video_id_and_created_at ON public.video_analytics USING btree (video_id, created_at);


--
-- Name: index_voice_commands_on_smartmenu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voice_commands_on_smartmenu_id ON public.voice_commands USING btree (smartmenu_id);


--
-- Name: index_voice_commands_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voice_commands_on_status ON public.voice_commands USING btree (status);


--
-- Name: index_whiskey_flights_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_whiskey_flights_on_menu_id ON public.whiskey_flights USING btree (menu_id);


--
-- Name: index_whiskey_flights_on_menu_id_and_theme_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_whiskey_flights_on_menu_id_and_theme_key ON public.whiskey_flights USING btree (menu_id, theme_key);


--
-- Name: index_whiskey_flights_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_whiskey_flights_on_status ON public.whiskey_flights USING btree (status);


--
-- Name: pay_customer_owner_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pay_customer_owner_index ON public.pay_customers USING btree (owner_type, owner_id, deleted_at);


--
-- Name: uniq_smartmenus_restaurant_menu_global; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_smartmenus_restaurant_menu_global ON public.smartmenus USING btree (restaurant_id, menu_id) WHERE ((tablesetting_id IS NULL) AND (menu_id IS NOT NULL));


--
-- Name: uniq_smartmenus_restaurant_menu_table; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_smartmenus_restaurant_menu_table ON public.smartmenus USING btree (restaurant_id, menu_id, tablesetting_id) WHERE ((menu_id IS NOT NULL) AND (tablesetting_id IS NOT NULL));


--
-- Name: uniq_smartmenus_restaurant_table_general; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_smartmenus_restaurant_table_general ON public.smartmenus USING btree (restaurant_id, tablesetting_id) WHERE ((menu_id IS NULL) AND (tablesetting_id IS NOT NULL));


--
-- Name: ordr_split_item_assignments fk_rails_016ef3ed65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_item_assignments
    ADD CONSTRAINT fk_rails_016ef3ed65 FOREIGN KEY (ordritem_id) REFERENCES public.ordritems(id);


--
-- Name: menu_imports fk_rails_01b0b8d6ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_imports
    ADD CONSTRAINT fk_rails_01b0b8d6ad FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: marketing_qr_codes fk_rails_03049c5671; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes
    ADD CONSTRAINT fk_rails_03049c5671 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE SET NULL;


--
-- Name: dining_sessions fk_rails_04d0a237df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dining_sessions
    ADD CONSTRAINT fk_rails_04d0a237df FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ocr_menu_sections fk_rails_061628071d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_sections
    ADD CONSTRAINT fk_rails_061628071d FOREIGN KEY (ocr_menu_import_id) REFERENCES public.ocr_menu_imports(id);


--
-- Name: ordractions fk_rails_116964a63c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordractions
    ADD CONSTRAINT fk_rails_116964a63c FOREIGN KEY (ordritem_id) REFERENCES public.ordritems(id);


--
-- Name: smartmenus fk_rails_13af15e3c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smartmenus
    ADD CONSTRAINT fk_rails_13af15e3c9 FOREIGN KEY (tablesetting_id) REFERENCES public.tablesettings(id);


--
-- Name: features_plans fk_rails_1527e9ed48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.features_plans
    ADD CONSTRAINT fk_rails_1527e9ed48 FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: receipt_deliveries fk_rails_1651c34dcb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_deliveries
    ADD CONSTRAINT fk_rails_1651c34dcb FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: onboarding_sessions fk_rails_16ce28a5c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onboarding_sessions
    ADD CONSTRAINT fk_rails_16ce28a5c1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: similar_product_recommendations fk_rails_1819b9c717; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.similar_product_recommendations
    ADD CONSTRAINT fk_rails_1819b9c717 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: ordrnotes fk_rails_1828436f4a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrnotes
    ADD CONSTRAINT fk_rails_1828436f4a FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: ocr_menu_items fk_rails_19883c5eee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_items
    ADD CONSTRAINT fk_rails_19883c5eee FOREIGN KEY (ocr_menu_section_id) REFERENCES public.ocr_menu_sections(id);


--
-- Name: menus fk_rails_1a9abeaefc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT fk_rails_1a9abeaefc FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: menu_versions fk_rails_1b594a3367; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_versions
    ADD CONSTRAINT fk_rails_1b594a3367 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: restaurant_onboardings fk_rails_1dbda6406f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_onboardings
    ADD CONSTRAINT fk_rails_1dbda6406f FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ordrparticipant_allergyn_filters fk_rails_1dd89dec97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipant_allergyn_filters
    ADD CONSTRAINT fk_rails_1dd89dec97 FOREIGN KEY (ordrparticipant_id) REFERENCES public.ordrparticipants(id);


--
-- Name: menu_item_product_links fk_rails_283c478da0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_item_product_links
    ADD CONSTRAINT fk_rails_283c478da0 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: crm_lead_notes fk_rails_2920b340a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_notes
    ADD CONSTRAINT fk_rails_2920b340a5 FOREIGN KEY (crm_lead_id) REFERENCES public.crm_leads(id);


--
-- Name: pairing_recommendations fk_rails_296e3923e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pairing_recommendations
    ADD CONSTRAINT fk_rails_296e3923e5 FOREIGN KEY (drink_menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: tracks fk_rails_2a7a85d479; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT fk_rails_2a7a85d479 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: marketing_qr_codes fk_rails_2b27d975bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes
    ADD CONSTRAINT fk_rails_2b27d975bd FOREIGN KEY (smartmenu_id) REFERENCES public.smartmenus(id) ON DELETE SET NULL;


--
-- Name: profit_margin_targets fk_rails_2b36597cda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_margin_targets
    ADD CONSTRAINT fk_rails_2b36597cda FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: menuitem_size_mappings fk_rails_2dc87441f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_size_mappings
    ADD CONSTRAINT fk_rails_2dc87441f5 FOREIGN KEY (size_id) REFERENCES public.sizes(id);


--
-- Name: restaurant_removal_requests fk_rails_2e8cf9d8ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_removal_requests
    ADD CONSTRAINT fk_rails_2e8cf9d8ec FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: receipt_deliveries fk_rails_3009604927; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_deliveries
    ADD CONSTRAINT fk_rails_3009604927 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: payment_attempts fk_rails_3425b735a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempts
    ADD CONSTRAINT fk_rails_3425b735a0 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ordrs fk_rails_3426fe8de8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrs
    ADD CONSTRAINT fk_rails_3426fe8de8 FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: menusectionlocales fk_rails_347f3950d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menusectionlocales
    ADD CONSTRAINT fk_rails_347f3950d4 FOREIGN KEY (menusection_id) REFERENCES public.menusections(id);


--
-- Name: payment_profiles fk_rails_3b1e3db4e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_profiles
    ADD CONSTRAINT fk_rails_3b1e3db4e4 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: marketing_qr_codes fk_rails_408cb1de08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes
    ADD CONSTRAINT fk_rails_408cb1de08 FOREIGN KEY (tablesetting_id) REFERENCES public.tablesettings(id) ON DELETE SET NULL;


--
-- Name: discovered_restaurants fk_rails_43bb2593bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discovered_restaurants
    ADD CONSTRAINT fk_rails_43bb2593bb FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: push_subscriptions fk_rails_43d43720fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT fk_rails_43d43720fc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pay_charges fk_rails_44a2c276fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_charges
    ADD CONSTRAINT fk_rails_44a2c276fa FOREIGN KEY (subscription_id) REFERENCES public.pay_subscriptions(id);


--
-- Name: employees fk_rails_49811d7840; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_rails_49811d7840 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: restaurants fk_rails_4b6c394da1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT fk_rails_4b6c394da1 FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: menus fk_rails_4d07a806b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT fk_rails_4d07a806b1 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: testimonials fk_rails_4d3e46b658; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.testimonials
    ADD CONSTRAINT fk_rails_4d3e46b658 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: provider_accounts fk_rails_4d5a2754ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_accounts
    ADD CONSTRAINT fk_rails_4d5a2754ff FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ordr_split_item_assignments fk_rails_4d5b056a14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_item_assignments
    ADD CONSTRAINT fk_rails_4d5b056a14 FOREIGN KEY (ordr_split_payment_id) REFERENCES public.ordr_split_payments(id);


--
-- Name: inventories fk_rails_4dc2747426; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT fk_rails_4dc2747426 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: ordr_split_payments fk_rails_4edbb05b85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_payments
    ADD CONSTRAINT fk_rails_4edbb05b85 FOREIGN KEY (ordr_split_plan_id) REFERENCES public.ordr_split_plans(id);


--
-- Name: ordritems fk_rails_4f184e074e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritems
    ADD CONSTRAINT fk_rails_4f184e074e FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: services fk_rails_51a813203f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT fk_rails_51a813203f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: impersonation_audits fk_rails_52064a962a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_audits
    ADD CONSTRAINT fk_rails_52064a962a FOREIGN KEY (admin_user_id) REFERENCES public.users(id);


--
-- Name: product_enrichments fk_rails_523435d994; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enrichments
    ADD CONSTRAINT fk_rails_523435d994 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: menu_sources fk_rails_54571e902d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sources
    ADD CONSTRAINT fk_rails_54571e902d FOREIGN KEY (discovered_restaurant_id) REFERENCES public.discovered_restaurants(id);


--
-- Name: staff_invitations fk_rails_564d95047f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitations
    ADD CONSTRAINT fk_rails_564d95047f FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: tablesettings fk_rails_587eb463cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tablesettings
    ADD CONSTRAINT fk_rails_587eb463cf FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: restaurantlocales fk_rails_58fe7ae125; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantlocales
    ADD CONSTRAINT fk_rails_58fe7ae125 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: restaurant_subscriptions fk_rails_59c556bbd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_subscriptions
    ADD CONSTRAINT fk_rails_59c556bbd4 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: menu_edit_sessions fk_rails_5a8bc5a3cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_edit_sessions
    ADD CONSTRAINT fk_rails_5a8bc5a3cb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ocr_menu_imports fk_rails_5bc151ab22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_imports
    ADD CONSTRAINT fk_rails_5bc151ab22 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: admin_jwt_tokens fk_rails_5c18e2067b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_jwt_tokens
    ADD CONSTRAINT fk_rails_5c18e2067b FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: userplans fk_rails_666174eb65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userplans
    ADD CONSTRAINT fk_rails_666174eb65 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: userplans fk_rails_66a5e11bf7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.userplans
    ADD CONSTRAINT fk_rails_66a5e11bf7 FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: menuitem_tag_mappings fk_rails_6831d50fe2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_tag_mappings
    ADD CONSTRAINT fk_rails_6831d50fe2 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: genimages fk_rails_69d628f6bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genimages
    ADD CONSTRAINT fk_rails_69d628f6bc FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: beverage_pipeline_runs fk_rails_6b27ca4c65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beverage_pipeline_runs
    ADD CONSTRAINT fk_rails_6b27ca4c65 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: ordr_split_plans fk_rails_6ca0e7e8f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_plans
    ADD CONSTRAINT fk_rails_6ca0e7e8f1 FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id);


--
-- Name: menu_items fk_rails_6ce18aef6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT fk_rails_6ce18aef6c FOREIGN KEY (menu_section_id) REFERENCES public.menu_sections(id);


--
-- Name: ingredients fk_rails_6defac91a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT fk_rails_6defac91a6 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: jwt_token_usage_logs fk_rails_6ec5557375; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_token_usage_logs
    ADD CONSTRAINT fk_rails_6ec5557375 FOREIGN KEY (jwt_token_id) REFERENCES public.admin_jwt_tokens(id);


--
-- Name: ordr_split_item_assignments fk_rails_6efb42618b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_item_assignments
    ADD CONSTRAINT fk_rails_6efb42618b FOREIGN KEY (ordr_split_plan_id) REFERENCES public.ordr_split_plans(id);


--
-- Name: ingredients fk_rails_6f9dc24b9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT fk_rails_6f9dc24b9c FOREIGN KEY (parent_ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: pairing_recommendations fk_rails_6ff6a185a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pairing_recommendations
    ADD CONSTRAINT fk_rails_6ff6a185a1 FOREIGN KEY (food_menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: menu_item_product_links fk_rails_7045c3c899; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_item_product_links
    ADD CONSTRAINT fk_rails_7045c3c899 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: ordrs fk_rails_70b0a22d0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrs
    ADD CONSTRAINT fk_rails_70b0a22d0b FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: ocr_menu_items fk_rails_713e4767df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_items
    ADD CONSTRAINT fk_rails_713e4767df FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: ordrnotes fk_rails_715c81f2e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrnotes
    ADD CONSTRAINT fk_rails_715c81f2e4 FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: payment_refunds fk_rails_74300a0512; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_refunds
    ADD CONSTRAINT fk_rails_74300a0512 FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: ordractions fk_rails_753c8bf1bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordractions
    ADD CONSTRAINT fk_rails_753c8bf1bb FOREIGN KEY (ordrparticipant_id) REFERENCES public.ordrparticipants(id);


--
-- Name: beverage_pipeline_runs fk_rails_77e813c0f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beverage_pipeline_runs
    ADD CONSTRAINT fk_rails_77e813c0f3 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: marketing_qr_codes fk_rails_78dcd93826; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes
    ADD CONSTRAINT fk_rails_78dcd93826 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: similar_product_recommendations fk_rails_7be23a6159; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.similar_product_recommendations
    ADD CONSTRAINT fk_rails_7be23a6159 FOREIGN KEY (recommended_product_id) REFERENCES public.products(id);


--
-- Name: ordr_split_plans fk_rails_7c0b052f79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_plans
    ADD CONSTRAINT fk_rails_7c0b052f79 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: ordrparticipants fk_rails_7cc8425445; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipants
    ADD CONSTRAINT fk_rails_7cc8425445 FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: alcohol_order_events fk_rails_7e8a4494ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_order_events
    ADD CONSTRAINT fk_rails_7e8a4494ce FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: ordr_station_tickets fk_rails_7ef0e690e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_station_tickets
    ADD CONSTRAINT fk_rails_7ef0e690e7 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: marketing_qr_codes fk_rails_7f847c7d02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_qr_codes
    ADD CONSTRAINT fk_rails_7f847c7d02 FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE SET NULL;


--
-- Name: menuitem_costs fk_rails_8001b406b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_costs
    ADD CONSTRAINT fk_rails_8001b406b2 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id) ON DELETE CASCADE;


--
-- Name: alcohol_order_events fk_rails_83023d3e45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_order_events
    ADD CONSTRAINT fk_rails_83023d3e45 FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: crm_leads fk_rails_86438a87b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_leads
    ADD CONSTRAINT fk_rails_86438a87b4 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: menulocales fk_rails_8648fef0b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menulocales
    ADD CONSTRAINT fk_rails_8648fef0b6 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: resource_locks fk_rails_8a053aeee9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_locks
    ADD CONSTRAINT fk_rails_8a053aeee9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: menuitem_allergyn_mappings fk_rails_8c75c95956; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_allergyn_mappings
    ADD CONSTRAINT fk_rails_8c75c95956 FOREIGN KEY (allergyn_id) REFERENCES public.allergyns(id);


--
-- Name: payment_attempts fk_rails_8cfe1b838d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempts
    ADD CONSTRAINT fk_rails_8cfe1b838d FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: crm_email_sends fk_rails_8e2b9d9c0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_email_sends
    ADD CONSTRAINT fk_rails_8e2b9d9c0b FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: restaurant_menus fk_rails_900dac8822; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_menus
    ADD CONSTRAINT fk_rails_900dac8822 FOREIGN KEY (archived_by_id) REFERENCES public.users(id);


--
-- Name: features_plans fk_rails_90e2063c37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.features_plans
    ADD CONSTRAINT fk_rails_90e2063c37 FOREIGN KEY (feature_id) REFERENCES public.features(id);


--
-- Name: menuitem_tag_mappings fk_rails_9156e4156b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_tag_mappings
    ADD CONSTRAINT fk_rails_9156e4156b FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: ordrs fk_rails_91ba63bb67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrs
    ADD CONSTRAINT fk_rails_91ba63bb67 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: alcohol_order_events fk_rails_93c7dd408f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_order_events
    ADD CONSTRAINT fk_rails_93c7dd408f FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: crm_lead_notes fk_rails_9e8c428264; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_notes
    ADD CONSTRAINT fk_rails_9e8c428264 FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: menu_source_change_reviews fk_rails_9ee428ffe6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_source_change_reviews
    ADD CONSTRAINT fk_rails_9ee428ffe6 FOREIGN KEY (menu_source_id) REFERENCES public.menu_sources(id);


--
-- Name: user_sessions fk_rails_9fa262d742; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_rails_9fa262d742 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: onboarding_sessions fk_rails_a120d6797d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onboarding_sessions
    ADD CONSTRAINT fk_rails_a120d6797d FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: menuitem_allergyn_mappings fk_rails_a1c78d8521; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_allergyn_mappings
    ADD CONSTRAINT fk_rails_a1c78d8521 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: menuparticipants fk_rails_a255716a53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuparticipants
    ADD CONSTRAINT fk_rails_a255716a53 FOREIGN KEY (smartmenu_id) REFERENCES public.smartmenus(id);


--
-- Name: profit_margin_targets fk_rails_a2cf07c710; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_margin_targets
    ADD CONSTRAINT fk_rails_a2cf07c710 FOREIGN KEY (menusection_id) REFERENCES public.menusections(id) ON DELETE CASCADE;


--
-- Name: restaurant_menus fk_rails_a4fec423e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_menus
    ADD CONSTRAINT fk_rails_a4fec423e9 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: menu_imports fk_rails_a527c83389; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_imports
    ADD CONSTRAINT fk_rails_a527c83389 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: menuitem_ingredient_mappings fk_rails_a595a8024b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_mappings
    ADD CONSTRAINT fk_rails_a595a8024b FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: ordritems fk_rails_a59721da40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritems
    ADD CONSTRAINT fk_rails_a59721da40 FOREIGN KEY (ordr_station_ticket_id) REFERENCES public.ordr_station_tickets(id);


--
-- Name: genimages fk_rails_a62167abbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genimages
    ADD CONSTRAINT fk_rails_a62167abbe FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: restaurant_menus fk_rails_a6569ec805; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_menus
    ADD CONSTRAINT fk_rails_a6569ec805 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: restaurant_claim_requests fk_rails_a714799fb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claim_requests
    ADD CONSTRAINT fk_rails_a714799fb8 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: profit_margin_targets fk_rails_a752280ab2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_margin_targets
    ADD CONSTRAINT fk_rails_a752280ab2 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id) ON DELETE CASCADE;


--
-- Name: menu_sections fk_rails_a915680585; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sections
    ADD CONSTRAINT fk_rails_a915680585 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: menu_edit_sessions fk_rails_abceb11a0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_edit_sessions
    ADD CONSTRAINT fk_rails_abceb11a0e FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: ordr_split_payments fk_rails_ac25e084c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_payments
    ADD CONSTRAINT fk_rails_ac25e084c8 FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: smartmenus fk_rails_acf54119ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smartmenus
    ADD CONSTRAINT fk_rails_acf54119ab FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: sizes fk_rails_ad38f24c5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sizes
    ADD CONSTRAINT fk_rails_ad38f24c5e FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: dining_sessions fk_rails_ad7a6a606e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dining_sessions
    ADD CONSTRAINT fk_rails_ad7a6a606e FOREIGN KEY (smartmenu_id) REFERENCES public.smartmenus(id);


--
-- Name: ocr_menu_items fk_rails_ae1a643b10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_items
    ADD CONSTRAINT fk_rails_ae1a643b10 FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id);


--
-- Name: restaurants fk_rails_aef57e41ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT fk_rails_aef57e41ec FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: old_passwords fk_rails_b03aadf864; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.old_passwords
    ADD CONSTRAINT fk_rails_b03aadf864 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pay_charges fk_rails_b19d32f835; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_charges
    ADD CONSTRAINT fk_rails_b19d32f835 FOREIGN KEY (customer_id) REFERENCES public.pay_customers(id);


--
-- Name: menusections fk_rails_b1a53ba6e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menusections
    ADD CONSTRAINT fk_rails_b1a53ba6e4 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: crm_leads fk_rails_b327454a7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_leads
    ADD CONSTRAINT fk_rails_b327454a7d FOREIGN KEY (assigned_to_id) REFERENCES public.users(id);


--
-- Name: genimages fk_rails_b5396a358a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genimages
    ADD CONSTRAINT fk_rails_b5396a358a FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: menuitem_costs fk_rails_b57d75e9eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_costs
    ADD CONSTRAINT fk_rails_b57d75e9eb FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: pay_subscriptions fk_rails_b7cd64d378; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_subscriptions
    ADD CONSTRAINT fk_rails_b7cd64d378 FOREIGN KEY (customer_id) REFERENCES public.pay_customers(id);


--
-- Name: allergyns fk_rails_b93ea7a952; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allergyns
    ADD CONSTRAINT fk_rails_b93ea7a952 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: restaurant_claim_requests fk_rails_b9862dbad9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claim_requests
    ADD CONSTRAINT fk_rails_b9862dbad9 FOREIGN KEY (reviewed_by_user_id) REFERENCES public.users(id);


--
-- Name: crawl_source_rules fk_rails_bb7f7af677; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crawl_source_rules
    ADD CONSTRAINT fk_rails_bb7f7af677 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: ordr_split_plans fk_rails_bbaa683853; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_plans
    ADD CONSTRAINT fk_rails_bbaa683853 FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: ordr_split_payments fk_rails_bcc4fc31f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_split_payments
    ADD CONSTRAINT fk_rails_bcc4fc31f2 FOREIGN KEY (ordrparticipant_id) REFERENCES public.ordrparticipants(id);


--
-- Name: alcohol_policies fk_rails_bd4e13bd21; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_policies
    ADD CONSTRAINT fk_rails_bd4e13bd21 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: impersonation_audits fk_rails_c02a97b796; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impersonation_audits
    ADD CONSTRAINT fk_rails_c02a97b796 FOREIGN KEY (impersonated_user_id) REFERENCES public.users(id);


--
-- Name: restaurant_removal_requests fk_rails_c1263edfca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_removal_requests
    ADD CONSTRAINT fk_rails_c1263edfca FOREIGN KEY (actioned_by_user_id) REFERENCES public.users(id);


--
-- Name: menuitem_ingredient_mappings fk_rails_c19699c686; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_mappings
    ADD CONSTRAINT fk_rails_c19699c686 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: order_events fk_rails_c2e4e152a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_events
    ADD CONSTRAINT fk_rails_c2e4e152a7 FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: ordrparticipant_allergyn_filters fk_rails_c560167c17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipant_allergyn_filters
    ADD CONSTRAINT fk_rails_c560167c17 FOREIGN KEY (allergyn_id) REFERENCES public.allergyns(id);


--
-- Name: crm_lead_audits fk_rails_c5f1c0dde0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_audits
    ADD CONSTRAINT fk_rails_c5f1c0dde0 FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: ocr_menu_sections fk_rails_c5f9dbae67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_sections
    ADD CONSTRAINT fk_rails_c5f9dbae67 FOREIGN KEY (menusection_id) REFERENCES public.menusections(id);


--
-- Name: dining_sessions fk_rails_c6bdf83dde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dining_sessions
    ADD CONSTRAINT fk_rails_c6bdf83dde FOREIGN KEY (tablesetting_id) REFERENCES public.tablesettings(id);


--
-- Name: pay_payment_methods fk_rails_c78c6cb84d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pay_payment_methods
    ADD CONSTRAINT fk_rails_c78c6cb84d FOREIGN KEY (customer_id) REFERENCES public.pay_customers(id);


--
-- Name: menu_sources fk_rails_c8406e782b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_sources
    ADD CONSTRAINT fk_rails_c8406e782b FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: menuavailabilities fk_rails_caa572a39a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuavailabilities
    ADD CONSTRAINT fk_rails_caa572a39a FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: staff_invitations fk_rails_cdac8f95ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_invitations
    ADD CONSTRAINT fk_rails_cdac8f95ea FOREIGN KEY (invited_by_id) REFERENCES public.users(id);


--
-- Name: smartmenus fk_rails_cf4299746e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smartmenus
    ADD CONSTRAINT fk_rails_cf4299746e FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: taxes fk_rails_cfbb60e880; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT fk_rails_cfbb60e880 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ocr_menu_sections fk_rails_cfdd8a28c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_sections
    ADD CONSTRAINT fk_rails_cfdd8a28c6 FOREIGN KEY (menu_section_id) REFERENCES public.menu_sections(id);


--
-- Name: menus fk_rails_d19335e7f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT fk_rails_d19335e7f8 FOREIGN KEY (owner_restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: tips fk_rails_d26e612cb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tips
    ADD CONSTRAINT fk_rails_d26e612cb3 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ocr_menu_imports fk_rails_d58e8d1ce3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ocr_menu_imports
    ADD CONSTRAINT fk_rails_d58e8d1ce3 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: ordrs fk_rails_d78f912a34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrs
    ADD CONSTRAINT fk_rails_d78f912a34 FOREIGN KEY (tablesetting_id) REFERENCES public.tablesettings(id);


--
-- Name: ordritemnotes fk_rails_d7e0ca74e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordritemnotes
    ADD CONSTRAINT fk_rails_d7e0ca74e0 FOREIGN KEY (ordritem_id) REFERENCES public.ordritems(id);


--
-- Name: admin_jwt_tokens fk_rails_d9412e59ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_jwt_tokens
    ADD CONSTRAINT fk_rails_d9412e59ea FOREIGN KEY (admin_user_id) REFERENCES public.users(id);


--
-- Name: menuitem_ingredient_quantities fk_rails_da6c3805c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_quantities
    ADD CONSTRAINT fk_rails_da6c3805c1 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id) ON DELETE CASCADE;


--
-- Name: crm_email_sends fk_rails_dcb963d670; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_email_sends
    ADD CONSTRAINT fk_rails_dcb963d670 FOREIGN KEY (crm_lead_id) REFERENCES public.crm_leads(id);


--
-- Name: employees fk_rails_dcfd3d4fc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_rails_dcfd3d4fc3 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_refunds fk_rails_dda3ea39de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_refunds
    ADD CONSTRAINT fk_rails_dda3ea39de FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ordr_station_tickets fk_rails_de8a2f319d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordr_station_tickets
    ADD CONSTRAINT fk_rails_de8a2f319d FOREIGN KEY (ordr_id) REFERENCES public.ordrs(id);


--
-- Name: menuitem_ingredient_quantities fk_rails_df81b8329c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_ingredient_quantities
    ADD CONSTRAINT fk_rails_df81b8329c FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- Name: menuitemlocales fk_rails_e09be4d4b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitemlocales
    ADD CONSTRAINT fk_rails_e09be4d4b3 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: whiskey_flights fk_rails_e1c487eb31; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whiskey_flights
    ADD CONSTRAINT fk_rails_e1c487eb31 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: menus fk_rails_e5768e875c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT fk_rails_e5768e875c FOREIGN KEY (menu_import_id) REFERENCES public.menu_imports(id);


--
-- Name: testimonials fk_rails_e59666453f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.testimonials
    ADD CONSTRAINT fk_rails_e59666453f FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: alcohol_order_events fk_rails_e647589a44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alcohol_order_events
    ADD CONSTRAINT fk_rails_e647589a44 FOREIGN KEY (ordritem_id) REFERENCES public.ordritems(id);


--
-- Name: restaurant_claim_requests fk_rails_e80cd502e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claim_requests
    ADD CONSTRAINT fk_rails_e80cd502e3 FOREIGN KEY (initiated_by_user_id) REFERENCES public.users(id);


--
-- Name: performance_metrics fk_rails_e85e631e6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_metrics
    ADD CONSTRAINT fk_rails_e85e631e6b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_refunds fk_rails_eca5fdc0ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_refunds
    ADD CONSTRAINT fk_rails_eca5fdc0ae FOREIGN KEY (payment_attempt_id) REFERENCES public.payment_attempts(id);


--
-- Name: onboarding_sessions fk_rails_ee40ebe70e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onboarding_sessions
    ADD CONSTRAINT fk_rails_ee40ebe70e FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: ordrparticipants fk_rails_f3dae537ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordrparticipants
    ADD CONSTRAINT fk_rails_f3dae537ff FOREIGN KEY (ordritem_id) REFERENCES public.ordritems(id);


--
-- Name: genimages fk_rails_f68483113d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genimages
    ADD CONSTRAINT fk_rails_f68483113d FOREIGN KEY (menusection_id) REFERENCES public.menusections(id);


--
-- Name: menuitems fk_rails_f6916ee8f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitems
    ADD CONSTRAINT fk_rails_f6916ee8f3 FOREIGN KEY (menusection_id) REFERENCES public.menusections(id);


--
-- Name: menu_versions fk_rails_f750ec91a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_versions
    ADD CONSTRAINT fk_rails_f750ec91a3 FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: crm_lead_audits fk_rails_fb30938bf5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crm_lead_audits
    ADD CONSTRAINT fk_rails_fb30938bf5 FOREIGN KEY (crm_lead_id) REFERENCES public.crm_leads(id);


--
-- Name: menuitem_size_mappings fk_rails_fc0cb35a04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menuitem_size_mappings
    ADD CONSTRAINT fk_rails_fc0cb35a04 FOREIGN KEY (menuitem_id) REFERENCES public.menuitems(id);


--
-- Name: restaurantavailabilities fk_rails_fcb95e3c67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurantavailabilities
    ADD CONSTRAINT fk_rails_fcb95e3c67 FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: voice_commands fk_rails_ffd8a93481; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_commands
    ADD CONSTRAINT fk_rails_ffd8a93481 FOREIGN KEY (smartmenu_id) REFERENCES public.smartmenus(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260327200004'),
('20260327200003'),
('20260327200002'),
('20260327200001'),
('20260327100002'),
('20260327100001'),
('20260326194824'),
('20260326194817'),
('20260325195401'),
('20260325120000'),
('20260325094758'),
('20260324132133'),
('20260324132112'),
('20260324132048'),
('20260317090311'),
('20260317003953'),
('20260317003900'),
('20260317003803'),
('20260317003723'),
('20260316232500'),
('20260316231830'),
('20260316231707'),
('20260309184831'),
('20260308084502'),
('20260308084501'),
('20260308084500'),
('20260306154839'),
('20260306124845'),
('20260305080000'),
('20260304230100'),
('20260304230000'),
('20260304224700'),
('20260304220000'),
('20260226150000'),
('20260225183232'),
('20260224171903'),
('20260222100000'),
('20260221210752'),
('20260220213701'),
('20260220213700'),
('20260219220838'),
('20260219175455'),
('20260218180140'),
('20260218175553'),
('20260218174652'),
('20260216090000'),
('20260215223253'),
('20260211194831'),
('20260211171600'),
('20260211171500'),
('20260211171400'),
('20260211171300'),
('20260211171200'),
('20260211171100'),
('20260211142805'),
('20260210170000'),
('20260210165000'),
('20260210164500'),
('20260210161000'),
('20260210153000'),
('20260209202500'),
('20260209200500'),
('20260209195600'),
('20260209195500'),
('20260209194400'),
('20260209093000'),
('20260209091500'),
('20260205183500'),
('20260205123000'),
('202602051000'),
('20260204122000'),
('20260130120000'),
('20260126183000'),
('20260126170000'),
('20260124100000'),
('20260123103300'),
('20260122210000'),
('20260121230600'),
('20260121222200'),
('20260121221000'),
('20260119183500'),
('20260119180000'),
('20260119114800'),
('20260117160000'),
('20260117100300'),
('20260117100000'),
('20260112190000'),
('20260109180630'),
('20260109180600'),
('20260109170000'),
('20260106170800'),
('20260106170700'),
('20260105152500'),
('20260105113200'),
('20251227083000'),
('20251223181100'),
('20251222131700'),
('202511231100'),
('202511230003'),
('202511230002'),
('202511230001'),
('20251121182000'),
('20251119102000'),
('20251116174928'),
('20251028151017'),
('20251023205430'),
('20251019214400'),
('20251019214351'),
('20251019214341'),
('20251019203820'),
('20251015205345'),
('20251012172730'),
('20251012172721'),
('20251012172711'),
('20251005181034'),
('20251004222429'),
('20251004222350'),
('20251004222306'),
('20251004222222'),
('20250929172225'),
('20250928201829'),
('20250928190500'),
('20250924181009'),
('20250923211912'),
('20250922204000'),
('20250920104530'),
('20250916215000'),
('20250916203813'),
('20250916201742'),
('20250916201628'),
('20250916201621'),
('20250916201613'),
('20250914153926'),
('20250830185212'),
('20250830164200'),
('20250830164000'),
('20250830163550'),
('20250830163251'),
('20250830163236'),
('20250830152739'),
('20250830152553'),
('20250830150431'),
('20250822223600'),
('20250822203207'),
('20250822163249'),
('20250822161255'),
('20250822161030'),
('20250821183651'),
('20250821181758'),
('20250821180322'),
('20250706143650'),
('20250703181508'),
('20250606080125'),
('20250604165129'),
('20250603200708'),
('20250530152632'),
('20250526153035'),
('20250522190416'),
('20250520172627'),
('20250519153629'),
('20250517154822'),
('20250506155159'),
('20250428082635'),
('20250428082415'),
('20250428082314'),
('20250425175616'),
('20250418164623'),
('20250418164556'),
('20250414162432'),
('20250408135053'),
('20250407183109'),
('20250407183017'),
('20250312190107'),
('20250215171433'),
('20250208110821'),
('20250205124601'),
('20250204172505'),
('20250128205511'),
('20250119201408'),
('20250116205343'),
('20250112213653'),
('20250108181710'),
('20250108181709'),
('20241225121022'),
('20241225121006'),
('20241206162715'),
('20241206145557'),
('20241206135744'),
('20241206133900'),
('20241206110108'),
('20241117141328'),
('20240826220000'),
('20240704150255'),
('20240701172251'),
('20240623160909'),
('20240623155320'),
('20240615183050'),
('20240615182707'),
('20240608205504'),
('20240526171302'),
('20240526165354'),
('20240525203753'),
('20240524144646'),
('20240508130848'),
('20240504161450'),
('20240427074006'),
('20240417195922'),
('20240414161841'),
('20240414062151'),
('20240407112523'),
('20240406170235'),
('20240406163730'),
('20240406153155'),
('20240406121456'),
('20240404185504'),
('20240330225111'),
('20240330153424'),
('20240329181528'),
('20240329170029'),
('20240329164322'),
('20240329164225'),
('20240329163253'),
('20240329162858'),
('20240328193226'),
('20240324143328'),
('20240324075544'),
('20240323121314'),
('20240320233404'),
('20240320155033'),
('20240320152447'),
('20240320152349'),
('20240319142546'),
('20240319130024'),
('20240318174858'),
('20240318174744'),
('20240318082824'),
('20240318082315'),
('20240318081456'),
('20240318081250'),
('20240308173932'),
('20240308173615'),
('20240308105203'),
('20240308103532'),
('20240229134137'),
('20240229134134'),
('20240229134132'),
('20240229134130'),
('20240229134128'),
('20240229134127'),
('20240229134125'),
('20240229134123'),
('20240229134121'),
('20240229134119'),
('20240229134117'),
('20240229134115'),
('20240229123035'),
('20240229123010'),
('20240229123009'),
('20240229123008'),
('20240229123007'),
('20240229123005'),
('20240229122955'),
('20230815163418'),
('20230815163417'),
('20230815163416');

