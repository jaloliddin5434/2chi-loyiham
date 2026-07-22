--
-- PostgreSQL database dump
--

\restrict g9zhlnoIUAIDZMAKfRX9SHWUkyXE8Z6M13s1SipRR6DRnEa3JzekgCDRYDHAW9Z

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hujjat_holati_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.hujjat_holati_enum AS ENUM (
    'jarayon',
    'tugallandi',
    'bekor'
);


ALTER TYPE public.hujjat_holati_enum OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: hujjat_raqam_hisoblagich; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hujjat_raqam_hisoblagich (
    yil integer NOT NULL,
    oxirgi_raqam integer
);


ALTER TABLE public.hujjat_raqam_hisoblagich OWNER TO postgres;

--
-- Name: hujjat_raqam_hisoblagich_yil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hujjat_raqam_hisoblagich_yil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hujjat_raqam_hisoblagich_yil_seq OWNER TO postgres;

--
-- Name: hujjat_raqam_hisoblagich_yil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hujjat_raqam_hisoblagich_yil_seq OWNED BY public.hujjat_raqam_hisoblagich.yil;


--
-- Name: hujjatlar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hujjatlar (
    id integer NOT NULL,
    raqam character varying,
    mashina_id integer,
    mahsulot_id integer,
    operator_id integer,
    aravalar_soni integer,
    tuda_raqam character varying,
    texnik_chiqit character varying,
    sanoat_turi character varying,
    klassifikatsiya character varying,
    davomlilik_raqam character varying,
    davomlilik_dan character varying,
    davomlilik_gacha character varying,
    yuk_oluvchi character varying,
    shartnoma character varying,
    holat public.hujjat_holati_enum DEFAULT 'jarayon'::public.hujjat_holati_enum NOT NULL,
    bekor_sabab text,
    created_at timestamp without time zone
);


ALTER TABLE public.hujjatlar OWNER TO postgres;

--
-- Name: hujjatlar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hujjatlar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hujjatlar_id_seq OWNER TO postgres;

--
-- Name: hujjatlar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hujjatlar_id_seq OWNED BY public.hujjatlar.id;


--
-- Name: mahsulotlar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mahsulotlar (
    id integer NOT NULL,
    nom character varying,
    konditsiya_bor boolean,
    is_active boolean
);


ALTER TABLE public.mahsulotlar OWNER TO postgres;

--
-- Name: mahsulotlar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mahsulotlar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mahsulotlar_id_seq OWNER TO postgres;

--
-- Name: mahsulotlar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mahsulotlar_id_seq OWNED BY public.mahsulotlar.id;


--
-- Name: mashinalar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mashinalar (
    id integer NOT NULL,
    davlat_raqami character varying,
    turi character varying,
    shofyor character varying,
    firma character varying,
    viloyat character varying,
    telefon character varying
);


ALTER TABLE public.mashinalar OWNER TO postgres;

--
-- Name: mashinalar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mashinalar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mashinalar_id_seq OWNER TO postgres;

--
-- Name: mashinalar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mashinalar_id_seq OWNED BY public.mashinalar.id;


--
-- Name: navbat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.navbat (
    id integer NOT NULL,
    hujjat_id integer,
    mashina_id integer,
    raqam character varying,
    turi character varying,
    shofyor character varying,
    firma character varying,
    mahsulot_id integer,
    mahsulot_nomi character varying,
    vaqt character varying,
    kelgan_vaqt timestamp without time zone,
    tuda_raqam character varying,
    tiket_raqam character varying,
    seleksiya_navi character varying,
    klass character varying,
    sinf character varying,
    terim_turi character varying,
    namlik double precision,
    ifloslik double precision,
    tugallandi boolean,
    tugallangan_vaqt timestamp without time zone,
    aravalar_json text,
    created_at timestamp without time zone
);


ALTER TABLE public.navbat OWNER TO postgres;

--
-- Name: navbat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.navbat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.navbat_id_seq OWNER TO postgres;

--
-- Name: navbat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.navbat_id_seq OWNED BY public.navbat.id;


--
-- Name: olchovlar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.olchovlar (
    id integer NOT NULL,
    hujjat_id integer,
    arava_raqam integer,
    tara double precision,
    brutto double precision,
    netto double precision,
    namlik double precision,
    ifloslik double precision,
    konditsion double precision,
    tara_rasm character varying,
    brutto_rasm character varying,
    qolda_kiritildi boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.olchovlar OWNER TO postgres;

--
-- Name: olchovlar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.olchovlar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.olchovlar_id_seq OWNER TO postgres;

--
-- Name: olchovlar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.olchovlar_id_seq OWNED BY public.olchovlar.id;


--
-- Name: sozlamalar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sozlamalar (
    id integer NOT NULL,
    kalit character varying,
    qiymat text,
    updated_at timestamp without time zone
);


ALTER TABLE public.sozlamalar OWNER TO postgres;

--
-- Name: sozlamalar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sozlamalar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sozlamalar_id_seq OWNER TO postgres;

--
-- Name: sozlamalar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sozlamalar_id_seq OWNED BY public.sozlamalar.id;


--
-- Name: tizim_xatolari; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tizim_xatolari (
    id integer NOT NULL,
    turi character varying,
    xabar text,
    korilgan boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.tizim_xatolari OWNER TO postgres;

--
-- Name: tizim_xatolari_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tizim_xatolari_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tizim_xatolari_id_seq OWNER TO postgres;

--
-- Name: tizim_xatolari_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tizim_xatolari_id_seq OWNED BY public.tizim_xatolari.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying,
    password character varying,
    role character varying,
    is_active boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: hujjat_raqam_hisoblagich yil; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hujjat_raqam_hisoblagich ALTER COLUMN yil SET DEFAULT nextval('public.hujjat_raqam_hisoblagich_yil_seq'::regclass);


--
-- Name: hujjatlar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hujjatlar ALTER COLUMN id SET DEFAULT nextval('public.hujjatlar_id_seq'::regclass);


--
-- Name: mahsulotlar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mahsulotlar ALTER COLUMN id SET DEFAULT nextval('public.mahsulotlar_id_seq'::regclass);


--
-- Name: mashinalar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mashinalar ALTER COLUMN id SET DEFAULT nextval('public.mashinalar_id_seq'::regclass);


--
-- Name: navbat id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navbat ALTER COLUMN id SET DEFAULT nextval('public.navbat_id_seq'::regclass);


--
-- Name: olchovlar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.olchovlar ALTER COLUMN id SET DEFAULT nextval('public.olchovlar_id_seq'::regclass);


--
-- Name: sozlamalar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sozlamalar ALTER COLUMN id SET DEFAULT nextval('public.sozlamalar_id_seq'::regclass);


--
-- Name: tizim_xatolari id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tizim_xatolari ALTER COLUMN id SET DEFAULT nextval('public.tizim_xatolari_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: hujjat_raqam_hisoblagich; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hujjat_raqam_hisoblagich (yil, oxirgi_raqam) FROM stdin;
2026	264
\.


--
-- Data for Name: hujjatlar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hujjatlar (id, raqam, mashina_id, mahsulot_id, operator_id, aravalar_soni, tuda_raqam, texnik_chiqit, sanoat_turi, klassifikatsiya, davomlilik_raqam, davomlilik_dan, davomlilik_gacha, yuk_oluvchi, shartnoma, holat, bekor_sabab, created_at) FROM stdin;
2	2026/002	3	1	\N	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-01 14:34:16.25283
3	2026/003	4	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-01 15:46:31.743693
4	2026/004	5	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-01 15:58:33.18431
5	2026/005	6	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-01 16:46:46.718696
6	2026/006	7	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-01 17:15:46.615374
7	2026/007	8	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-01 17:32:50.422572
8	2026/008	9	1	\N	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-02 10:23:19.276044
9	2026/009	10	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-02 10:49:11.829819
10	2026/010	11	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-02 11:07:55.445522
11	2026/011	12	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-02 11:20:37.950013
12	2026/012	13	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-02 11:42:27.707012
13	2026/013	14	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-02 14:30:40.762044
14	2026/014	15	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 09:00:45.544653
15	2026/015	16	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 09:19:01.243675
16	2026/016	17	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 09:42:25.737606
17	2026/017	18	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 09:52:03.139458
18	2026/018	19	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 10:06:53.261387
19	2026/019	20	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 14:06:01.654629
20	2026/020	21	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-03 14:23:32.155791
21	2026/021	22	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-04 08:59:54.049195
22	2026/022	23	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-04 09:42:03.804766
23	2026/023	24	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-05 11:15:19.645536
24	2026/024	25	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-05 11:17:22.932494
25	2026/025	26	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-05 11:33:04.659207
26	2026/026	27	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-06 09:26:04.417501
27	2026/027	17	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-06 10:01:12.000441
28	2026/028	28	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-06 10:52:46.778773
29	2026/029	29	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-06 10:54:50.691278
30	2026/030	30	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-07 08:57:46.351047
31	2026/031	31	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-07 09:09:41.328446
32	2026/032	32	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-07 12:20:01.253674
33	2026/033	33	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-07 13:08:40.672955
34	2026/034	34	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-07 14:56:39.103043
35	2026/035	35	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 09:22:34.225169
36	2026/036	31	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 09:31:06.112848
37	2026/037	36	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 15:03:21.602971
38	2026/038	37	2	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 15:14:02.718661
39	2026/039	38	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 15:34:29.515832
40	2026/040	39	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 15:36:15.562519
41	2026/041	34	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 15:38:18.103472
42	2026/042	40	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-08 15:39:46.231682
43	2026/043	41	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 13:55:31.530613
44	2026/044	42	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 13:59:43.105718
45	2026/045	43	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 14:02:42.455405
46	2026/046	44	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 14:15:15.070667
47	2026/047	45	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 14:59:02.598087
48	2026/048	42	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 14:59:55.852347
49	2026/049	46	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 15:26:26.142941
50	2026/050	47	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 15:42:09.612278
51	2026/051	48	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-09 15:49:51.92485
52	2026/052	49	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 09:01:20.096321
53	2026/053	50	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 09:12:29.030733
54	2026/054	44	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 09:20:33.90887
55	2026/055	36	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 13:51:51.002827
56	2026/056	51	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 14:03:14.036336
57	2026/057	52	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 15:20:19.583012
58	2026/058	53	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 15:27:13.809727
59	2026/059	44	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 15:33:42.651821
60	2026/060	2	1	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-10 15:39:22.458093
61	2026/061	54	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-11 10:08:47.290533
62	2026/062	55	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-11 10:09:32.486076
63	2026/063	49	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-11 10:55:31.138505
65	2026/064	56	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-11 10:56:45.774068
66	2026/065	57	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-11 11:05:04.769846
67	2026/066	58	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-11 11:12:41.636929
68	2026/067	59	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-12 12:00:56.118666
69	2026/068	60	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-12 12:19:54.615294
70	2026/069	61	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-12 12:27:21.142344
71	2026/070	62	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-12 12:33:49.727188
72	2026/071	42	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 08:19:26.318438
73	2026/072	54	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 08:20:45.970221
74	2026/073	63	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 08:30:55.291672
75	2026/074	64	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 08:53:01.629175
76	2026/075	65	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:03:08.056331
77	2026/076	66	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:09:29.530548
78	2026/077	67	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:17:44.763886
79	2026/078	68	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:26:46.231447
80	2026/079	69	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:35:01.98409
81	2026/080	70	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:40:53.612754
82	2026/081	71	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 09:51:29.084612
83	2026/082	72	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 10:02:00.833654
84	2026/083	73	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 10:11:30.680166
85	2026/084	74	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 10:18:19.430067
86	2026/085	75	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:01:34.958567
87	2026/086	76	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:10:53.172082
88	2026/087	77	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:22:51.456865
89	2026/088	78	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:31:07.505621
90	2026/089	79	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:41:21.432253
91	2026/090	17	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:46:22.923227
92	2026/091	80	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 14:57:20.150793
93	2026/092	81	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 15:07:32.28107
94	2026/093	82	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 15:23:57.922512
95	2026/094	83	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 15:27:49.962487
96	2026/095	84	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 15:38:12.646782
97	2026/096	85	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 15:43:20.005338
98	2026/097	86	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 15:52:34.123514
99	2026/098	87	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 16:10:23.624864
100	2026/099	88	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 16:16:27.464936
101	2026/100	2	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-13 16:32:07.907953
102	2026/101	89	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 08:11:56.959749
103	2026/102	90	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 08:18:55.669843
104	2026/103	91	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 08:23:59.339484
105	2026/104	92	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 08:28:36.613393
106	2026/105	76	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 08:34:29.182656
107	2026/106	93	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 08:43:17.483705
108	2026/107	94	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 10:34:58.762325
109	2026/108	53	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 10:45:18.180457
110	2026/109	95	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 10:56:53.170679
111	2026/110	96	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:05:02.963964
112	2026/111	97	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:12:05.025595
113	2026/112	98	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:15:48.627228
114	2026/113	99	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:18:34.368769
115	2026/114	100	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:33:33.903723
116	2026/115	101	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:40:59.829034
117	2026/116	102	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:44:04.229478
118	2026/117	103	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:44:38.275296
119	2026/118	104	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 11:47:39.323037
120	2026/119	105	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 12:05:28.754764
121	2026/120	106	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 12:07:44.927158
122	2026/121	107	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:10:16.864585
123	2026/122	108	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:13:05.363119
124	2026/123	109	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:17:11.749124
125	2026/124	110	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:27:10.381235
126	2026/125	111	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:29:26.656479
127	2026/126	112	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:30:39.13504
128	2026/127	113	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:36:24.885669
129	2026/128	114	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:40:08.522196
130	2026/129	115	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 13:49:48.431713
131	2026/130	116	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:07:29.480639
132	2026/131	117	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:22:12.690748
133	2026/132	118	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:22:52.700019
134	2026/133	119	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:37:40.917775
135	2026/134	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:44:13.528815
136	2026/135	121	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:45:03.371393
137	2026/136	122	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:46:49.534014
138	2026/137	123	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:47:39.149527
139	2026/138	124	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 14:56:08.281347
140	2026/139	125	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:06:14.868828
141	2026/140	122	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:07:49.828565
142	2026/141	126	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:29:25.031883
143	2026/142	95	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:31:38.925022
144	2026/143	127	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:33:38.934468
145	2026/144	128	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:37:09.468965
146	2026/145	129	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:38:11.099911
147	2026/146	95	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:39:19.813308
148	2026/147	130	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-14 15:49:01.740319
149	2026/148	127	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 10:31:41.933448
150	2026/149	131	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 10:32:57.526486
151	2026/150	132	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 13:58:15.459266
152	2026/151	133	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 14:18:01.71569
153	2026/152	134	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 14:26:42.685919
154	2026/153	135	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 14:34:43.345267
155	2026/154	95	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 14:39:34.890147
156	2026/155	136	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 14:53:55.640854
157	2026/156	137	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:08:16.374009
158	2026/157	127	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:20:12.933822
159	2026/158	115	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:21:41.503489
160	2026/159	138	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:30:49.949529
161	2026/160	139	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:35:29.017583
162	2026/161	140	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:44:17.112293
163	2026/162	141	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:49:33.165782
164	2026/163	142	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-15 15:59:43.94367
165	2026/164	139	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 09:26:40.662363
166	2026/165	127	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 09:28:22.412216
167	2026/166	131	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 09:37:31.522403
168	2026/167	142	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 09:40:12.174308
169	2026/168	143	4	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 09:49:01.175484
170	2026/169	144	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 09:56:49.867415
171	2026/170	145	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:14:32.278345
172	2026/171	146	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:20:24.540915
173	2026/172	147	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:23:09.118694
174	2026/173	148	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:24:55.69472
175	2026/174	149	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:35:22.880681
176	2026/175	150	3	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:38:03.031083
177	2026/176	150	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:48:26.084088
178	2026/177	151	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:49:35.212638
179	2026/178	152	4	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 10:54:09.661077
180	2026/179	153	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 11:02:43.948529
181	2026/180	154	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 11:09:53.577969
182	2026/181	155	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 11:17:16.853061
191	2026/182	160	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 13:05:15.167714
192	2026/183	165	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 13:10:04.585822
193	2026/184	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 13:10:18.81469
194	2026/185	121	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 13:11:48.840637
195	2026/186	166	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 13:25:40.174807
196	2026/187	167	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 13:44:21.650513
197	2026/188	168	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 14:57:44.038028
198	2026/189	169	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-16 16:02:37.642197
199	2026/190	136	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-17 08:15:18.841248
200	2026/191	170	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-17 08:15:53.947105
201	2026/192	171	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-17 11:43:59.417042
202	2026/193	172	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-17 15:18:48.588014
203	2026/194	173	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 08:46:55.043225
204	2026/195	174	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 09:36:30.049954
205	2026/196	175	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 09:46:23.734586
206	2026/197	176	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 09:51:26.774758
207	2026/198	177	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 10:04:09.861451
208	2026/199	178	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 10:16:17.747042
209	2026/200	179	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 10:28:52.850358
210	2026/201	180	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 10:40:07.869691
211	2026/202	181	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 10:45:47.790551
212	2026/203	182	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 11:12:44.34275
213	2026/204	183	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-18 11:22:54.801541
214	2026/205	184	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-19 10:07:25.523215
215	2026/206	185	4	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-19 10:10:35.442761
216	2026/207	176	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-19 11:50:03.943364
217	2026/208	186	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-19 11:55:07.778183
218	2026/209	187	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-20 08:31:21.041879
219	2026/210	120	1	\N	1	SINOV-1	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 10:15:19.221038
220	2026/211	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-21 15:20:54.944777
221	2026/212	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test sabab	2026-07-21 15:20:56.034834
222	2026/213	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Xato mashina tanlandi	2026-07-21 15:25:10.040933
223	2026/214	156	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:17:54.862336
226	2026/215	156	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:17:54.862336
227	2026/216	156	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:17:54.862336
228	2026/217	157	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:22:16.651739
229	2026/218	158	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:27:11.026938
230	2026/219	159	1	\N	1	1	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:31:06.242365
231	2026/220	160	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:35:49.860194
232	2026/221	131	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:52:39.474388
233	2026/222	161	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 11:55:43.269668
234	2026/223	164	2	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	tugallandi	\N	2026-07-16 12:02:44.038314
236	2026/224	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:14.971546
237	2026/225	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.045555
238	2026/226	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.061867
239	2026/227	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.094715
240	2026/228	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.115721
241	2026/229	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.118888
242	2026/230	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.12849
243	2026/231	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.181843
244	2026/232	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.216112
245	2026/233	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:15.231254
246	2026/234	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.214593
247	2026/235	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.231329
248	2026/236	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.248274
249	2026/237	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.262556
250	2026/238	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.275673
251	2026/239	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.308488
252	2026/240	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.323548
253	2026/241	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.32429
254	2026/242	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.339942
255	2026/243	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:38:28.354368
256	2026/244	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.43225
257	2026/245	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.443952
258	2026/246	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.461614
259	2026/247	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.471591
260	2026/248	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.484738
261	2026/249	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.499174
262	2026/250	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.51364
263	2026/251	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.529444
264	2026/252	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.544864
265	2026/253	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 15:39:00.545509
266	2026/254	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.855554
267	2026/255	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.873996
268	2026/256	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.883153
269	2026/257	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.898323
270	2026/258	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.911006
271	2026/259	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.926813
272	2026/260	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.927389
273	2026/261	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.941744
274	2026/262	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.957554
275	2026/263	120	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	bekor	Test - poyga holati sinovi uchun yaratilgan, haqiqiy emas	2026-07-21 15:39:22.973645
276	2026/264	151	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	jarayon	\N	2026-07-21 18:19:23.683609
\.


--
-- Data for Name: mahsulotlar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mahsulotlar (id, nom, konditsiya_bor, is_active) FROM stdin;
1	Chigit	t	t
2	Chiganoq	f	t
3	Chiganoq po'chog'i	f	t
4	Patoz	f	t
\.


--
-- Data for Name: mashinalar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mashinalar (id, davlat_raqami, turi, shofyor, firma, viloyat, telefon) FROM stdin;
1	95 Y 927 FA	Kamaz	Saburov Atamurod	Hazorasp Don Mahsulotlari	Xorazm	+998901234567
2	90 U 818 FA	Kamaz			Xorazm	\N
3	90 U 921 XA	Kamaz		AGRO	Xorazm	\N
4	90 U 88 FA	FAW	AZIZ AZIZOV	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
5	90 E 121 EW	FAW	AZIZ AHMEODV	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
6	90 R 787 FA	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
7	90 E 121 WW	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
8	90 R 819 DA	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
9	90 u717 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
10	90 w787ww	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
11	90 e 717 re	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
12	70 877 dda	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
13	90 e 878ea	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
14	90 e 787 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
15	90 f987 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
16	90 r 888 rrr	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
17	90 e 878 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
18	90 f 878 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
19	90 f 787 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
20	90 r 717 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
21	90 e 878 ea	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
22	90 r 787 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
23	70 d 818 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
24	90 r 787 qq	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
25	90 t 878 qa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
26	90 s 874 da	FAW	Ahmedov Ali	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
27	90 r 741 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
28	90 r 546 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
29	90 e 777da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
30	90 S 888 SS	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
31	90 Z 777 ZZ	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
32	90 A 111AA	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
33	90L777LL	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
34	90 w 777 ww	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
35	90 S 887 SS	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
36	90 o 001 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
37	90 t 781 da	Traktor	ahmedov I	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
38	90 D 001 OO	FAW	Ahemov Izzat	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
39	90  o 011 00	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
40	90 Q 001QQ	FAW	Azizov A	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
41	90 S 333 SS	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
42	90 S 555 SS	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
43	90 I 111 II	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
44	90 T 111 TT	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
45	90  Z 777 ZZ	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
46	90  O 001 OO	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
47	90 w 777 wq	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
48	90 i111ii	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
49	90 K 777 KK	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
50	90 B 888 BB	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
51	90 D 000 DD	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
52	90 i 111 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
53	90 d 001 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
54	90 J 777 JJ	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
55	90 E 777 EE	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
56	90 D 777DD	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
57	90 t 555 tt	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
58	90 741 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
59	90 D 777 DD	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
60	90 t 771 tt	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
61	90 s 555 sa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
62	90  e 777 ee	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
63	90  T 111 TT	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
64	90 q 000 qq	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
65	70 0 077 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
66	90 U 444 QQ	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
67	90 z 222 zz	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
68	90 s 222 zz	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
69	90 f 999 ff	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
70	90 e 888ee	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
71	90 e 555 e	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
72	01 011 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
73	70 d 777 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
74	90 d 888 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
75	90 w 222 ww	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
76	90 e 123 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
77	98 r 111aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
78	90 r 777 rr	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
79	90 e 213 ee	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
80	90 s 555ss	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
81	90 e 878 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
82	90 e 888 ee	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
83	90 d 111 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
84	90 e 159 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
85	80 g 555 gg	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
86	90 r 258 ee	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
87	01 o 001 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
88	80 f 888 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
89	90 z 838 zz	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
90	90 R 666 RR	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
91	90 D 080 DD	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
92	90 d 000 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
93	90 D 001 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
94	90 E 818 Wa	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
95	90	FAW	Ahmedov A	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
96	90 f 888 ff	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
97	90 u 838 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
100	90 t 741 tt	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
102	90 874 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
104	90 555 ooo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
98	90 f 551 ff	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
99	90 e 877 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
101	90 e 555 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
103	90 000 ooo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
105	90 d 7777dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
106	01 d 222ddd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
107	90  F 777 FF	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
108	90 s 888 ss	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
109	90 r 777 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
110	90 o 000 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
111	90 855	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
112	90 d 123 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
113	90 d 990 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
114	77777	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
115	1111	FAW	A Ahmedov	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
116	90 9000	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
117	90 o 009 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
118	90 0 999 00	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
119	90 001 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
120	8888	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
121	777	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
122	222	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
123	333	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
124	555	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
125	111	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
126	111222	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
127	1	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
128	90 e 111 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
129	90 8178	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
130	90 t 1	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
131	2	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
132	1994	FAW	ali	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
133	1996	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
134	1969	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
135	1972	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
136	123	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
137	77	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
138	951	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
139	3	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
140	55555	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
141	654	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
142	4	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
143	5	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
144	9	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
145	99	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
146	55	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
147	13	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
148	44	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
149	41	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
150	24	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
151	7777	FAW	li	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
152	48	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
153	67	FAW	Ali	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
154	87	FAW	A Ali	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
155	43	FAW	ali	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
156	63	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
157	22	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
158	513	FAW	ad	SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
159	9741	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
160	9874	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
161	64	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
162	61	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
163	3214	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
164	987	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
165	987453	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
166	987654	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
167	8714	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
168	90                          ddd	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
169	98754	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
170	124	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
171	90 888888	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
172	888222	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
173	0022	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
174	1254	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
175	112233	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
176	90 878	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
177	880088	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
178	808080	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
179	445566	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
180	818	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
181	123456789	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
182	838	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
183	884466	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
184	90 818 fs	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
185	90 777 da	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
186	90 88888	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
187	90 818 FA	FAW		SABZAVOTNAVURUG'LARI MChJ	Xorazm	\N
\.


--
-- Data for Name: navbat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.navbat (id, hujjat_id, mashina_id, raqam, turi, shofyor, firma, mahsulot_id, mahsulot_nomi, vaqt, kelgan_vaqt, tuda_raqam, tiket_raqam, seleksiya_navi, klass, sinf, terim_turi, namlik, ifloslik, tugallandi, tugallangan_vaqt, aravalar_json, created_at) FROM stdin;
10	71	62	90  e 777 ee	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	12:33	2026-07-12 12:33:50.770334		4162015	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-12 12:33:56.84338	{}	2026-07-12 12:33:50.770334
24	85	74	90 d 888 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:18	2026-07-13 10:18:21.215406		1989181	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 10:18:25.953055	{}	2026-07-13 10:18:21.215406
4	66	57	90 t 555 tt	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:05	2026-07-11 11:05:05.878966		4940848	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-11 11:05:47.344223	{}	2026-07-11 11:05:05.878966
3	65	56	90 D 777DD	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:56	2026-07-11 10:56:48.48969		4938627	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-12 12:38:19.394312	{"1": {"tara": 18462, "brutto": 18434, "netto": -28, "konditsion": -31.28491620111732}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-11 10:56:48.48969
5	67	58	90 741 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	3	Chiganoq po'chog'i	11:12	2026-07-11 11:12:42.798599		5035315	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-11 11:13:19.478089	{}	2026-07-11 11:12:42.798599
6	68	59	90 D 777 DD	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	12:00	2026-07-12 12:00:57.605933		3964685	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-12 12:01:11.265524	{"1": {"tara": 18430, "brutto": 18446, "netto": 16, "konditsion": 17.877094972067038}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-12 12:00:57.605933
15	76	65	70 0 077 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:03	2026-07-13 09:03:09.0698		1537182	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:03:14.793125	{}	2026-07-13 09:03:09.0698
7	69	60	90 t 771 tt	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	12:19	2026-07-12 12:19:56.453154		4078400	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-12 12:20:02.908863	{}	2026-07-12 12:19:56.453154
131	154	135	1972	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:34	2026-07-15 14:34:45.188236	1	0806324	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-15 14:34:49.786409	{"1": {"tara": 18444, "brutto": 18437, "netto": -7, "konditsion": -7.203351955307262}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 14:34:45.188236
11	72	42	90 S 555 SS	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:19	2026-07-13 08:19:27.556154		1275313	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 08:19:36.061499	{"1": {"tara": 18443, "brutto": 18411, "netto": -32, "konditsion": -35.754189944134076}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-13 08:19:27.556154
12	73	54	90 J 777 JJ	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:20	2026-07-13 08:20:46.82441		1283716	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 08:20:52.309266	{}	2026-07-13 08:20:46.82441
19	80	69	90 f 999 ff	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:35	2026-07-13 09:35:03.414422		1729128	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:35:08.358196	{}	2026-07-13 09:35:03.414422
13	74	63	90  T 111 TT	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:30	2026-07-13 08:30:56.200469		1344000	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 08:31:00.717231	{}	2026-07-13 08:30:56.200469
16	77	66	90 U 444 QQ	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:09	2026-07-13 09:09:30.348279		1575630	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:09:35.542441	{}	2026-07-13 09:09:30.348279
14	75	64	90 q 000 qq	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:53	2026-07-13 08:53:02.979437		1476716	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 08:53:08.019696	{}	2026-07-13 08:53:02.979437
17	78	67	90 z 222 zz	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:17	2026-07-13 09:17:46.468597		1625595	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:17:51.943909	{}	2026-07-13 09:17:46.468597
22	83	72	01 011 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:02	2026-07-13 10:02:02.802902		1890930	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 10:02:07.798977	{}	2026-07-13 10:02:02.802902
18	79	68	90 s 222 zz	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:26	2026-07-13 09:26:47.688025		1679717	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:26:53.680377	{"1": {"tara": 18447, "brutto": 18428, "netto": -19, "konditsion": -21.22905027932961}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-13 09:26:47.688025
20	81	70	90 e 888ee	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:40	2026-07-13 09:40:54.880348		1764486	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:41:01.944109	{}	2026-07-13 09:40:54.880348
21	82	71	90 e 555 e	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:51	2026-07-13 09:51:30.017092		1828125	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 09:51:35.014493	{}	2026-07-13 09:51:30.017092
23	84	73	70 d 777 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:11	2026-07-13 10:11:31.650677		1948450	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 10:11:36.752424	{}	2026-07-13 10:11:31.650677
28	88	77	98 r 111aa	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:22	2026-07-13 14:22:52.381717		3456112	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 14:22:59.76643	{}	2026-07-13 14:22:52.381717
27	87	76	90 e 123 da	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:10	2026-07-13 14:10:57.790356	1	3383017	Xorazm-150	1	1	Kul terim	7.8	1	t	2026-07-13 14:11:04.115117	{}	2026-07-13 14:10:57.790356
136	158	127	1	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:20	2026-07-15 15:20:14.291846		1079766	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-15 15:20:19.217833	{"1": {"tara": 18455, "brutto": 18457, "netto": 2, "konditsion": 2.0581005586592176}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 15:20:14.291846
29	89	78	90 r 777 rr	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:31	2026-07-13 14:31:09.562061		3506034	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 14:31:15.125341	{}	2026-07-13 14:31:09.562061
145	165	139	3	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	09:26	2026-07-16 09:26:42.447807		7599296	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 09:26:49.016374	{"1": {"tara": 18449, "brutto": 18441, "netto": -8, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 09:26:42.447807
34	92	80	90 s 555ss	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:57	2026-07-13 14:57:21.155753		3662095	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 14:57:26.721271	{}	2026-07-13 14:57:21.155753
35	93	81	90 e 878 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:07	2026-07-13 15:07:33.20897		3724514	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 15:07:37.993305	{}	2026-07-13 15:07:33.20897
201	204	174	1254	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:36	2026-07-18 09:36:32.033037	1	4936963	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-18 09:36:38.632402	{"1": {"tara": 18450, "brutto": 18459, "netto": 9, "konditsion": 9.26145251396648}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-18 09:36:32.033037
38	95	83	90 d 111 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:27	2026-07-13 15:27:50.89835		3846329	Xorazm-150	1	1	Kul terim	\N	\N	t	2026-07-13 15:27:55.106426	{}	2026-07-13 15:27:50.89835
216	214	184	90 818 fs	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:07	2026-07-19 10:07:26.906949	1	3762313	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-19 10:07:32.693472	{"1": {"tara": 18426, "brutto": 18418, "netto": -8, "konditsion": -8.23240223463687}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-19 10:07:26.906949
45	101	2	90 U 818 FA	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	16:32	2026-07-13 16:32:09.850197	1	4230305	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-13 16:32:15.348688	{"1": {"tara": 18402, "brutto": 18386, "netto": -16, "konditsion": -16.46480446927374}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-13 16:32:09.850197
132	155	95	90	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:39	2026-07-15 14:39:36.193737		0836037	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-15 14:39:42.656994	{"1": {"tara": 18462, "brutto": 18475, "netto": 13, "konditsion": 13.377653631284916}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 14:39:36.193737
41	97	85	80 g 555 gg	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:43	2026-07-13 15:43:21.38856		3939019	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 15:43:27.169501	{}	2026-07-13 15:43:21.38856
217	215	185	90 777 da	FAW		SABZAVOTNAVURUG'LARI MChJ	4	Patoz	10:10	2026-07-19 10:10:36.954942		3782769	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-19 10:10:41.746953	{"1": {"tara": 18449, "brutto": 18424, "netto": -25, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-19 10:10:36.954942
42	98	86	90 r 258 ee	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:52	2026-07-13 15:52:35.684276		3989740	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 15:52:42.352488	{}	2026-07-13 15:52:35.684276
43	99	87	01 o 001 oo	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	16:10	2026-07-13 16:10:24.673997		4101455	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 16:10:28.743805	{}	2026-07-13 16:10:24.673997
44	100	88	80 f 888 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	16:16	2026-07-13 16:16:28.859586		4137879	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-13 16:16:33.756533	{"1": {"tara": 18443, "brutto": 18446, "netto": 3, "konditsion": 3.35195530726257}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-13 16:16:28.859586
56	107	93	90 D 001 dd	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:43	2026-07-14 08:43:19.961192	1	0056660	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-14 08:43:25.16593	{"1": {"tara": 18425, "brutto": 18409, "netto": -16, "konditsion": -16.46480446927374}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 08:43:19.961192
57	108	94	90 E 818 Wa	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:35	2026-07-14 10:35:00.249843			Xorazm-150	1		Kul terim	\N	\N	t	2026-07-14 10:35:05.507531	{"1": {"tara": 18461, "brutto": 18469, "netto": 8, "konditsion": 8.938547486033519}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 10:35:00.249843
55	106	76	90 e 123 da	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:34	2026-07-14 08:34:30.961038		0006078	Xorazm-150	1	1	Kul terim	\N	\N	t	2026-07-14 08:34:37.882865	{"1": {"tara": 18394, "brutto": 18398, "netto": 4, "konditsion": 4.4692737430167595}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 08:34:30.961038
60	111	96	90 f 888 ff	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:05	2026-07-14 11:05:04.406891		0909632	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-14 11:05:17.915058	{"1": {"tara": 18437, "brutto": 18436, "netto": -1, "konditsion": -1.1173184357541899}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 11:05:04.406891
58	109	53		FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:45	2026-07-14 10:45:19.690689			Xorazm-150	1		Kul terim	\N	\N	t	2026-07-14 10:45:35.472633	{"1": {"tara": 18455, "brutto": 18453, "netto": -2, "konditsion": -2.2346368715083798}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 10:45:19.690689
61	112	97		FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:12	2026-07-14 11:12:06.073642		0951693	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-14 11:12:34.474874	{"1": {"tara": 18442, "brutto": 18403, "netto": -39, "konditsion": -43.57541899441341}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 11:12:06.073642
64	114	99	90 e 877 da	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:18	2026-07-14 11:18:35.255949		0976378	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-14 11:18:42.5284	{"1": {"tara": 18315, "brutto": 18301, "netto": -14, "konditsion": -15.64245810055866}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 11:18:35.255949
156	172	146	55	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	10:23	2026-07-16 10:23:03.774827		7922037	Xorazm-150	1		Kul terim	\N	\N	f	\N	{"1": {"tara": 18440, "brutto": 18427, "netto": -13, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:23:03.774827
202	205	175	112233	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:46	2026-07-18 09:46:26.65975		4997141	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-18 09:46:32.105499	{"1": {"tara": 18440, "brutto": 18452, "netto": 12, "konditsion": 12.348603351955305}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-18 09:46:26.65975
133	156	136	123	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:53	2026-07-15 14:53:56.720964		0922055	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-15 14:54:04.111151	{"1": {"tara": 18431, "brutto": 18423, "netto": -8, "konditsion": -8.23240223463687}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 14:53:56.720964
172	227	156	63	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	11:17	2026-07-16 11:17:54.862336		8266666	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 11:17:59.023872	{"1": {"tara": 18446, "brutto": 18441, "netto": -5, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:17:54.862336
174	229	158	513	FAW	ad	SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:27	2026-07-16 11:27:11.026938		8321205	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 11:27:16.202602	{"1": {"tara": 18455, "brutto": 18458, "netto": 3, "konditsion": 3.087150837988826}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:27:11.026938
176	231	160	9874	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:35	2026-07-16 11:35:49.860194		8373897	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 11:35:54.3371	{"1": {"tara": 18448, "brutto": 18446, "netto": -2, "konditsion": -2.0581005586592176}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:35:49.860194
79	123	108	90 s 888 ss	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	13:13	2026-07-14 13:13:06.365741	1	1676345	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-14 13:13:15.968564	{"1": {"tara": 17469, "brutto": 17470, "netto": 1, "konditsion": 1.0290502793296088}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 13:13:06.365741
142	162	140	55555	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	15:44	2026-07-15 15:44:18.291473		1224019	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-15 15:44:23.628008	{"1": {"tara": 18458, "brutto": 18458, "netto": 0, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 15:44:18.291473
92	131	116	90 9000	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:07	2026-07-14 14:07:30.885916		2002988	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-14 14:07:38.777205	{"1": {"tara": 18402, "brutto": 18370, "netto": -32, "konditsion": -31.003671784582846}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 14:07:30.885916
90	129	114	77777	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	13:40	2026-07-14 13:40:09.715769	1	1838783	Xorazm-150	11	1	Kul terim	7.8	0.1	t	2026-07-14 13:40:16.104303	{"1": {"tara": 17678, "brutto": 17664, "netto": -14, "konditsion": -14.406703910614524}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 13:40:09.715769
91	130	115	1111	FAW	A Ahmedov	SABZAVOTNAVURUG'LARI MChJ	1	Chigit	13:49	2026-07-14 13:49:49.59862		1895705	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-14 13:49:56.044581	{"1": {"tara": 18398, "brutto": 18369, "netto": -29, "konditsion": -28.097077554778203}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 13:49:49.59862
150	168	142	4	FAW		SABZAVOTNAVURUG'LARI MChJ	3	Chiganoq po'chog'i	09:40	2026-07-16 09:40:13.575632		7680828	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 09:40:19.1644	{"1": {"tara": 18435, "brutto": 18421, "netto": -14, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 09:40:13.575632
95	133	118	90 0 999 00	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:22	2026-07-14 14:22:53.384041		2095937	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-14 14:23:01.393064	{"1": {"tara": 18472, "brutto": 18462, "netto": -10, "konditsion": -9.688647432682139}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 14:22:53.384041
141	161	139	3	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	15:35	2026-07-15 15:35:30.1731		1172475	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-15 15:35:34.626738	{"1": {"tara": 18043, "brutto": 18054, "netto": 11, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 15:35:30.1731
151	169	143	5	FAW		SABZAVOTNAVURUG'LARI MChJ	4	Patoz	09:49	2026-07-16 09:49:04.315669		7733668	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 09:49:09.819766	{"1": {"tara": 18455, "brutto": 18444, "netto": -11, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 09:49:04.315669
154	171	145	99	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	10:14	2026-07-16 10:14:32.994561		7886467	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 10:14:40.766985	{"1": {"tara": 18466, "brutto": 18468, "netto": 2, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:14:32.994561
157	173	147	13	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	10:23	2026-07-16 10:23:10.082743		7938376	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 10:23:14.271903	{"1": {"tara": 18253, "brutto": 18232, "netto": -21, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:23:10.082743
162	176	150	24	FAW		SABZAVOTNAVURUG'LARI MChJ	3	Chiganoq po'chog'i	10:38	2026-07-16 10:38:03.784296		8027880	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 10:38:08.634337	{"1": {"tara": 18448, "brutto": 18431, "netto": -17, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:38:03.784296
130	153	134	1969	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	14:26	2026-07-15 14:26:44.005523		0758687	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-15 14:26:49.786955	{"1": {"tara": 18429, "brutto": 18417, "netto": -12, "konditsion": -12.348603351955305}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 14:26:44.005523
203	206	176	90 878	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	09:51	2026-07-18 09:51:28.291452		5026042	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-18 09:51:33.283399	{"1": {"tara": 18394, "brutto": 18376, "netto": -18, "konditsion": -18.52290502793296}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-18 09:51:28.291452
143	163	141	654	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	15:49	2026-07-15 15:49:33.830198		1256814	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-15 15:49:41.103194	{"1": {"tara": 18462, "brutto": 18466, "netto": 4, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 15:49:33.830198
114	144	127	1	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:33	2026-07-14 15:33:39.984936	1	2512621	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-14 15:33:47.473179	{"1": {"tara": 18328, "brutto": 18331, "netto": 3, "konditsion": 2.9065942298046417}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 15:33:39.984936
144	164	142	4	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	15:59	2026-07-15 15:59:45.944912		1317922	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-15 15:59:50.535609	{"1": {"tara": 18436, "brutto": 18434, "netto": -2, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-15 15:59:45.944912
109	141	122	222	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:07	2026-07-14 15:07:51.049195		2365763	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-14 15:07:59.255858	{"1": {"tara": 18416, "brutto": 18417, "netto": 1, "konditsion": 0.9688647432682139}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 15:07:51.049195
204	207	177	880088	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:04	2026-07-18 10:04:12.213587		5103738	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-18 10:04:16.981383	{"1": {"tara": 18475, "brutto": 18474, "netto": -1, "konditsion": -1.0290502793296088}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-18 10:04:12.213587
166	179	152	48	FAW		SABZAVOTNAVURUG'LARI MChJ	4	Patoz	10:54	2026-07-16 10:54:10.367475		8124440	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 10:54:14.891604	{"1": {"tara": 18458, "brutto": 18453, "netto": -5, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:54:10.367475
159	174	148	44	FAW		SABZAVOTNAVURUG'LARI MChJ	3	Chiganoq po'chog'i	10:25	2026-07-16 10:25:18.030894		7949077	Xorazm-150	1		Kul terim	\N	\N	f	\N	{"1": {"tara": 18443, "brutto": 18443, "netto": 0, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:25:18.030894
205	208	178	808080	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:16	2026-07-18 10:16:18.927937	1	5176245	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-18 10:16:23.913626	{"1": {"tara": 18432, "brutto": 18429, "netto": -3, "konditsion": -3.087150837988826}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-18 10:16:18.927937
173	228	157	22	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	11:22	2026-07-16 11:22:16.651739		8292748	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 11:22:20.898553	{"1": {"tara": 18446, "brutto": 18438, "netto": -8, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:22:16.651739
121	148	130	90 t 1	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	15:49	2026-07-14 15:49:02.598185		2613457	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-14 15:49:07.814685	{"1": {"tara": 18175, "brutto": 18178, "netto": 3, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 15:49:02.598185
175	230	159	9741	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:31	2026-07-16 11:31:06.242365	1	8344647	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-16 11:31:13.952588	{"1": {"tara": 18458, "brutto": 18473, "netto": 15, "konditsion": 15.435754189944134}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:31:06.242365
179	232	131	2	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:52	2026-07-16 11:52:39.474388		8474736	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 11:52:44.888992	{"1": {"tara": 18452, "brutto": 18447, "netto": -5, "konditsion": -5.145251396648045}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:52:39.474388
163	177	150	24	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	10:48	2026-07-16 10:48:27.032243		8089892	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 10:48:32.963898	{"1": {"tara": 18442, "brutto": 18426, "netto": -16, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 10:48:27.032243
180	233	161	64	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	11:55	2026-07-16 11:55:43.269668		8493646	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 11:55:47.551473	{"1": {"tara": 18435, "brutto": 18425, "netto": -10, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:55:43.269668
171	182	155	43	FAW	ali	SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:17	2026-07-16 11:17:18.561986		8261163	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-16 11:17:24.094275	{"1": {"tara": 17988, "brutto": 17991, "netto": 3, "konditsion": 3.087150837988826}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 11:17:18.561986
182	138	163	3214	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	12:02	2026-07-16 12:02:10.691216		8531982	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 12:02:14.756987	{"1": {"tara": 18438, "brutto": 18425, "netto": -13, "konditsion": -13.377653631284916}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 12:02:10.691216
223	219	120	8888	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:15	2026-07-21 10:15:20.41294		1087888	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-21 10:15:27.463562	{"1": {"tara": 18384, "brutto": 18388, "netto": 4, "konditsion": 4.116201117318435}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-21 10:15:20.41294
66	116	101		FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:41	2026-07-14 11:41:02.752985		1081480	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 14:15:37.57514	{"1": {"tara": 18258, "brutto": 18485, "netto": 227, "konditsion": 253.6312849162011}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-14 11:41:02.752985
220	217	186	90 88888	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:55	2026-07-19 11:55:09.040821	1	4409927	Xorazm-150	1	1	Kul terim	7.8	0.1	t	2026-07-19 11:55:21.448026	{"1": {"tara": 18462, "brutto": 18468, "netto": 6, "konditsion": 6.174301675977652}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-19 11:55:09.040821
184	234	164	987	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	12:02	2026-07-16 12:02:44.038314		8535977	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 12:02:48.008105	{"1": {"tara": 18305, "brutto": 18301, "netto": -4, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 12:02:44.038314
198	201	171	90 888888	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:44	2026-07-17 11:44:00.582411		7062576	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-17 11:44:05.915085	{"1": {"tara": 18177, "brutto": 18187, "netto": 10, "konditsion": 10.29050279329609}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-17 11:44:00.582411
194	198	169	98754	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	16:02	2026-07-16 16:02:38.691434		9972172	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 16:03:08.913149	{"1": {"tara": 18392, "brutto": 18322, "netto": -70, "konditsion": -72.03351955307262}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 16:02:38.691434
190	194	121	777	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	13:11	2026-07-16 13:11:50.322647		8949820	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 13:11:54.630875	{"1": {"tara": 18178, "brutto": 18178, "netto": 0, "konditsion": 0}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 13:11:50.322647
191	195	166	987654	FAW		SABZAVOTNAVURUG'LARI MChJ	2	Chiganoq	13:25	2026-07-16 13:25:48.384033		9033256	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-16 13:25:53.991182	{"1": {"tara": 18433, "brutto": 18429, "netto": -4, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 13:25:48.384033
192	196	167	8714	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	13:44	2026-07-16 13:44:22.328125		9144618	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-16 13:44:29.279741	{"1": {"tara": 18457, "brutto": 18468, "netto": 11, "konditsion": 11.319553072625697}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-16 13:44:22.328125
224	276	151	7777	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	18:19	2026-07-21 18:19:24.885676		3973516	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-21 18:19:32.531601	{"1": {"tara": 18351, "brutto": 18344, "netto": -7, "konditsion": -7.203351955307262}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-21 18:19:24.885676
199	202	172	888222	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	15:18	2026-07-17 15:18:50.094466		8351304	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-17 15:18:55.258323	{"1": {"tara": 18430, "brutto": 18408, "netto": -22, "konditsion": -22.639106145251393}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-17 15:18:50.094466
200	203	173	0022	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	08:46	2026-07-18 08:46:56.19362		4640345	Xorazm-150	1		Kul terim	7.8	0.1	t	2026-07-18 08:47:00.710234	{"1": {"tara": 18441, "brutto": 18433, "netto": -8, "konditsion": -8.23240223463687}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-18 08:46:56.19362
\.


--
-- Data for Name: olchovlar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.olchovlar (id, hujjat_id, arava_raqam, tara, brutto, netto, namlik, ifloslik, konditsion, tara_rasm, brutto_rasm, qolda_kiritildi, created_at) FROM stdin;
5	2	2	18419	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 14:34:16.31296
6	2	1	18423	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 14:34:27.607103
7	2	2	18419	18403	-16	\N	\N	\N	\N	\N	f	2026-07-01 14:34:44.674185
8	2	1	18423	18384	-39	\N	\N	\N	\N	\N	f	2026-07-01 14:34:57.658863
9	3	1	18485	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 15:46:31.824113
10	3	2	18470	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 15:46:43.354856
11	3	1	18485	18452	-33	\N	\N	\N	\N	\N	f	2026-07-01 15:47:00.436999
12	3	2	18470	18437	-33	\N	\N	\N	\N	\N	f	2026-07-01 15:47:11.524616
13	4	1	18306	\N	\N	8	0.1	\N	\N	\N	f	2026-07-01 15:58:33.257193
14	4	2	18283	\N	\N	8	0.1	\N	\N	\N	f	2026-07-01 15:58:45.537958
15	4	2	18283	18256	-27	8	0.1	-24.813000000000002	\N	\N	f	2026-07-01 15:58:56.711837
16	4	1	18306	18218	-88	8	0.1	-80.872	\N	\N	f	2026-07-01 15:59:10.372501
17	5	2	18463	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 16:46:46.856508
18	5	1	18452	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 16:47:10.702164
19	5	1	18452	18465	13	\N	\N	\N	\N	\N	f	2026-07-01 16:47:26.55965
20	5	2	18463	18472	9	\N	\N	\N	\N	\N	f	2026-07-01 16:47:38.655996
21	6	1	18444	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 17:15:46.688585
22	6	2	18451	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 17:15:59.392511
23	6	1	18444	18424	-20	\N	\N	\N	\N	\N	f	2026-07-01 17:16:12.507508
24	6	2	18451	18387	-64	\N	\N	\N	\N	\N	f	2026-07-01 17:16:38.716413
25	7	1	18378	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 17:32:50.520252
26	7	2	18377	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 17:33:06.241455
27	7	1	18378	18366	-12	\N	\N	\N	\N	\N	f	2026-07-01 17:33:29.185546
28	7	2	18377	18368	-9	\N	\N	\N	\N	\N	f	2026-07-01 17:33:47.908063
29	8	1	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 10:23:19.408274
30	8	2	18428	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 10:23:39.202003
31	8	1	18431	18422	-9	\N	\N	\N	\N	\N	f	2026-07-02 10:23:46.850904
32	8	2	18428	18420	-8	\N	\N	\N	\N	\N	f	2026-07-02 10:24:00.062545
33	9	1	18423	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 10:49:11.895052
34	9	2	18391	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 10:49:42.308661
35	9	1	18423	18332	-91	\N	\N	\N	\N	\N	f	2026-07-02 10:50:19.798648
36	9	2	18391	18339	-52	\N	\N	\N	\N	\N	f	2026-07-02 10:50:34.782557
37	10	1	18445	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 11:07:55.511635
38	10	2	18423	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 11:08:10.887812
39	10	1	18445	18422	-23	\N	\N	\N	\N	\N	f	2026-07-02 11:08:27.580723
40	10	2	18423	18415	-8	\N	\N	\N	\N	\N	f	2026-07-02 11:08:40.687703
41	11	1	18459	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 11:20:38.013654
42	11	2	18470	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 11:20:55.609917
43	11	1	18459	18464	5	\N	\N	\N	\N	\N	f	2026-07-02 11:21:21.492787
44	11	2	18470	18455	-15	\N	\N	\N	\N	\N	f	2026-07-02 11:21:34.404293
45	12	1	18381	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 11:42:27.750568
46	12	2	18359	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 11:42:38.667936
47	12	1	18381	18339	-42	\N	\N	\N	\N	\N	f	2026-07-02 11:42:47.087364
48	12	2	18359	18310	-49	\N	\N	\N	\N	\N	f	2026-07-02 11:43:01.502706
49	13	1	18453	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 14:30:40.817516
50	13	2	18451	\N	\N	\N	\N	\N	\N	\N	f	2026-07-02 14:30:51.792145
51	13	1	18453	18476	23	\N	\N	\N	\N	\N	f	2026-07-02 14:31:20.784056
52	13	2	18451	18458	7	\N	\N	\N	\N	\N	f	2026-07-02 14:31:33.387256
53	14	1	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:00:45.609446
54	14	2	18420	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:00:56.651352
55	14	1	18431	18333	-98	9	1	-88.2	\N	\N	f	2026-07-03 09:01:48.489122
56	14	2	18420	18328	-92	9	1	-82.8	\N	\N	f	2026-07-03 09:02:01.240486
57	15	1	18444	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:19:01.288819
58	15	2	18432	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:19:17.356916
59	15	1	18444	18439	-5	\N	\N	\N	\N	\N	f	2026-07-03 09:19:42.40668
60	15	2	18432	18447	15	\N	\N	\N	\N	\N	f	2026-07-03 09:19:54.554083
61	16	1	18429	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:42:25.815625
62	16	2	18433	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:42:39.551521
63	16	1	18429	18440	11	\N	\N	\N	\N	\N	f	2026-07-03 09:43:03.800365
64	16	2	18433	18440	7	\N	\N	\N	\N	\N	f	2026-07-03 09:43:47.291868
65	17	1	18453	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:52:03.189018
66	17	2	18455	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 09:52:14.146068
67	17	1	18453	18409	-44	\N	\N	\N	\N	\N	f	2026-07-03 09:53:07.084159
68	17	2	18455	18422	-33	\N	\N	\N	\N	\N	f	2026-07-03 09:53:19.914612
69	18	1	18444	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 10:06:53.310512
70	18	2	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 10:07:04.978521
71	18	1	18444	18380	-64	\N	\N	\N	\N	\N	f	2026-07-03 10:07:30.564113
72	18	2	18431	18338	-93	\N	\N	\N	\N	\N	f	2026-07-03 10:07:46.128825
73	19	1	18412	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:06:01.944992
74	19	2	18412	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:06:13.367296
75	19	1	\N	18425	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:06:40.440798
76	19	2	18427	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:06:51.722186
77	19	1	\N	18475	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:07:38.936201
78	19	2	18454	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:10:55.544907
79	20	1	18432	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:23:32.207844
80	20	2	18391	\N	\N	\N	\N	\N	\N	\N	f	2026-07-03 14:23:45.472426
81	20	1	18432	18401	-31	\N	\N	\N	\N	\N	f	2026-07-03 14:24:04.348672
82	20	2	18391	18380	-11	\N	\N	\N	\N	\N	f	2026-07-03 14:24:17.452073
83	21	1	18426	\N	\N	\N	\N	\N	\N	\N	f	2026-07-04 08:59:54.157597
84	21	2	18408	\N	\N	\N	\N	\N	\N	\N	f	2026-07-04 09:00:05.33985
85	21	1	18426	18373	-53	\N	\N	\N	\N	\N	f	2026-07-04 09:00:26.883503
86	21	2	18408	18362	-46	\N	\N	\N	\N	\N	f	2026-07-04 09:00:45.48812
87	22	1	16819	\N	\N	\N	\N	\N	\N	\N	f	2026-07-04 09:42:03.890859
88	22	2	16802	\N	\N	\N	\N	\N	\N	\N	f	2026-07-04 09:42:15.296199
89	23	1	18460	\N	\N	\N	\N	\N	\N	\N	f	2026-07-05 11:15:19.710396
90	23	1	18460	18465	5	\N	\N	\N	\N	\N	f	2026-07-05 11:15:37.53832
91	24	1	18458	\N	\N	\N	\N	\N	\N	\N	f	2026-07-05 11:17:23.134916
92	24	2	18468	\N	\N	\N	\N	\N	\N	\N	f	2026-07-05 11:17:34.31879
93	25	1	18387	\N	\N	9	1	\N	\N	\N	f	2026-07-05 11:33:04.799812
94	25	2	18402	\N	\N	9	1	\N	\N	\N	f	2026-07-05 11:33:15.966098
95	24	1	18458	18463	5	\N	\N	\N	\N	\N	f	2026-07-05 11:55:36.457638
96	26	1	18411	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 09:26:04.481014
97	26	1	18411	18364	-47	\N	\N	\N	\N	\N	f	2026-07-06 09:26:26.254129
98	27	1	16275	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 10:01:12.054441
99	28	1	18462	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 10:52:46.818729
100	28	2	18445	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 10:52:57.765358
101	27	1	16275	18447	2172	\N	\N	\N	\N	\N	f	2026-07-06 10:53:12.065628
102	27	2	18468	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 10:53:23.488772
103	28	2	18445	18461	16	\N	\N	\N	\N	\N	f	2026-07-06 10:54:00.932089
104	29	1	18432	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 10:54:50.723478
105	29	2	18446	\N	\N	\N	\N	\N	\N	\N	f	2026-07-06 10:55:01.792795
106	29	1	18432	18448	16	\N	\N	\N	\N	\N	f	2026-07-06 10:55:20.137752
107	29	2	18446	18443	-3	\N	\N	\N	\N	\N	f	2026-07-06 10:55:32.904771
108	30	1	18433	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 08:57:46.460725
109	30	2	18418	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 08:57:57.42507
110	31	2	18418	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 09:09:41.37597
111	31	1	18407	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 09:09:53.655843
112	31	1	18407	18411	4	\N	\N	\N	\N	\N	f	2026-07-07 09:10:14.298549
113	31	2	18418	18426	8	\N	\N	\N	\N	\N	f	2026-07-07 09:10:27.142629
114	32	1	18435	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 12:20:01.298087
115	32	2	18427	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 12:20:12.930786
116	33	1	18419	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 13:08:40.835684
117	33	2	18377	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 13:09:07.697115
118	32	1	18435	18361	-74	\N	\N	\N	\N	\N	f	2026-07-07 13:09:17.542328
119	32	2	18427	18350	-77	\N	\N	\N	\N	\N	f	2026-07-07 13:09:30.147261
120	34	1	18384	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 14:56:39.229615
121	34	2	18362	\N	\N	\N	\N	\N	\N	\N	f	2026-07-07 14:56:57.733417
122	35	1	18452	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 09:22:34.294459
123	35	2	18437	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 09:22:47.477479
124	35	1	18452	18352	-100	\N	\N	\N	\N	\N	f	2026-07-08 09:25:32.978522
125	35	2	18437	18331	-106	\N	\N	\N	\N	\N	f	2026-07-08 09:25:46.111498
126	36	1	18470	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 09:31:06.253722
127	36	2	18486	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 09:31:18.037368
128	36	1	18470	18477	7	\N	\N	\N	\N	\N	f	2026-07-08 09:31:35.456101
129	36	2	18486	18469	-17	\N	\N	\N	\N	\N	f	2026-07-08 09:31:49.421875
130	37	1	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 15:03:21.623644
131	38	1	18429	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 15:14:02.735481
132	38	2	18423	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 15:14:13.42728
133	38	1	18429	18428	-1	\N	\N	\N	\N	\N	f	2026-07-08 15:14:24.396128
134	38	2	18423	18443	20	\N	\N	\N	\N	\N	f	2026-07-08 15:14:37.104828
135	39	1	18384	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:34:29.530141
136	39	2	18371	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:34:42.667335
137	37	1	18431	18356	-75	7.8	0.1	-72.66485574511604	\N	\N	f	2026-07-08 15:34:59.705316
138	37	2	18321	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:35:12.066033
139	40	1	18194	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:36:15.572433
140	40	2	18176	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:36:26.776738
141	40	1	18194	18132	-62	7.8	0.1	-60.069614082629265	\N	\N	f	2026-07-08 15:37:04.107443
142	40	2	18176	18094	-82	7.8	0.1	-79.44690894799353	\N	\N	f	2026-07-08 15:37:16.815167
143	41	1	18415	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 15:38:18.11356
144	41	2	18405	\N	\N	\N	\N	\N	\N	\N	f	2026-07-08 15:38:28.869774
145	42	1	18252	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:39:46.241767
146	42	2	18251	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-08 15:39:57.025627
147	42	1	18252	18100	-152	7.8	0.1	-147.2674409767685	\N	\N	f	2026-07-08 15:41:37.192252
148	42	2	18251	18086	-165	7.8	0.1	-159.8626826392553	\N	\N	f	2026-07-08 15:41:49.663266
149	43	1	18429	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 13:55:31.573462
150	43	2	18387	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 13:55:44.695271
151	43	1	18429	18329	-100	\N	\N	\N	\N	\N	f	2026-07-09 13:56:11.739505
152	43	2	18387	18310	-77	\N	\N	\N	\N	\N	f	2026-07-09 13:56:24.506744
153	44	1	18184	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 13:59:43.115843
154	44	2	18167	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 13:59:53.815133
155	45	1	18066	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:02:42.464772
156	45	2	18055	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:02:54.385547
157	45	1	18066	18041	-25	7.8	0.1	-24.221618581705346	\N	\N	f	2026-07-09 14:03:07.226738
158	45	2	18055	18025	-30	7.8	0.1	-29.065942298046416	\N	\N	f	2026-07-09 14:03:20.025224
159	46	1	18420	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:15:15.08738
160	46	2	18424	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:15:28.868553
161	46	1	18420	18420	0	7.8	0.1	0	\N	\N	f	2026-07-09 14:15:50.53244
162	46	2	18424	18405	-19	7.8	0.1	-18.408430122096064	\N	\N	f	2026-07-09 14:16:04.125557
163	47	1	18565	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:59:02.620593
164	47	2	18579	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:59:13.639518
165	48	1	18582	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 14:59:55.900801
166	48	2	18595	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-09 15:00:07.892036
167	48	1	18582	18592	10	7.8	0.1	9.688647432682139	\N	\N	f	2026-07-09 15:00:18.603477
168	48	2	18595	18588	-7	7.8	0.1	-6.782053202877497	\N	\N	f	2026-07-09 15:00:32.236918
169	49	1	18430	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 15:26:26.159464
170	49	2	18415	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 15:26:37.523285
171	49	1	18430	18397	-33	\N	\N	\N	\N	\N	f	2026-07-09 15:26:48.15351
172	49	2	18415	18381	-34	\N	\N	\N	\N	\N	f	2026-07-09 15:27:00.690989
173	47	1	18565	18448	-117	7.8	0.1	-113.35717496238102	\N	\N	f	2026-07-09 15:40:39.484611
174	50	1	18438	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 15:42:10.124752
175	50	1	18438	18431	-7	\N	\N	\N	\N	\N	f	2026-07-09 15:42:26.013034
176	51	1	18419	\N	\N	\N	\N	\N	\N	\N	f	2026-07-09 15:49:51.938699
177	51	1	18419	18400	-19	\N	\N	\N	\N	\N	f	2026-07-09 15:49:58.977729
178	52	1	18442	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 09:01:20.13908
179	52	1	18442	18428	-14	\N	\N	\N	\N	\N	f	2026-07-10 09:01:29.176899
180	53	1	18470	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 09:12:29.067599
181	53	1	18470	18472	2	\N	\N	\N	\N	\N	f	2026-07-10 09:12:39.942013
182	54	1	18428	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 09:20:33.942227
183	54	1	18428	18412	-16	\N	\N	\N	\N	\N	f	2026-07-10 09:20:41.704713
184	55	1	18423	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 13:51:51.117401
185	55	1	18423	18418	-5	\N	\N	\N	\N	\N	f	2026-07-10 13:52:04.598201
186	56	1	18455	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 14:03:14.049821
187	56	1	18455	18460	5	\N	\N	\N	\N	\N	f	2026-07-10 14:03:22.198022
188	57	1	18435	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 15:20:19.655997
189	57	1	18435	18411	-24	\N	\N	\N	\N	\N	f	2026-07-10 15:20:33.81144
190	58	1	18161	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 15:27:13.845713
191	58	1	18161	18142	-19	\N	\N	\N	\N	\N	f	2026-07-10 15:27:25.766594
192	59	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 15:33:42.707504
193	59	1	18448	18446	-2	\N	\N	\N	\N	\N	f	2026-07-10 15:33:50.780046
194	60	1	18403	\N	\N	\N	\N	\N	\N	\N	f	2026-07-10 15:39:22.476482
195	61	1	18445	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:08:47.413358
196	62	1	18422	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:09:32.50124
197	62	1	18422	18420	-2	\N	\N	\N	\N	\N	f	2026-07-11 10:09:40.84215
198	63	1	18450	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:55:31.322415
201	65	1	18462	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:56:45.783494
202	66	1	18456	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 11:05:04.784787
203	66	1	18456	18469	13	\N	\N	\N	\N	\N	f	2026-07-11 11:05:47.294788
204	67	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 11:12:41.6593
205	67	1	18448	18444	-4	\N	\N	\N	\N	\N	f	2026-07-11 11:13:19.429259
206	68	1	18430	\N	\N	\N	\N	\N	\N	\N	f	2026-07-12 12:00:56.154575
207	68	1	18430	18446	16	\N	\N	\N	\N	\N	f	2026-07-12 12:01:11.170182
208	69	1	18421	\N	\N	\N	\N	\N	\N	\N	f	2026-07-12 12:19:54.642339
209	69	1	18421	18407	-14	\N	\N	\N	\N	\N	f	2026-07-12 12:20:02.849939
210	70	1	18459	\N	\N	\N	\N	\N	\N	\N	f	2026-07-12 12:27:21.159689
211	70	1	18459	18461	2	\N	\N	\N	\N	\N	f	2026-07-12 12:27:26.673848
212	71	1	18381	\N	\N	\N	\N	\N	\N	\N	f	2026-07-12 12:33:49.738702
213	71	1	18381	18379	-2	\N	\N	\N	\N	\N	f	2026-07-12 12:33:56.788118
214	65	1	18462	18434	-28	\N	\N	\N	\N	\N	f	2026-07-12 12:38:19.341799
215	72	1	18443	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 08:19:26.365757
216	72	1	18443	18411	-32	\N	\N	\N	\N	\N	f	2026-07-13 08:19:36.007235
217	73	1	18444	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 08:20:46.012745
218	73	1	18444	18446	2	\N	\N	\N	\N	\N	f	2026-07-13 08:20:52.258874
219	74	1	18437	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 08:30:55.302665
220	74	1	18437	18433	-4	\N	\N	\N	\N	\N	f	2026-07-13 08:31:00.649454
221	75	1	18432	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 08:53:01.658679
222	75	1	18432	18435	3	\N	\N	\N	\N	\N	f	2026-07-13 08:53:07.954329
223	76	1	18435	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:03:08.071269
224	76	1	18435	18428	-7	\N	\N	\N	\N	\N	f	2026-07-13 09:03:14.744822
225	77	1	18439	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:09:29.550728
226	77	1	18439	18441	2	\N	\N	\N	\N	\N	f	2026-07-13 09:09:35.495627
227	78	1	18437	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:17:44.816774
228	78	1	18437	18419	-18	\N	\N	\N	\N	\N	f	2026-07-13 09:17:51.883862
229	79	1	18447	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:26:46.252412
230	79	1	18447	18428	-19	\N	\N	\N	\N	\N	f	2026-07-13 09:26:53.635857
231	80	1	18436	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:35:02.008825
232	80	1	18436	18426	-10	\N	\N	\N	\N	\N	f	2026-07-13 09:35:08.33496
233	81	1	18444	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:40:53.638475
234	81	1	18444	18426	-18	\N	\N	\N	\N	\N	f	2026-07-13 09:41:01.902587
235	82	1	18443	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 09:51:29.100802
236	82	1	18443	18432	-11	\N	\N	\N	\N	\N	f	2026-07-13 09:51:34.999366
237	83	1	18440	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 10:02:00.853237
238	83	1	18440	18438	-2	\N	\N	\N	\N	\N	f	2026-07-13 10:02:07.778244
239	84	1	18440	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 10:11:30.696613
240	84	1	18440	18441	1	\N	\N	\N	\N	\N	f	2026-07-13 10:11:36.73349
241	85	1	18456	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 10:18:19.441756
242	85	1	18456	18464	8	\N	\N	\N	\N	\N	f	2026-07-13 10:18:25.940675
243	86	1	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 14:01:35.008483
244	86	1	18431	18422	-9	\N	\N	\N	\N	\N	f	2026-07-13 14:01:41.799109
245	87	1	18277	\N	\N	7.8	1	\N	\N	\N	f	2026-07-13 14:10:53.183225
246	87	1	18277	18250	-27	7.8	1	-26.397160323407608	\N	\N	f	2026-07-13 14:11:04.101907
247	88	1	18452	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 14:22:51.475103
248	88	1	18452	18439	-13	\N	\N	\N	\N	\N	f	2026-07-13 14:22:59.747577
249	89	1	18439	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 14:31:07.531943
250	89	1	18439	18411	-28	\N	\N	\N	\N	\N	f	2026-07-13 14:31:15.09536
251	90	1	18424	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 14:41:21.454363
252	90	1	18424	18430	6	\N	\N	\N	\N	\N	f	2026-07-13 14:41:28.928449
253	91	1	18292	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 14:46:22.94052
254	91	1	18292	18282	-10	\N	\N	\N	\N	\N	f	2026-07-13 14:46:33.043036
255	92	1	18392	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 14:57:20.210388
256	92	1	18392	18387	-5	\N	\N	\N	\N	\N	f	2026-07-13 14:57:26.18287
257	93	1	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 15:07:32.304424
258	93	1	18431	18414	-17	\N	\N	\N	\N	\N	f	2026-07-13 15:07:37.879342
259	94	1	18462	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-13 15:23:57.94344
260	94	1	18462	18458	-4	7.8	0.1	-3.8754589730728557	\N	\N	f	2026-07-13 15:24:04.764058
261	95	1	18288	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 15:27:49.979718
262	95	1	18288	18284	-4	\N	\N	\N	\N	\N	f	2026-07-13 15:27:55.020364
263	96	1	18445	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 15:38:12.663694
264	96	1	18445	18427	-18	\N	\N	\N	\N	\N	f	2026-07-13 15:38:19.538618
265	97	1	18431	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 15:43:20.022263
266	97	1	18431	18429	-2	\N	\N	\N	\N	\N	f	2026-07-13 15:43:27.145985
267	98	1	18423	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 15:52:34.154236
268	98	1	18423	18414	-9	\N	\N	\N	\N	\N	f	2026-07-13 15:52:42.147623
269	99	1	18438	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 16:10:23.648537
270	99	1	18438	18427	-11	\N	\N	\N	\N	\N	f	2026-07-13 16:10:28.593028
271	100	1	18443	\N	\N	\N	\N	\N	\N	\N	f	2026-07-13 16:16:27.495838
272	100	1	18443	18446	3	\N	\N	\N	\N	\N	f	2026-07-13 16:16:33.571531
273	101	1	18402	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-13 16:32:07.939047
274	101	1	18402	18386	-16	7.8	0.1	-15.501835892291423	\N	\N	f	2026-07-13 16:32:14.923147
275	102	1	18495	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 08:11:57.00658
276	102	1	18495	18492	-3	\N	\N	\N	\N	\N	f	2026-07-14 08:12:07.974384
277	103	1	18481	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 08:18:55.721824
278	103	1	18481	18480	-1	7.8	0.1	-0.9688647432682139	\N	\N	f	2026-07-14 08:19:04.460717
279	104	1	18485	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 08:23:59.359704
280	104	1	18485	18487	2	\N	\N	\N	\N	\N	f	2026-07-14 08:24:13.328353
281	105	1	18428	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 08:28:36.633655
282	105	1	18428	18426	-2	\N	\N	\N	\N	\N	f	2026-07-14 08:28:42.560206
283	106	1	18394	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 08:34:29.201013
284	106	1	18394	18398	4	\N	\N	\N	\N	\N	f	2026-07-14 08:34:37.460041
285	107	1	18425	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 08:43:17.495455
286	107	1	18425	18409	-16	7.8	0.1	-15.501835892291423	\N	\N	f	2026-07-14 08:43:25.153275
287	108	1	18461	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 10:34:58.795744
288	108	1	18461	18469	8	\N	\N	\N	\N	\N	f	2026-07-14 10:35:05.383151
289	109	1	18455	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 10:45:18.203238
290	109	1	18455	18453	-2	\N	\N	\N	\N	\N	f	2026-07-14 10:45:35.447712
291	110	1	18428	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 10:56:53.186916
292	111	1	18437	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:05:02.980885
293	111	1	18437	18436	-1	\N	\N	\N	\N	\N	f	2026-07-14 11:05:17.899599
294	112	1	18442	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:12:05.04088
295	112	1	18442	18403	-39	\N	\N	\N	\N	\N	f	2026-07-14 11:12:34.447253
296	113	1	18439	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:15:48.642566
297	113	1	18439	18410	-29	\N	\N	\N	\N	\N	f	2026-07-14 11:16:01.657288
298	114	1	18315	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:18:34.383915
299	114	1	18315	18301	-14	\N	\N	\N	\N	\N	f	2026-07-14 11:18:42.516257
300	115	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:33:33.930899
301	116	1	18258	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:40:59.8397
302	117	1	18447	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:44:04.244905
303	117	1	18447	18442	-5	\N	\N	\N	\N	\N	f	2026-07-14 11:44:10.614488
304	118	1	18417	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:44:38.283934
305	118	1	18417	18344	-73	\N	\N	\N	\N	\N	f	2026-07-14 11:45:26.990163
306	119	1	18263	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 11:47:39.332461
307	119	1	18263	18240	-23	\N	\N	\N	\N	\N	f	2026-07-14 11:47:51.924513
308	120	1	18054	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 12:05:28.789778
309	120	1	18054	18031	-23	\N	\N	\N	\N	\N	f	2026-07-14 12:05:35.837824
310	121	1	17995	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 12:07:44.94174
311	121	1	17995	17986	-9	\N	\N	\N	\N	\N	f	2026-07-14 12:07:54.605929
312	122	1	17607	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 13:10:16.913656
313	122	1	17607	17601	-6	\N	\N	\N	\N	\N	f	2026-07-14 13:10:23.325972
314	123	1	17469	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 13:13:05.379175
315	123	1	17469	17470	1	7.8	0.1	0.9688647432682139	\N	\N	f	2026-07-14 13:13:15.945582
316	124	1	18298	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 13:17:11.791056
317	124	1	18298	18270	-28	7.8	0.1	-27.12821281150999	\N	\N	f	2026-07-14 13:17:20.822665
318	121	1	17000	17500	500	7.8	0.1	484.4323716341069	\N	\N	f	2026-07-14 13:20:28.276948
319	125	1	18209	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 13:27:10.396033
320	125	1	18209	18199	-10	\N	\N	\N	\N	\N	f	2026-07-14 13:27:18.691154
321	126	1	18021	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 13:29:26.670472
322	126	1	18021	17997	-24	7.8	0.1	-23.252753838437133	\N	\N	f	2026-07-14 13:29:45.03849
323	127	1	17955	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 13:30:39.149318
324	127	1	17955	17935	-20	\N	\N	\N	\N	\N	f	2026-07-14 13:30:45.826151
325	128	1	17818	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 13:36:24.907647
326	128	1	17818	17798	-20	7.8	0.1	-19.377294865364277	\N	\N	f	2026-07-14 13:36:33.081157
327	129	1	17678	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 13:40:08.537785
328	129	1	17678	17664	-14	7.8	0.1	-13.564106405754995	\N	\N	f	2026-07-14 13:40:16.053918
329	130	1	18398	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 13:49:48.451453
330	130	1	18398	18369	-29	7.8	0.1	-28.097077554778203	\N	\N	f	2026-07-14 13:49:55.994869
331	131	1	18402	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:07:29.503663
332	131	1	18402	18370	-32	7.8	0.1	-31.003671784582846	\N	\N	f	2026-07-14 14:07:38.129164
333	132	1	18470	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 14:22:12.707437
334	132	1	18470	18475	5	\N	\N	\N	\N	\N	f	2026-07-14 14:22:20.560161
335	133	1	18472	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:22:52.715956
336	133	1	18472	18462	-10	7.8	0.1	-9.688647432682139	\N	\N	f	2026-07-14 14:23:01.34004
337	134	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 14:37:40.933775
338	134	1	18448	18442	-6	\N	\N	\N	\N	\N	f	2026-07-14 14:37:50.352396
339	135	1	18448	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:44:13.550145
340	135	1	18448	18428	-20	7.8	0.1	-19.377294865364277	\N	\N	f	2026-07-14 14:44:20.764823
341	136	1	18354	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:45:03.380192
342	136	1	18354	18331	-23	7.8	0.1	-22.28388909516892	\N	\N	f	2026-07-14 14:45:17.512025
343	137	1	18223	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:46:49.550351
344	138	1	18165	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:47:39.165938
345	138	1	18165	18159	-6	7.8	0.1	-5.813188459609283	\N	\N	f	2026-07-14 14:48:08.59694
346	139	1	18454	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 14:56:08.309064
347	139	1	18454	18457	3	7.8	0.1	2.9065942298046417	\N	\N	f	2026-07-14 14:56:17.102982
348	140	1	18438	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 15:06:14.891238
349	140	1	18438	18433	-5	\N	\N	\N	\N	\N	f	2026-07-14 15:06:22.802516
350	141	1	18416	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 15:07:49.847231
351	141	1	18416	18417	1	7.8	0.1	0.9688647432682139	\N	\N	f	2026-07-14 15:07:59.217633
352	142	1	18444	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 15:29:25.058611
353	142	1	18444	18440	-4	7.8	0.1	-3.8754589730728557	\N	\N	f	2026-07-14 15:29:33.393104
354	143	1	18430	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 15:31:38.941528
355	143	1	18430	18425	-5	\N	\N	\N	\N	\N	f	2026-07-14 15:31:59.980075
356	144	1	18328	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-14 15:33:38.943003
357	144	1	18328	18331	3	7.8	0.1	2.9065942298046417	\N	\N	f	2026-07-14 15:33:47.43243
358	145	1	18452	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 15:37:09.482988
359	145	1	18452	18459	7	\N	\N	\N	\N	\N	f	2026-07-14 15:37:16.383785
360	146	1	18403	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 15:38:11.107314
361	146	1	18403	18415	12	\N	\N	\N	\N	\N	f	2026-07-14 15:38:22.28998
362	147	1	18392	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 15:39:19.82209
363	147	1	18392	18392	0	\N	\N	\N	\N	\N	f	2026-07-14 15:39:25.845213
364	148	1	18175	\N	\N	\N	\N	\N	\N	\N	f	2026-07-14 15:49:01.753536
365	148	1	18175	18178	3	\N	\N	\N	\N	\N	f	2026-07-14 15:49:07.357514
366	149	1	18367	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 10:31:42.820572
367	149	1	18367	18335	-32	7.8	0.1	-32.92960893854748	\N	\N	f	2026-07-15 10:31:54.472084
368	150	1	18277	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 10:32:57.591804
369	150	1	18277	18264	-13	7.8	0.1	-13.377653631284916	\N	\N	f	2026-07-15 10:33:05.315534
370	151	1	18452	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 13:58:15.552226
371	151	1	18452	18468	16	7.8	0.1	16.46480446927374	\N	\N	f	2026-07-15 13:58:22.705139
372	152	1	18168	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 14:18:01.737987
373	152	1	18168	18154	-14	7.8	0.1	-14.406703910614524	\N	\N	f	2026-07-15 14:18:12.036798
374	153	1	18429	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 14:26:42.713374
375	153	1	18429	18417	-12	7.8	0.1	-12.348603351955305	\N	\N	f	2026-07-15 14:26:49.219602
376	154	1	18444	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 14:34:43.371878
377	154	1	18444	18437	-7	7.8	0.1	-7.203351955307262	\N	\N	f	2026-07-15 14:34:49.622596
378	155	1	18462	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 14:39:34.912467
379	155	1	18462	18475	13	7.8	0.1	13.377653631284916	\N	\N	f	2026-07-15 14:39:42.172069
380	156	1	18431	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 14:53:55.665725
381	156	1	18431	18423	-8	7.8	0.1	-8.23240223463687	\N	\N	f	2026-07-15 14:54:03.68693
382	157	1	18463	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 15:08:16.400448
383	157	1	18463	18455	-8	7.8	0.1	-8.23240223463687	\N	\N	f	2026-07-15 15:08:22.564642
384	158	1	18455	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-15 15:20:12.964505
385	158	1	18455	18457	2	7.8	0.1	2.0581005586592176	\N	\N	f	2026-07-15 15:20:18.659099
386	159	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-15 15:21:41.515892
387	159	1	18448	18442	-6	\N	\N	\N	\N	\N	f	2026-07-15 15:21:51.022454
388	160	1	18107	\N	\N	\N	\N	\N	\N	\N	f	2026-07-15 15:30:49.973207
389	160	1	18107	18114	7	\N	\N	\N	\N	\N	f	2026-07-15 15:30:55.677128
390	161	1	18043	\N	\N	\N	\N	\N	\N	\N	f	2026-07-15 15:35:29.028616
391	161	1	18043	18054	11	\N	\N	\N	\N	\N	f	2026-07-15 15:35:34.573143
392	162	1	18458	\N	\N	\N	\N	\N	\N	\N	f	2026-07-15 15:44:17.134413
393	162	1	18458	18458	0	\N	\N	\N	\N	\N	f	2026-07-15 15:44:23.574096
394	163	1	18462	\N	\N	\N	\N	\N	\N	\N	f	2026-07-15 15:49:33.199177
395	163	1	18462	18466	4	\N	\N	\N	\N	\N	f	2026-07-15 15:49:40.626143
396	164	1	18436	\N	\N	\N	\N	\N	\N	\N	f	2026-07-15 15:59:43.954847
397	164	1	18436	18434	-2	\N	\N	\N	\N	\N	f	2026-07-15 15:59:49.967324
398	165	1	18449	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 09:26:40.708399
399	165	1	18449	18441	-8	\N	\N	\N	\N	\N	f	2026-07-16 09:26:48.416026
400	166	1	18434	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 09:28:22.421636
401	166	1	18434	18439	5	\N	\N	\N	\N	\N	f	2026-07-16 09:28:28.812069
402	167	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 09:37:31.547066
403	167	1	18448	18440	-8	\N	\N	\N	\N	\N	f	2026-07-16 09:37:37.324628
404	168	1	18435	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 09:40:12.196933
405	168	1	18435	18421	-14	\N	\N	\N	\N	\N	f	2026-07-16 09:40:19.088297
406	169	1	18455	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 09:49:01.191484
407	169	1	18455	18444	-11	\N	\N	\N	\N	\N	f	2026-07-16 09:49:09.276942
408	170	1	18446	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 09:56:49.88123
409	170	1	18446	18438	-8	\N	\N	\N	\N	\N	f	2026-07-16 09:56:59.929247
410	171	1	18466	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:14:32.291051
411	171	1	18466	18468	2	\N	\N	\N	\N	\N	f	2026-07-16 10:14:39.992582
412	172	1	18440	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:20:24.562475
413	172	1	18440	18427	-13	\N	\N	\N	\N	\N	f	2026-07-16 10:20:32.478238
414	173	1	18253	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:23:09.134924
415	173	1	18253	18232	-21	\N	\N	\N	\N	\N	f	2026-07-16 10:23:14.224188
416	174	1	18443	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:24:55.704566
417	174	1	18443	18443	0	\N	\N	\N	\N	\N	f	2026-07-16 10:25:03.980902
418	175	1	18434	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:35:22.895297
419	175	1	18434	18437	3	\N	\N	\N	\N	\N	f	2026-07-16 10:35:29.415698
420	176	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:38:03.039415
421	176	1	18448	18431	-17	\N	\N	\N	\N	\N	f	2026-07-16 10:38:08.615291
422	177	1	18442	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:48:26.104757
423	177	1	18442	18426	-16	\N	\N	\N	\N	\N	f	2026-07-16 10:48:32.431329
424	178	1	18410	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 10:49:35.226842
425	178	1	18410	18412	2	7.8	0.1	2.0581005586592176	\N	\N	f	2026-07-16 10:49:41.110575
426	179	1	18458	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 10:54:09.673851
427	179	1	18458	18453	-5	\N	\N	\N	\N	\N	f	2026-07-16 10:54:14.859636
428	180	1	18442	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:02:43.964313
429	180	1	18442	18431	-11	7.8	0.1	-11.319553072625697	\N	\N	f	2026-07-16 11:02:50.165368
430	181	1	18436	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:09:53.596408
431	181	1	18436	18438	2	7.8	0.1	2.0581005586592176	\N	\N	f	2026-07-16 11:09:58.947072
432	182	1	17988	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:17:16.883305
433	182	1	17988	17991	3	7.8	0.1	3.087150837988826	\N	\N	f	2026-07-16 11:17:24.064266
444	157	1	18461	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:52:10.192992
445	157	1	18461	18457	-4	7.8	0.1	-4.116201117318435	\N	\N	f	2026-07-16 11:52:14.704269
452	138	1	18438	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 12:02:10.144392
453	138	1	18438	18425	-13	7.8	0.1	-13.377653631284916	\N	\N	f	2026-07-16 12:02:14.725995
456	191	1	18471	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 13:05:15.222914
457	191	1	18471	18475	4	7.8	0.1	4.116201117318435	\N	\N	f	2026-07-16 13:05:20.328722
458	192	1	18228	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 13:10:04.617552
459	193	1	18227	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 13:10:18.832655
460	193	1	18227	18219	-8	7.8	0.1	-8.23240223463687	\N	\N	f	2026-07-16 13:10:26.180429
461	194	1	18178	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 13:11:48.85069
462	194	1	18178	18178	0	7.8	0.1	0	\N	\N	f	2026-07-16 13:11:54.598033
436	228	1	18446	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 11:22:15.728852
437	228	1	18446	18438	-8	\N	\N	\N	\N	\N	f	2026-07-16 11:22:20.392429
438	229	1	18455	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:27:06.434679
440	230	1	18458	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:31:02.664822
441	230	1	18458	18473	15	7.8	0.1	15.435754189944134	\N	\N	f	2026-07-16 11:31:13.476729
442	231	1	18448	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:35:49.05949
443	231	1	18448	18446	-2	7.8	0.1	-2.0581005586592176	\N	\N	f	2026-07-16 11:35:53.825297
446	232	1	18452	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 11:52:38.577703
447	232	1	18452	18447	-5	7.8	0.1	-5.145251396648045	\N	\N	f	2026-07-16 11:52:44.872583
448	233	1	18435	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 11:55:42.002924
449	233	1	18435	18425	-10	\N	\N	\N	\N	\N	f	2026-07-16 11:55:47.035884
454	234	1	18305	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 12:02:43.489754
455	234	1	18305	18301	-4	\N	\N	\N	\N	\N	f	2026-07-16 12:02:47.992712
450	\N	1	18456	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 11:59:15.330328
451	\N	1	18456	18452	-4	\N	\N	\N	\N	\N	f	2026-07-16 11:59:19.517444
463	195	1	18433	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 13:25:40.196553
464	195	1	18433	18429	-4	\N	\N	\N	\N	\N	f	2026-07-16 13:25:53.462402
465	196	1	18457	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 13:44:21.662673
466	196	1	18457	18468	11	7.8	0.1	11.319553072625697	\N	\N	f	2026-07-16 13:44:28.718457
467	116	1	18258	18485	227	\N	\N	\N	\N	\N	f	2026-07-16 14:15:37.500634
468	197	1	18450	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 14:57:44.121783
469	198	1	18392	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-16 16:02:37.740887
470	198	1	18392	18322	-70	7.8	0.1	-72.03351955307262	\N	\N	f	2026-07-16 16:03:07.350338
471	199	1	18444	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-17 08:15:18.876038
472	199	1	18444	18439	-5	7.8	0.1	-5.145251396648045	\N	\N	f	2026-07-17 08:15:25.130364
473	200	1	18409	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-17 08:15:53.958029
474	201	1	18177	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-17 11:43:59.46469
475	201	1	18177	18187	10	7.8	0.1	10.29050279329609	\N	\N	f	2026-07-17 11:44:05.184729
476	202	1	18430	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-17 15:18:48.722636
477	202	1	18430	18408	-22	7.8	0.1	-22.639106145251393	\N	\N	f	2026-07-17 15:18:54.483844
478	203	1	18441	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 08:46:55.115989
479	203	1	18441	18433	-8	7.8	0.1	-8.23240223463687	\N	\N	f	2026-07-18 08:47:00.568888
480	204	1	18450	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 09:36:30.087646
481	204	1	18450	18459	9	7.8	0.1	9.26145251396648	\N	\N	f	2026-07-18 09:36:38.084374
482	205	1	18440	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 09:46:23.754308
483	205	1	18440	18452	12	7.8	0.1	12.348603351955305	\N	\N	f	2026-07-18 09:46:31.410556
484	206	1	18394	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 09:51:26.787289
485	206	1	18394	18376	-18	7.8	0.1	-18.52290502793296	\N	\N	f	2026-07-18 09:51:33.237888
486	207	1	18475	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 10:04:09.878963
487	207	1	18475	18474	-1	7.8	0.1	-1.0290502793296088	\N	\N	f	2026-07-18 10:04:16.579731
488	208	1	18432	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 10:16:17.758638
489	208	1	18432	18429	-3	7.8	0.1	-3.087150837988826	\N	\N	f	2026-07-18 10:16:23.321039
490	209	1	18450	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 10:28:52.864724
491	209	1	18450	18457	7	7.8	0.1	7.203351955307262	\N	\N	f	2026-07-18 10:28:58.918683
492	210	1	18436	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 10:40:07.88648
493	210	1	18436	18433	-3	7.8	0.1	-3.087150837988826	\N	\N	f	2026-07-18 10:40:13.410763
494	211	1	18412	\N	\N	\N	\N	\N	\N	\N	f	2026-07-18 10:45:47.806381
495	211	1	18412	18387	-25	\N	\N	\N	\N	\N	f	2026-07-18 10:45:52.804337
496	212	1	18433	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 11:12:44.368909
497	212	1	18433	18447	14	7.8	0.1	14.406703910614524	\N	\N	f	2026-07-18 11:12:53.236875
498	213	1	18452	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-18 11:22:54.833675
499	213	1	18452	18463	11	7.8	0.1	11.319553072625697	\N	\N	f	2026-07-18 11:23:00.868384
500	214	1	18426	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-19 10:07:25.549579
501	214	1	18426	18418	-8	7.8	0.1	-8.23240223463687	\N	\N	f	2026-07-19 10:07:32.100645
502	215	1	18449	\N	\N	\N	\N	\N	\N	\N	f	2026-07-19 10:10:35.458142
503	215	1	18449	18424	-25	\N	\N	\N	\N	\N	f	2026-07-19 10:10:41.653723
504	216	1	18453	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-19 11:50:04.032324
505	216	1	18453	18453	0	7.8	0.1	0	\N	\N	f	2026-07-19 11:50:10.003694
506	217	1	18462	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-19 11:55:07.815772
507	217	1	18462	18468	6	7.8	0.1	6.174301675977652	\N	\N	f	2026-07-19 11:55:21.407094
508	218	1	18430	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-20 08:31:21.064837
509	218	1	18430	18417	-13	7.8	0.1	-13.377653631284916	\N	\N	f	2026-07-20 08:31:28.952425
510	219	1	18384	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-21 10:15:19.309888
511	219	1	18384	18388	4	7.8	0.1	4.116201117318435	\N	\N	f	2026-07-21 10:15:26.60024
512	219	2	0	1000	\N	7.8	0.1	\N	\N	\N	f	2026-07-21 14:08:19.349476
513	219	3	50	1050	1000	7.8	0.1	1029.0502793296089	\N	\N	f	2026-07-21 14:08:35.878684
514	219	1	50	1050	1000	5	3	1027.9329608938547	\N	\N	f	2026-07-21 15:05:17.713031
515	219	1	50	1050	1000	5	3	1027.9329608938547	\N	\N	f	2026-07-21 15:08:06.506865
434	227	1	18446	\N	\N	\N	\N	\N	\N	\N	f	2026-07-16 11:17:54.381063
435	227	1	18446	18441	-5	\N	\N	\N	\N	\N	f	2026-07-16 11:17:59.004696
439	229	1	18455	18458	3	7.8	0.1	3.087150837988826	\N	\N	f	2026-07-16 11:27:15.670083
1	\N	2	18425	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 11:56:17.157694
2	\N	1	18420	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 11:56:31.957937
3	\N	2	18425	18341	-84	\N	\N	\N	\N	\N	f	2026-07-01 11:56:58.460503
4	\N	1	18420	18337	-83	\N	\N	\N	\N	\N	f	2026-07-01 11:57:11.284338
199	\N	1	18450	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:55:31.323248
200	\N	1	18450	18472	22	\N	\N	\N	\N	\N	f	2026-07-11 10:56:00.657871
517	276	1	18351	\N	\N	7.8	0.1	\N	\N	\N	f	2026-07-21 18:19:23.776122
518	276	1	18351	18344	-7	7.8	0.1	-7.203351955307262	\N	\N	f	2026-07-21 18:19:31.635768
\.


--
-- Data for Name: sozlamalar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sozlamalar (id, kalit, qiymat, updated_at) FROM stdin;
1	konditsion_narx	5000	2026-07-12 10:43:02.752532
2	telegram_token	8619880300:AAHU1sWHDxMRY4yeEtJjqTBxFRMUpjGFxKQ	2026-07-12 10:45:56.898944
3	tuda_raqam		2026-07-18 10:23:30.491814
4	klass	1	2026-07-18 10:23:30.491814
5	sinf		2026-07-18 10:23:30.491814
6	terim_turi	Kul terim	2026-07-18 10:23:30.491814
7	seleksiya_navi	Xorazm-150	2026-07-18 10:23:30.491814
8	namlik		2026-07-18 10:23:30.491814
9	ifloslik		2026-07-18 10:23:30.491814
\.


--
-- Data for Name: tizim_xatolari; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tizim_xatolari (id, turi, xabar, korilgan, created_at) FROM stdin;
1	telegram	404 Client Error: Not Found for url: https://api.telegram.org/botNOTOGRI_TOKEN_SINOV_UCHUN/sendMessage	f	2026-07-21 15:46:47.245947
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password, role, is_active, created_at) FROM stdin;
1	admin	$2b$12$aj6gPR5e3ywk54kcdytdqeFANJW3EUNDJoH8cTgvD8WAyEQzVgY7q	admin	t	2026-06-30 14:31:48.315442
2	operator	$2b$12$9Cox0cNjpvlMIjn21xQXI.BCZpSub/3DyhtszR.BIHryZyCmnuVqS	operator	t	2026-06-30 14:31:48.315442
\.


--
-- Name: hujjat_raqam_hisoblagich_yil_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hujjat_raqam_hisoblagich_yil_seq', 1, false);


--
-- Name: hujjatlar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hujjatlar_id_seq', 276, true);


--
-- Name: mahsulotlar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mahsulotlar_id_seq', 4, true);


--
-- Name: mashinalar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mashinalar_id_seq', 187, true);


--
-- Name: navbat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.navbat_id_seq', 224, true);


--
-- Name: olchovlar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.olchovlar_id_seq', 518, true);


--
-- Name: sozlamalar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sozlamalar_id_seq', 9, true);


--
-- Name: tizim_xatolari_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tizim_xatolari_id_seq', 1, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: hujjat_raqam_hisoblagich hujjat_raqam_hisoblagich_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hujjat_raqam_hisoblagich
    ADD CONSTRAINT hujjat_raqam_hisoblagich_pkey PRIMARY KEY (yil);


--
-- Name: hujjatlar hujjatlar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hujjatlar
    ADD CONSTRAINT hujjatlar_pkey PRIMARY KEY (id);


--
-- Name: mahsulotlar mahsulotlar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mahsulotlar
    ADD CONSTRAINT mahsulotlar_pkey PRIMARY KEY (id);


--
-- Name: mashinalar mashinalar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mashinalar
    ADD CONSTRAINT mashinalar_pkey PRIMARY KEY (id);


--
-- Name: navbat navbat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navbat
    ADD CONSTRAINT navbat_pkey PRIMARY KEY (id);


--
-- Name: olchovlar olchovlar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.olchovlar
    ADD CONSTRAINT olchovlar_pkey PRIMARY KEY (id);


--
-- Name: sozlamalar sozlamalar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sozlamalar
    ADD CONSTRAINT sozlamalar_pkey PRIMARY KEY (id);


--
-- Name: tizim_xatolari tizim_xatolari_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tizim_xatolari
    ADD CONSTRAINT tizim_xatolari_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_hujjatlar_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_hujjatlar_id ON public.hujjatlar USING btree (id);


--
-- Name: ix_hujjatlar_raqam; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_hujjatlar_raqam ON public.hujjatlar USING btree (raqam);


--
-- Name: ix_mahsulotlar_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mahsulotlar_id ON public.mahsulotlar USING btree (id);


--
-- Name: ix_mashinalar_davlat_raqami; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mashinalar_davlat_raqami ON public.mashinalar USING btree (davlat_raqami);


--
-- Name: ix_mashinalar_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_mashinalar_id ON public.mashinalar USING btree (id);


--
-- Name: ix_navbat_hujjat_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_navbat_hujjat_id ON public.navbat USING btree (hujjat_id);


--
-- Name: ix_navbat_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_navbat_id ON public.navbat USING btree (id);


--
-- Name: ix_olchovlar_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_olchovlar_id ON public.olchovlar USING btree (id);


--
-- Name: ix_sozlamalar_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_sozlamalar_id ON public.sozlamalar USING btree (id);


--
-- Name: ix_sozlamalar_kalit; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_sozlamalar_kalit ON public.sozlamalar USING btree (kalit);


--
-- Name: ix_tizim_xatolari_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_tizim_xatolari_id ON public.tizim_xatolari USING btree (id);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: hujjatlar fk_hujjat_mahsulot; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hujjatlar
    ADD CONSTRAINT fk_hujjat_mahsulot FOREIGN KEY (mahsulot_id) REFERENCES public.mahsulotlar(id) ON DELETE RESTRICT;


--
-- Name: hujjatlar fk_hujjat_mashina; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hujjatlar
    ADD CONSTRAINT fk_hujjat_mashina FOREIGN KEY (mashina_id) REFERENCES public.mashinalar(id) ON DELETE RESTRICT;


--
-- Name: navbat fk_navbat_hujjat; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navbat
    ADD CONSTRAINT fk_navbat_hujjat FOREIGN KEY (hujjat_id) REFERENCES public.hujjatlar(id) ON DELETE CASCADE;


--
-- Name: olchovlar fk_olchov_hujjat; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.olchovlar
    ADD CONSTRAINT fk_olchov_hujjat FOREIGN KEY (hujjat_id) REFERENCES public.hujjatlar(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict g9zhlnoIUAIDZMAKfRX9SHWUkyXE8Z6M13s1SipRR6DRnEa3JzekgCDRYDHAW9Z

