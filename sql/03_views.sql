-- View: meteurosystem.hr_hierarchia

-- DROP VIEW meteurosystem.hr_hierarchia;

CREATE OR REPLACE VIEW meteurosystem.hr_hierarchia
 AS
 WITH drabina AS (
         SELECT h.id,
            h.employee_id,
            concat(p1.p_nazwisko, ' ', p1.p_imie) AS pracownik,
            h.supervisor_id,
            concat(p2.p_nazwisko, ' ', p2.p_imie) AS przelozony
           FROM meteurosystem.hr_employee_hierarchy h
             JOIN tb_pracownicy p1 ON p1.p_idpracownika = h.employee_id
             JOIN tb_pracownicy p2 ON p2.p_idpracownika = h.supervisor_id
        ), pracownicy AS (
         SELECT prac.p_idpracownika,
            prac.p_nazwisko,
            prac.p_imie,
            dzial.dz_nazwa,
            stan.st_nazwa
           FROM tb_pracownicy prac
             LEFT JOIN ts_stanowisko stan USING (st_idstanowiska)
             LEFT JOIN ts_dzialy dzial USING (dz_iddzialu)
          WHERE prac.p_czyaktywny = true AND (prac.p_idpracownika <> ALL (ARRAY[2, 8, 33, 36, 63, 136, 191, 304, 305, 306, 307, 308, 309, 310, 311, 336, 337, 341, 342, 344, 345, 360, 371, 401, 430, 433, 505, 578, 679]))
        )
 SELECT p.p_idpracownika,
    p.p_nazwisko,
    p.p_imie,
    p.dz_nazwa,
    p.st_nazwa,
    d.id,
    d.employee_id,
    d.pracownik,
    d.supervisor_id,
    d.przelozony,
    i.umowa_id,
    t.typ_umowy
   FROM pracownicy p
     LEFT JOIN drabina d ON p.p_idpracownika = d.employee_id
     LEFT JOIN meteurosystem.hr_info i ON i.employee_id = p.p_idpracownika
     LEFT JOIN meteurosystem.hr_contract_type t ON t.id = i.umowa_id;

ALTER TABLE meteurosystem.hr_hierarchia
    OWNER TO testdbuser;


--------------------------------------------------------------------
--------------------------------------------------------------------
-- View: meteurosystem.hr_pracownicy

-- DROP VIEW meteurosystem.hr_pracownicy;

CREATE OR REPLACE VIEW meteurosystem.hr_pracownicy
 AS
 SELECT i.employee_id,
    p.p_nazwisko,
    p.p_imie,
    concat(p.p_nazwisko, ' ', p.p_imie) AS concat,
    i.employment_date,
    i.contract_end_date,
    i.leave_entitlement,
    p.p_czyaktywny,
    u.typ_umowy,
    d.dz_nazwa
   FROM meteurosystem.hr_info i
     JOIN tb_pracownicy p ON i.employee_id = p.p_idpracownika
     JOIN meteurosystem.hr_contract_type u ON u.id = i.umowa_id
     JOIN ts_dzialy d USING (dz_iddzialu);

ALTER TABLE meteurosystem.hr_pracownicy
    OWNER TO testdbuser;

--------------------------------------------------------------------
--------------------------------------------------------------------

-- View: meteurosystem.mdb_prac_rbh_mpk

-- DROP MATERIALIZED VIEW IF EXISTS meteurosystem.mdb_prac_rbh_mpk;

CREATE MATERIALIZED VIEW IF NOT EXISTS meteurosystem.mdb_prac_rbh_mpk
TABLESPACE pg_default
AS
 WITH aktywni_pracownicy AS (
         SELECT p_1.employee_id,
            p_1.p_imie,
            p_1.p_nazwisko,
            p_1.dz_nazwa,
            p_1.employment_date,
            p_1.contract_end_date
           FROM meteurosystem.hr_pracownicy p_1
        ), kalendarz_aktywni AS (
         SELECT generate_series(GREATEST('2024-10-01'::date, ap.employment_date)::timestamp with time zone, LEAST((CURRENT_DATE + '1 year'::interval)::date, COALESCE(ap.contract_end_date, (CURRENT_DATE + '1 year'::interval)::date))::timestamp with time zone, '1 day'::interval)::date AS dzien,
            ap.employee_id,
            (ap.p_imie || ' '::text) || ap.p_nazwisko AS pracownik,
            ap.dz_nazwa AS mpk_domyslny,
            EXTRACT(dow FROM generate_series(GREATEST('2024-10-01'::date, ap.employment_date)::timestamp with time zone, LEAST((CURRENT_DATE + '1 year'::interval)::date, COALESCE(ap.contract_end_date, (CURRENT_DATE + '1 year'::interval)::date))::timestamp with time zone, '1 day'::interval)::date) AS dzien_tyg
           FROM aktywni_pracownicy ap
        ), logi_aktywni AS (
         SELECT k.dzien,
            k.employee_id,
            k.pracownik,
            COALESCE(r.mpk, k.mpk_domyslny) AS mpk,
            COALESCE(r.h_night, 0) + COALESCE(r.overtime, 0) + COALESCE(r.regular_time, 0) AS minuty_r,
            u.skrot IS NOT NULL AS na_urlopie,
            k.dzien_tyg,
            r.day_type,
            COALESCE(r.h_night, 0) + COALESCE(r.overtime, 0) + COALESCE(r.regular_time, 0) AS sum_czas,
                CASE
                    WHEN r.id IS NOT NULL THEN 1
                    ELSE 0
                END AS ma_rcp
           FROM kalendarz_aktywni k
             LEFT JOIN meteurosystem.hr_saved_rcp_report r ON r.id = k.employee_id AND r.data = k.dzien
             LEFT JOIN meteurosystem.hr_gen_leave_entry_all() u(employee_id, data_wpisu, skrot) ON u.employee_id = k.employee_id AND u.data_wpisu = k.dzien
        ), byli_pracownicy AS (
         SELECT DISTINCT r.id
           FROM meteurosystem.hr_saved_rcp_report r
          WHERE NOT (EXISTS ( SELECT 1
                   FROM meteurosystem.hr_pracownicy p_1
                  WHERE p_1.employee_id = r.id))
        ), logi_byli AS (
         SELECT r.data AS dzien,
            r.id AS employee_id,
            r.pracownik,
            r.mpk,
            COALESCE(r.h_night, 0) + COALESCE(r.overtime, 0) + COALESCE(r.regular_time, 0) AS minuty_r,
            false AS na_urlopie,
            EXTRACT(dow FROM r.data) AS dzien_tyg,
            r.day_type,
            COALESCE(r.h_night, 0) + COALESCE(r.overtime, 0) + COALESCE(r.regular_time, 0) AS sum_czas,
            1 AS ma_rcp
           FROM meteurosystem.hr_saved_rcp_report r
             JOIN byli_pracownicy b ON r.id = b.id
        ), polaczone_status AS (
         SELECT logi_aktywni.dzien,
            logi_aktywni.employee_id,
            logi_aktywni.pracownik,
            logi_aktywni.mpk,
            logi_aktywni.minuty_r,
            logi_aktywni.dzien_tyg,
            logi_aktywni.day_type,
            logi_aktywni.sum_czas,
            logi_aktywni.ma_rcp,
            logi_aktywni.na_urlopie,
                CASE
                    WHEN logi_aktywni.na_urlopie THEN 'urlop'::text
                    WHEN logi_aktywni.day_type = 's'::text AND logi_aktywni.sum_czas = 0 THEN 'święto'::text
                    WHEN logi_aktywni.day_type = 'w'::text AND logi_aktywni.sum_czas = 0 THEN 'weekend'::text
                    WHEN logi_aktywni.dzien_tyg = ANY (ARRAY[0::numeric, 6::numeric]) THEN 'weekend'::text
                    WHEN logi_aktywni.ma_rcp = 1 AND logi_aktywni.sum_czas = 0 THEN 'urlop'::text
                    WHEN logi_aktywni.minuty_r > 0 THEN 'zalogowany'::text
                    ELSE 'automatyczne 480'::text
                END AS status
           FROM logi_aktywni
        UNION ALL
         SELECT logi_byli.dzien,
            logi_byli.employee_id,
            logi_byli.pracownik,
            logi_byli.mpk,
            logi_byli.minuty_r,
            logi_byli.dzien_tyg,
            logi_byli.day_type,
            logi_byli.sum_czas,
            logi_byli.ma_rcp,
            logi_byli.na_urlopie,
                CASE
                    WHEN logi_byli.day_type = 's'::text AND logi_byli.sum_czas = 0 THEN 'święto'::text
                    WHEN logi_byli.day_type = 'w'::text AND logi_byli.sum_czas = 0 THEN 'weekend'::text
                    WHEN logi_byli.dzien_tyg = ANY (ARRAY[0::numeric, 6::numeric]) THEN 'weekend'::text
                    WHEN logi_byli.ma_rcp = 1 AND logi_byli.sum_czas = 0 THEN 'urlop'::text
                    WHEN logi_byli.minuty_r > 0 THEN 'zalogowany'::text
                    ELSE 'automatyczne 480'::text
                END AS status
           FROM logi_byli
        ), polaczone_minuty AS (
         SELECT polaczone_status.dzien,
            polaczone_status.employee_id,
            polaczone_status.pracownik,
            polaczone_status.mpk,
                CASE
                    WHEN polaczone_status.status = 'automatyczne 480'::text THEN 480
                    WHEN polaczone_status.status = ANY (ARRAY['urlop'::text, 'weekend'::text, 'święto'::text]) THEN 0
                    ELSE polaczone_status.minuty_r
                END AS minuty,
            polaczone_status.status
           FROM polaczone_status
        )
 SELECT p.dzien,
    p.employee_id,
    p.pracownik,
    p.mpk,
        CASE
            WHEN p.mpk = ANY (ARRAY['Ślusarnia Ogólne'::text, 'Ślusarnia'::text, 'Costa'::text, 'Ukosowanie'::text]) THEN 'Ślusarnia'::text
            ELSE p.mpk
        END AS mpk_agr,
    p.minuty,
    p.minuty / 60 AS godziny,
    p.minuty / 480 AS dniowki,
    p.status
   FROM polaczone_minuty p
  ORDER BY p.pracownik, p.dzien
WITH DATA;

ALTER TABLE IF EXISTS meteurosystem.mdb_prac_rbh_mpk
    OWNER TO testdbuser;


-----------------------------------------------------------------
-----------------------------------------------------------------

-- View: meteurosystem.mdb_dostepne_godziny_msc_det

-- DROP MATERIALIZED VIEW IF EXISTS meteurosystem.mdb_dostepne_godziny_msc_det;

CREATE MATERIALIZED VIEW IF NOT EXISTS meteurosystem.mdb_dostepne_godziny_msc_det
TABLESPACE pg_default
AS
 WITH godziny_do_konca_miesiaca AS (
         SELECT (to_char(mdb_prac_rbh_mpk.dzien::timestamp with time zone, 'YYYY'::text) || '-'::text) || to_char(mdb_prac_rbh_mpk.dzien::timestamp with time zone, 'MM'::text) AS msc,
                CASE
                    WHEN mdb_prac_rbh_mpk.dzien < now()::date THEN 1
                    ELSE 0
                END AS past,
            mdb_prac_rbh_mpk.dzien,
            mdb_prac_rbh_mpk.employee_id,
            mdb_prac_rbh_mpk.pracownik,
            mdb_prac_rbh_mpk.mpk,
            mdb_prac_rbh_mpk.mpk_agr,
            mdb_prac_rbh_mpk.minuty,
            mdb_prac_rbh_mpk.godziny,
                CASE
                    WHEN mdb_prac_rbh_mpk.godziny > 0 THEN mdb_prac_rbh_mpk.godziny::numeric - 0.5
                    ELSE mdb_prac_rbh_mpk.godziny::numeric
                END AS godziny_to_sum,
            mdb_prac_rbh_mpk.dniowki,
            mdb_prac_rbh_mpk.status
           FROM meteurosystem.mdb_prac_rbh_mpk
          WHERE mdb_prac_rbh_mpk.mpk_agr = ANY (ARRAY['Ślusarnia'::text, 'Prasy'::text, 'Montaż'::text, 'Spawalnia'::text, 'Skrawanie'::text])
        )
 SELECT godziny_do_konca_miesiaca.msc,
    godziny_do_konca_miesiaca.past,
    godziny_do_konca_miesiaca.dzien,
    godziny_do_konca_miesiaca.employee_id,
    godziny_do_konca_miesiaca.pracownik,
    godziny_do_konca_miesiaca.mpk,
    godziny_do_konca_miesiaca.mpk_agr,
    godziny_do_konca_miesiaca.minuty,
    godziny_do_konca_miesiaca.godziny,
    godziny_do_konca_miesiaca.dniowki,
    godziny_do_konca_miesiaca.status,
        CASE
            WHEN godziny_do_konca_miesiaca.past = 1 THEN godziny_do_konca_miesiaca.godziny_to_sum
            ELSE NULL::integer::numeric
        END AS godziny_past,
        CASE
            WHEN godziny_do_konca_miesiaca.past = 0 THEN godziny_do_konca_miesiaca.godziny_to_sum
            ELSE NULL::integer::numeric
        END AS godziny_nowfuture
   FROM godziny_do_konca_miesiaca
  WHERE date_trunc('month'::text, ((godziny_do_konca_miesiaca.msc || '-01'::text)::date)::timestamp with time zone) = ANY (ARRAY[date_trunc('month'::text, CURRENT_DATE::timestamp with time zone), date_trunc('month'::text, CURRENT_DATE + '1 mon'::interval)::timestamp with time zone, date_trunc('month'::text, CURRENT_DATE + '2 mons'::interval)::timestamp with time zone])
WITH DATA;

ALTER TABLE IF EXISTS meteurosystem.mdb_dostepne_godziny_msc_det
    OWNER TO testdbuser;

-------------------------------------------------------------------------
-------------------------------------------------------------------------
