--
-- PostgreSQL database dump
--

\restrict yCz0D168QkglG12ZwBvrU7IvrbDSEa51GGFhpMmVrB5eay0xQciJlQ1YeWdMzYk

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-07-28 15:49:20

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
-- TOC entry 220 (class 1259 OID 16415)
-- Name: fish_processor_employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fish_processor_employees (
    employee_name character varying(15),
    pay_per_hour integer,
    fish_lbs_processed_per_hour integer,
    price_per_lb integer
);


ALTER TABLE public.fish_processor_employees OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16400)
-- Name: la_jolla_tide_fishing_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.la_jolla_tide_fishing_status (
    july_date date,
    high_tide_chart_am time without time zone,
    high_tide_chart_pm time without time zone,
    low_tide_chart_am time without time zone,
    low_tide_chart_pm time without time zone,
    moon_phase character varying(20),
    kayak_fishing_day_status character varying(30) DEFAULT 'Normal Fishing Day'::character varying,
    pier_fishing_morning_status character varying(40),
    pier_fishing_evening_status character varying(40),
    est_am_fish_count_lbs integer,
    est_pm_fish_count_lbs integer
);


ALTER TABLE public.la_jolla_tide_fishing_status OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16506)
-- Name: total_profits; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.total_profits AS
 WITH RECURSIVE base_rates AS (
         SELECT fish_stat.july_date,
            (fish_stat.est_am_fish_count_lbs)::numeric AS am_total_lbs,
            (fish_stat.est_pm_fish_count_lbs)::numeric AS pm_total_lbs,
            emp.employee_name,
            emp.pay_per_hour,
            (emp.fish_lbs_processed_per_hour)::numeric AS lbs_per_hour,
            emp.price_per_lb,
            ((emp.price_per_lb)::numeric - ((emp.pay_per_hour)::numeric / (NULLIF(emp.fish_lbs_processed_per_hour, 0))::numeric)) AS profit_per_lb
           FROM (public.la_jolla_tide_fishing_status fish_stat
             CROSS JOIN public.fish_processor_employees emp)
          WHERE (emp.fish_lbs_processed_per_hour > 0)
        ), am_efficiency AS (
         SELECT base_rates.july_date,
            base_rates.am_total_lbs,
            base_rates.pm_total_lbs,
            base_rates.employee_name,
            base_rates.pay_per_hour,
            base_rates.lbs_per_hour,
            base_rates.price_per_lb,
            base_rates.profit_per_lb,
            row_number() OVER (PARTITION BY base_rates.july_date ORDER BY base_rates.profit_per_lb DESC) AS rnk
           FROM base_rates
        ), am_scheduler AS (
         SELECT am_efficiency.july_date,
            am_efficiency.rnk,
            am_efficiency.employee_name,
            am_efficiency.lbs_per_hour,
            am_efficiency.pay_per_hour,
            am_efficiency.price_per_lb,
            am_efficiency.am_total_lbs AS lbs_remaining_before,
                CASE
                    WHEN (am_efficiency.am_total_lbs > (0)::numeric) THEN LEAST(4.0, ceil((am_efficiency.am_total_lbs / am_efficiency.lbs_per_hour)))
                    ELSE (0)::numeric
                END AS hours_scheduled,
            LEAST(am_efficiency.am_total_lbs, (LEAST(4.0, ceil((am_efficiency.am_total_lbs / am_efficiency.lbs_per_hour))) * am_efficiency.lbs_per_hour)) AS lbs_processed,
            GREATEST((0)::numeric, (am_efficiency.am_total_lbs - (LEAST(4.0, ceil((am_efficiency.am_total_lbs / am_efficiency.lbs_per_hour))) * am_efficiency.lbs_per_hour))) AS lbs_remaining_after,
            1 AS processing_order
           FROM am_efficiency
          WHERE (am_efficiency.rnk = 1)
        UNION ALL
         SELECT r.july_date,
            r.rnk,
            r.employee_name,
            r.lbs_per_hour,
            r.pay_per_hour,
            r.price_per_lb,
            w.lbs_remaining_after AS lbs_remaining_before,
                CASE
                    WHEN (w.lbs_remaining_after > (0)::numeric) THEN LEAST(4.0, ceil((w.lbs_remaining_after / r.lbs_per_hour)))
                    ELSE (0)::numeric
                END AS hours_scheduled,
            LEAST(w.lbs_remaining_after, (LEAST(4.0, ceil((w.lbs_remaining_after / r.lbs_per_hour))) * r.lbs_per_hour)) AS lbs_processed,
            GREATEST((0)::numeric, (w.lbs_remaining_after - (LEAST(4.0, ceil((w.lbs_remaining_after / r.lbs_per_hour))) * r.lbs_per_hour))) AS lbs_remaining_after,
            (w.processing_order + 1) AS processing_order
           FROM (am_efficiency r
             JOIN am_scheduler w ON (((r.july_date = w.july_date) AND (r.rnk = (w.rnk + 1)))))
          WHERE (w.lbs_remaining_after > (0)::numeric)
        ), am_worked AS (
         SELECT DISTINCT am_scheduler.july_date,
            am_scheduler.employee_name
           FROM am_scheduler
          WHERE (am_scheduler.hours_scheduled > (0)::numeric)
        ), pm_efficiency AS (
         SELECT b.july_date,
            b.am_total_lbs,
            b.pm_total_lbs,
            b.employee_name,
            b.pay_per_hour,
            b.lbs_per_hour,
            b.price_per_lb,
            b.profit_per_lb,
            row_number() OVER (PARTITION BY b.july_date ORDER BY b.profit_per_lb DESC) AS rnk
           FROM (base_rates b
             LEFT JOIN am_worked a ON (((b.july_date = a.july_date) AND ((b.employee_name)::text = (a.employee_name)::text))))
          WHERE (a.employee_name IS NULL)
        ), pm_scheduler AS (
         SELECT pm_efficiency.july_date,
            pm_efficiency.rnk,
            pm_efficiency.employee_name,
            pm_efficiency.lbs_per_hour,
            pm_efficiency.pay_per_hour,
            pm_efficiency.price_per_lb,
            pm_efficiency.pm_total_lbs AS lbs_remaining_before,
                CASE
                    WHEN (pm_efficiency.pm_total_lbs > (0)::numeric) THEN LEAST(4.0, ceil((pm_efficiency.pm_total_lbs / pm_efficiency.lbs_per_hour)))
                    ELSE (0)::numeric
                END AS hours_scheduled,
            LEAST(pm_efficiency.pm_total_lbs, (LEAST(4.0, ceil((pm_efficiency.pm_total_lbs / pm_efficiency.lbs_per_hour))) * pm_efficiency.lbs_per_hour)) AS lbs_processed,
            GREATEST((0)::numeric, (pm_efficiency.pm_total_lbs - (LEAST(4.0, ceil((pm_efficiency.pm_total_lbs / pm_efficiency.lbs_per_hour))) * pm_efficiency.lbs_per_hour))) AS lbs_remaining_after,
            1 AS processing_order
           FROM pm_efficiency
          WHERE (pm_efficiency.rnk = 1)
        UNION ALL
         SELECT r.july_date,
            r.rnk,
            r.employee_name,
            r.lbs_per_hour,
            r.pay_per_hour,
            r.price_per_lb,
            w.lbs_remaining_after AS lbs_remaining_before,
                CASE
                    WHEN (w.lbs_remaining_after > (0)::numeric) THEN LEAST(4.0, ceil((w.lbs_remaining_after / r.lbs_per_hour)))
                    ELSE (0)::numeric
                END AS hours_scheduled,
            LEAST(w.lbs_remaining_after, (LEAST(4.0, ceil((w.lbs_remaining_after / r.lbs_per_hour))) * r.lbs_per_hour)) AS lbs_processed,
            GREATEST((0)::numeric, (w.lbs_remaining_after - (LEAST(4.0, ceil((w.lbs_remaining_after / r.lbs_per_hour))) * r.lbs_per_hour))) AS lbs_remaining_after,
            (w.processing_order + 1) AS processing_order
           FROM (pm_efficiency r
             JOIN pm_scheduler w ON (((r.july_date = w.july_date) AND (r.rnk = (w.rnk + 1)))))
          WHERE (w.lbs_remaining_after > (0)::numeric)
        )
 SELECT am_scheduler.july_date,
    'AM'::text AS shift,
    am_scheduler.processing_order AS employee_needed_sequence,
    am_scheduler.employee_name,
    round(am_scheduler.lbs_remaining_before, 2) AS fish_lbs_awaiting_processing,
    round(am_scheduler.hours_scheduled, 2) AS hours_worker_will_work,
    round(am_scheduler.lbs_processed, 2) AS fish_lbs_they_will_clear,
    round(((am_scheduler.lbs_processed * (am_scheduler.price_per_lb)::numeric) - (am_scheduler.hours_scheduled * (am_scheduler.pay_per_hour)::numeric)), 2) AS net_profit_generated
   FROM am_scheduler
  WHERE (am_scheduler.hours_scheduled > (0)::numeric)
UNION ALL
 SELECT pm_scheduler.july_date,
    'PM'::text AS shift,
    pm_scheduler.processing_order AS employee_needed_sequence,
    pm_scheduler.employee_name,
    round(pm_scheduler.lbs_remaining_before, 2) AS fish_lbs_awaiting_processing,
    round(pm_scheduler.hours_scheduled, 2) AS hours_worker_will_work,
    round(pm_scheduler.lbs_processed, 2) AS fish_lbs_they_will_clear,
    round(((pm_scheduler.lbs_processed * (pm_scheduler.price_per_lb)::numeric) - (pm_scheduler.hours_scheduled * (pm_scheduler.pay_per_hour)::numeric)), 2) AS net_profit_generated
   FROM pm_scheduler
  WHERE (pm_scheduler.hours_scheduled > (0)::numeric)
  ORDER BY 1, 2, 3;


ALTER VIEW public.total_profits OWNER TO postgres;

--
-- TOC entry 5013 (class 0 OID 16415)
-- Dependencies: 220
-- Data for Name: fish_processor_employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fish_processor_employees (employee_name, pay_per_hour, fish_lbs_processed_per_hour, price_per_lb) FROM stdin;
Isaac	25	55	3
Thomas	25	55	3
Andrew	25	55	3
Austin	20	40	3
Beth	20	40	3
Andria	20	40	3
Dillon	30	70	3
\.


--
-- TOC entry 5012 (class 0 OID 16400)
-- Dependencies: 219
-- Data for Name: la_jolla_tide_fishing_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.la_jolla_tide_fishing_status (july_date, high_tide_chart_am, high_tide_chart_pm, low_tide_chart_am, low_tide_chart_pm, moon_phase, kayak_fishing_day_status, pier_fishing_morning_status, pier_fishing_evening_status, est_am_fish_count_lbs, est_pm_fish_count_lbs) FROM stdin;
2026-07-01	11:51:00	10:21:00	05:14:00	04:05:00	Full	Bad Kayak Fishing Day	Bad Pier Morning Fishing Day	Terrible Evening Pier Fishing Day	300	10
2026-07-02	00:00:00	12:24:00	05:45:00	04:44:00	Full	Bad Kayak Fishing Day	Bad Pier Morning Fishing Day	Best Evening Pier Fishing Day	300	400
2026-07-03	00:00:00	12:58:00	06:17:00	05:29:00	Full	Bad Kayak Fishing Day	Bad Pier Morning Fishing Day	Bad Evening Pier Fishing Day	300	150
2026-07-04	00:00:00	01:34:00	06:48:00	06:25:00	Three Quarter	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-05	12:11:00	02:12:00	07:20:00	07:36:00	Three Quarter	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-06	01:02:00	02:54:00	07:53:00	09:06:00	Three Quarter	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-07	02:15:00	03:39:00	08:31:00	10:44:00	Three Quarter	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-08	04:06:00	04:30:00	09:17:00	00:00:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Best Evening Pier Fishing Day	500	400
2026-07-09	06:09:00	05:23:00	12:05:00	00:00:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Bad Evening Pier Fishing Day	500	150
2026-07-10	07:39:00	06:17:00	01:06:00	00:00:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-11	08:38:00	07:10:00	01:58:00	12:35:00	One Quarter	Best Kayak Fishing Day	Best Pier Fishing Day	Terrible Evening Pier Fishing Day	800	10
2026-07-12	09:24:00	08:01:00	02:45:00	01:35:00	One Quarter	Best Kayak Fishing Day	Best Pier Fishing Day	Terrible Evening Pier Fishing Day	800	10
2026-07-14	10:45:00	09:40:00	04:12:00	03:24:00	New	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-15	11:24:00	10:27:00	04:54:00	04:16:00	New	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-26	09:38:00	07:56:00	02:51:00	01:40:00	Three Quarter	Bad Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	400	10
2026-07-27	09:58:00	08:31:00	03:21:00	02:16:00	Three Quarter	Bad Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	400	10
2026-07-28	10:19:00	09:04:00	03:49:00	02:50:00	Three Quarter	Bad Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	400	10
2026-07-29	10:42:00	09:36:00	04:16:00	03:24:00	Full	Terrible Kayak Fishing Day	Terrible Pier Morning Fishing Day	Terrible Evening Pier Fishing Day	20	10
2026-07-30	11:06:00	10:08:00	04:43:00	04:00:00	Full	Terrible Kayak Fishing Day	Terrible Pier Morning Fishing Day	Terrible Evening Pier Fishing Day	20	10
2026-07-16	00:00:00	12:05:00	05:34:00	05:10:00	New	Normal Kayak Fishing Day	Normal Pier Fishing Day	Bad Evening Pier Fishing Day	500	150
2026-07-17	00:00:00	12:46:00	06:13:00	06:07:00	One Quarter	Best Kayak Fishing Day	Best Pier Fishing Day	Terrible Evening Pier Fishing Day	800	10
2026-07-18	12:02:00	01:29:00	06:51:00	07:12:00	One Quarter	Best Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	650	10
2026-07-19	12:54:00	02:15:00	07:27:00	08:29:00	One Quarter	Best Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	650	10
2026-07-20	01:57:00	03:04:00	08:03:00	10:03:00	One Quarter	Best Kayak Fishing Day	Best Pier Fishing Day	Terrible Evening Pier Fishing Day	800	10
2026-07-21	03:30:00	03:57:00	08:41:00	11:38:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Best Evening Pier Fishing Day	500	400
2026-07-22	05:51:00	04:53:00	09:29:00	00:00:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Best Evening Pier Fishing Day	500	400
2026-07-23	07:51:00	05:47:00	12:50:00	00:00:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Bad Evening Pier Fishing Day	500	150
2026-07-24	08:46:00	06:35:00	01:40:00	12:00:00	Half	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-25	09:15:00	07:18:00	02:18:00	12:57:00	Three Quarter	Normal Kayak Fishing Day	Normal Pier Fishing Day	Terrible Evening Pier Fishing Day	500	10
2026-07-31	11:32:00	10:41:00	05:09:00	04:38:00	Full	Bad Kayak Fishing Day	Bad Pier Morning Fishing Day	Terrible Evening Pier Fishing Day	300	10
2026-07-13	10:05:00	08:51:00	03:29:00	02:31:00	One Quarter	Best Kayak Fishing Day	Best Pier Fishing Day	Terrible Evening Pier Fishing Day	800	10
\.


-- Completed on 2026-07-28 15:49:21

--
-- PostgreSQL database dump complete
--

\unrestrict yCz0D168QkglG12ZwBvrU7IvrbDSEa51GGFhpMmVrB5eay0xQciJlQ1YeWdMzYk

