--
-- PostgreSQL database dump
--

\restrict 6qccRQfHL5YxHXLXRpNrDsq4fwvIga8r2QVe7PSN8I9zZlHWUA1rrdz11Q5ajRY

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

SET default_tablespace = '';

SET default_table_access_method = heap;

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
    holat character varying,
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
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


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
\.


--
-- Data for Name: mahsulotlar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mahsulotlar (id, nom, konditsiya_bor, is_active) FROM stdin;
1	Chigit	t	t
2	Chiganoq	f	t
3	Chiganoq po'chog'i	f	t
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
\.


--
-- Data for Name: navbat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.navbat (id, hujjat_id, mashina_id, raqam, turi, shofyor, firma, mahsulot_id, mahsulot_nomi, vaqt, kelgan_vaqt, tuda_raqam, tiket_raqam, seleksiya_navi, klass, sinf, terim_turi, namlik, ifloslik, tugallandi, tugallangan_vaqt, aravalar_json, created_at) FROM stdin;
3	65	56	90 D 777DD	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	10:56	2026-07-11 10:56:48.48969		4938627	Xorazm-150	1		Kul terim	\N	\N	f	\N	{"1": {"tara": 18462, "brutto": null, "netto": null, "konditsion": null}, "2": {"tara": null, "brutto": null, "netto": null, "konditsion": null}, "3": {"tara": null, "brutto": null, "netto": null, "konditsion": null}}	2026-07-11 10:56:48.48969
4	66	57	90 t 555 tt	FAW		SABZAVOTNAVURUG'LARI MChJ	1	Chigit	11:05	2026-07-11 11:05:05.878966		4940848	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-11 11:05:47.344223	{}	2026-07-11 11:05:05.878966
5	67	58	90 741 aa	FAW		SABZAVOTNAVURUG'LARI MChJ	3	Chiganoq po'chog'i	11:12	2026-07-11 11:12:42.798599		5035315	Xorazm-150	1		Kul terim	\N	\N	t	2026-07-11 11:13:19.478089	{}	2026-07-11 11:12:42.798599
\.


--
-- Data for Name: olchovlar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.olchovlar (id, hujjat_id, arava_raqam, tara, brutto, netto, namlik, ifloslik, konditsion, tara_rasm, brutto_rasm, qolda_kiritildi, created_at) FROM stdin;
1	1	2	18425	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 11:56:17.157694
2	1	1	18420	\N	\N	\N	\N	\N	\N	\N	f	2026-07-01 11:56:31.957937
3	1	2	18425	18341	-84	\N	\N	\N	\N	\N	f	2026-07-01 11:56:58.460503
4	1	1	18420	18337	-83	\N	\N	\N	\N	\N	f	2026-07-01 11:57:11.284338
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
199	1250	1	18450	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:55:31.323248
198	63	1	18450	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:55:31.322415
200	1250	1	18450	18472	22	\N	\N	\N	\N	\N	f	2026-07-11 10:56:00.657871
201	65	1	18462	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 10:56:45.783494
202	66	1	18456	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 11:05:04.784787
203	66	1	18456	18469	13	\N	\N	\N	\N	\N	f	2026-07-11 11:05:47.294788
204	67	1	18448	\N	\N	\N	\N	\N	\N	\N	f	2026-07-11 11:12:41.6593
205	67	1	18448	18444	-4	\N	\N	\N	\N	\N	f	2026-07-11 11:13:19.429259
\.


--
-- Data for Name: sozlamalar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sozlamalar (id, kalit, qiymat, updated_at) FROM stdin;
1	konditsion_narx	5000	2026-07-12 10:43:02.752532
2	telegram_token	8619880300:AAHU1sWHDxMRY4yeEtJjqTBxFRMUpjGFxKQ	2026-07-12 10:45:56.898944
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password, role, is_active, created_at) FROM stdin;
1	admin	$2b$12$aj6gPR5e3ywk54kcdytdqeFANJW3EUNDJoH8cTgvD8WAyEQzVgY7q	admin	t	2026-06-30 14:31:48.315442
2	operator	$2b$12$9Cox0cNjpvlMIjn21xQXI.BCZpSub/3DyhtszR.BIHryZyCmnuVqS	operator	t	2026-06-30 14:31:48.315442
\.


--
-- Name: hujjatlar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hujjatlar_id_seq', 67, true);


--
-- Name: mahsulotlar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mahsulotlar_id_seq', 3, true);


--
-- Name: mashinalar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mashinalar_id_seq', 58, true);


--
-- Name: navbat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.navbat_id_seq', 5, true);


--
-- Name: olchovlar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.olchovlar_id_seq', 205, true);


--
-- Name: sozlamalar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sozlamalar_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


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
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- PostgreSQL database dump complete
--

\unrestrict 6qccRQfHL5YxHXLXRpNrDsq4fwvIga8r2QVe7PSN8I9zZlHWUA1rrdz11Q5ajRY

