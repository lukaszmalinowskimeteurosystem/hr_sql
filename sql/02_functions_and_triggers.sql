--hr_info: ok
--hr_leave_balances: ok
--hr_leave_requests: 


-- View: meteurosystem.hr_raport_urlopy

-- DROP VIEW meteurosystem.hr_raport_urlopy;

CREATE OR REPLACE VIEW meteurosystem.hr_raport_urlopy
 AS
 WITH urlop_bezplatny AS (
         SELECT a.employee_id,
            count(a.leave_type_id) AS "Urlop bezpłatny"
           FROM ( SELECT r.employee_id,
                    generate_series(r.start_date::timestamp with time zone, r.end_date::timestamp with time zone, '1 day'::interval)::date AS data_wpisu,
                    r.leave_type_id
                   FROM meteurosystem.hr_leave_requests r
                     JOIN meteurosystem.hr_types_hol_req t ON t.id = r.leave_type_id
                  WHERE r.status = 2 AND r.leave_type_id = 12) a
          WHERE EXTRACT(year FROM a.data_wpisu) = EXTRACT(year FROM CURRENT_DATE)
          GROUP BY a.employee_id
        ), zwolnienia AS (
         SELECT a.employee_id,
            count(a.leave_type_id) AS "Zwolnienie lekarskie"
           FROM ( SELECT r.employee_id,
                    generate_series(r.start_date::timestamp with time zone, r.end_date::timestamp with time zone, '1 day'::interval)::date AS data_wpisu,
                    r.leave_type_id
                   FROM meteurosystem.hr_leave_requests r
                     JOIN meteurosystem.hr_types_hol_req t ON t.id = r.leave_type_id
                  WHERE r.status = 2 AND r.leave_type_id = 3) a
          WHERE EXTRACT(year FROM a.data_wpisu) = EXTRACT(year FROM CURRENT_DATE)
          GROUP BY a.employee_id
        ), inne AS (
         SELECT a.employee_id,
            count(a.leave_type_id) AS "Inne"
           FROM ( SELECT r.employee_id,
                    generate_series(r.start_date::timestamp with time zone, r.end_date::timestamp with time zone, '1 day'::interval)::date AS data_wpisu,
                    r.leave_type_id
                   FROM meteurosystem.hr_leave_requests r
                     JOIN meteurosystem.hr_types_hol_req t ON t.id = r.leave_type_id
                  WHERE r.status = 2 AND (r.leave_type_id <> ALL (ARRAY[3, 12, 7, 2, 10, 8]))) a
          WHERE EXTRACT(year FROM a.data_wpisu) = EXTRACT(year FROM CURRENT_DATE)
          GROUP BY a.employee_id
        )
 SELECT p.p_idpracownika AS "ID",
    p.p_nazwisko AS "Nazwisko",
    p.p_imie AS "Imię",
    concat(p.p_nazwisko, ' ', p.p_imie) AS "Nazwisko i Imię",
    l1.current_year AS "Opieka na dziecko",
    l2.current_year AS "Uw aktualny rok",
    l2.overdue AS "Uw zaległy",
    l2.remaining_holiday + l2.used_days AS "Uw aktualny rok łącznie do wykorzystania",
    l2.used_days AS "Uw wykorzystany",
    l2.remaining_holiday AS "Uw pozostały do wykorzystania",
    ub."Urlop bezpłatny",
    zw."Zwolnienie lekarskie",
    l3.used_days AS "HO",
    l4.used_days AS "Urlop na żadanie",
    inne."Inne"
   FROM meteurosystem.hr_info i
     JOIN tb_pracownicy p ON i.employee_id = p.p_idpracownika
     LEFT JOIN meteurosystem.hr_leave_balances_new l1 ON l1.employee_id = i.employee_id AND l1.leave_type_id = 7
     LEFT JOIN meteurosystem.hr_leave_balances_new l2 ON l2.employee_id = i.employee_id AND l2.leave_type_id = 2
     LEFT JOIN urlop_bezplatny ub ON ub.employee_id = i.employee_id
     LEFT JOIN zwolnienia zw ON zw.employee_id = i.employee_id
     LEFT JOIN inne ON inne.employee_id = i.employee_id
     LEFT JOIN meteurosystem.hr_leave_balances_new l3 ON l3.employee_id = i.employee_id AND l3.leave_type_id = 10
     LEFT JOIN meteurosystem.hr_leave_balances_new l4 ON l4.employee_id = i.employee_id AND l4.leave_type_id = 8
  WHERE p.p_idpracownika <> ALL (ARRAY[2, 8, 33, 36, 63, 136, 191, 304, 305, 306, 307, 308, 309, 310, 311, 336, 337, 341, 342, 344, 345, 360, 371, 401, 430, 433, 505, 578, 679]);

ALTER TABLE meteurosystem.hr_raport_urlopy
    OWNER TO testdbuser;



-- Funkcja: meteurosystem.fn_update_hr_leave_balances()
-- (tu tylko log; w prawdziwej wersji wykonasz obliczenia/przeliczenia)

-- FUNCTION: meteurosystem.fn_update_hr_leave_balances()
 -- DROP FUNCTION IF EXISTS meteurosystem.fn_update_hr_leave_balances();

CREATE OR REPLACE FUNCTION meteurosystem.fn_update_hr_leave_balances()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    current_year             int := EXTRACT(YEAR FROM CURRENT_DATE)::int;
    month_start              int;
    month_end                int;
    prorated_entitlement     int := 0;
    next_year_entitlement    int := 0;

    existing_used_from_current int := 0;
    existing_overdue           int := 0;
    existing_used_days         int := 0;
BEGIN
    IF NEW.employee_id IS NOT NULL THEN

        ----------------------------------------------------------------
        -- 1. Obliczenie wymiaru urlopu na BIEŻĄCY ROK
        ----------------------------------------------------------------
        -- Start liczymy od miesiąca zatrudnienia (jeśli w tym roku),
        -- albo od stycznia (jeśli zatrudniony wcześniej).
        IF EXTRACT(YEAR FROM NEW.employment_date)::int = current_year THEN
            month_start := EXTRACT(MONTH FROM NEW.employment_date)::int;
        ELSE
            month_start := 1;
        END IF;

        -- Koniec liczymy:
        --  - jeśli kontrakt kończy się w tym roku → miesiąc końca
        --  - w pozostałych przypadkach → grudzień
        IF NEW.contract_end_date IS NOT NULL
           AND EXTRACT(YEAR FROM NEW.contract_end_date)::int = current_year
        THEN
            month_end := EXTRACT(MONTH FROM NEW.contract_end_date)::int;
        ELSE
            month_end := 12;
        END IF;

        prorated_entitlement :=
            CEIL(((month_end - month_start + 1)::numeric / 12) * NEW.leave_entitlement);

        ----------------------------------------------------------------
        -- 2. Obliczenie wymiaru urlopu na NASTĘPNY ROK
        ----------------------------------------------------------------
        IF NEW.contract_end_date IS NULL THEN
            -- Umowa bezterminowa → pełny urlop
            next_year_entitlement := NEW.leave_entitlement;

        ELSIF EXTRACT(YEAR FROM NEW.contract_end_date)::int = current_year THEN
            -- Umowa kończy się w tym roku → brak urlopu na następny rok
            next_year_entitlement := 0;

        ELSIF EXTRACT(YEAR FROM NEW.contract_end_date)::int = current_year + 1 THEN
            -- Umowa kończy się w następnym roku → proporcja do miesiąca końca
            month_end := EXTRACT(MONTH FROM NEW.contract_end_date)::int;
            next_year_entitlement :=
                CEIL((month_end::numeric / 12) * NEW.leave_entitlement);

        ELSE
            -- Umowa kończy się w latach późniejszych → pełny urlop
            next_year_entitlement := NEW.leave_entitlement;
        END IF;

        ----------------------------------------------------------------
        -- 3. Pobranie istniejących danych (żeby nie nadpisywać użytych dni)
        ----------------------------------------------------------------
        SELECT
            COALESCE(used_from_current_year, 0),
            COALESCE(overdue, 0),
            COALESCE(used_days, 0)
        INTO
            existing_used_from_current,
            existing_overdue,
            existing_used_days
        FROM meteurosystem.hr_leave_balances_new
        WHERE employee_id   = NEW.employee_id
          AND leave_type_id = 2;

        ----------------------------------------------------------------
        -- 4. Insert / Update
        ----------------------------------------------------------------
        IF EXISTS (
            SELECT 1 FROM meteurosystem.hr_leave_balances_new
            WHERE employee_id = NEW.employee_id
              AND leave_type_id = 2
        ) THEN
            UPDATE meteurosystem.hr_leave_balances_new
            SET current_year      = prorated_entitlement,
                next_year         = next_year_entitlement,
                remaining_holiday = existing_overdue
                                     + prorated_entitlement
                                     - existing_used_from_current,
                used_days         = existing_used_days,
                used_from_current_year = existing_used_from_current
            WHERE employee_id   = NEW.employee_id
              AND leave_type_id = 2;
        ELSE
            INSERT INTO meteurosystem.hr_leave_balances_new
                (overdue, current_year, next_year,
                 used_days, used_from_current_year,
                 remaining_holiday,
                 employee_id, leave_type_id)
            VALUES
                (0,
                 prorated_entitlement,
                 next_year_entitlement,
                 0,
                 0,
                 prorated_entitlement,
                 NEW.employee_id,
                 2);
        END IF;

        ----------------------------------------------------------------
        -- 5. Wyzerowanie next_year dla innych typów (8,10,11),
        --    jeśli umowa kończy się w bieżącym roku
        ----------------------------------------------------------------
        IF NEW.contract_end_date IS NOT NULL
           AND EXTRACT(YEAR FROM NEW.contract_end_date)::int = current_year
        THEN
            UPDATE meteurosystem.hr_leave_balances_new
            SET next_year = 0
            WHERE employee_id = NEW.employee_id
              AND leave_type_id IN (8, 10, 11);
        END IF;

    END IF;

    RETURN NEW;
END;
$$;





-- # TODO: do usunięcia
-- Funkcja: meteurosystem.fn_on_leave_entitlement_change()

-- FUNCTION: meteurosystem.fn_on_leave_entitlement_change()
 -- DROP FUNCTION IF EXISTS meteurosystem.fn_on_leave_entitlement_change();

-- CREATE OR REPLACE FUNCTION meteurosystem.fn_on_leave_entitlement_change() RETURNS trigger LANGUAGE 'plpgsql' COST 100 VOLATILE NOT LEAKPROOF AS $BODY$
-- DECLARE
-- --sprawdzamy aktualny rok
-- current_year int := EXTRACT(YEAR FROM CURRENT_DATE)::int;
-- month_end_to_calculate int :=12;
-- month_start_to_calculate int :=1;
-- full_months int :=12;
-- new_leave_in_current_year int :=0;
-- new_leave_in_next_year int :=0;
-- new_remaining_holiday int:=0;
-- existing_used_from_current_year int :=0;
-- existing_overdue int :=0;
-- BEGIN
-- -- Sprawdzamy czy leave_entitlement uległ zmianie lub to nowy wpis
-- IF TG_OP = 'INSERT' OR NEW.leave_entitlement IS DISTINCT FROM OLD.leave_entitlement THEN
-- -- Sprawdzenie czy contract_end_date jest NULL (bezterminowa) lub kończy się po bieżącym roku
-- IF NEW.contract_end_date IS NULL OR EXTRACT(YEAR FROM NEW.contract_end_date)::int > current_year THEN
-- month_end_to_calculate:=12;
-- else
-- month_end_to_calculate=EXTRACT(MONTH from NEW.contract_end_date);
-- END IF;

-- --Sprawdzenie month_start_to_calculate
-- --jezeli
-- IF EXTRACT(YEAR from NEW.employment_date) < current_year THEN
-- month_start_to_calculate:=1;
-- ELSIF EXTRACT(YEAR from NEW.employment_date) = current_year THEN
-- month_start_to_calculate := Extract(month from NEW.employment_date);
-- END IF;

-- full_months := month_end_to_calculate - month_start_to_calculate + 1;

-- --Obliczenie nowej wartości kolumny curent_year dla leave_type_id = 2
-- new_leave_in_current_year:=CEIL(full_months::float/12*NEW.leave_entitlement);

-- -- Obliczenie nowej wartości kolumny next_year dla leave_type_id = 2
-- IF NEW.contract_end_date IS NULL 
--    OR EXTRACT(YEAR FROM NEW.contract_end_date)::int > current_year+1 THEN
--     new_leave_in_next_year := NEW.leave_entitlement;
-- ELSIF EXTRACT(YEAR FROM NEW.contract_end_date)::int = current_year+1 THEN
--     month_end_to_calculate := EXTRACT(MONTH FROM NEW.contract_end_date);
--     new_leave_in_next_year := CEIL(month_end_to_calculate::float / 12 * NEW.leave_entitlement);
-- ELSIF EXTRACT(YEAR from NEW.employment_date) = current_year+1 THEN
--     new_leave_in_next_year := CEIL(EXTRACT(MONTH FROM NEW.employment_date)::float / 12 * NEW.leave_entitlement);
-- END IF;

-- --Obliczenie nowego remaining_holiday
-- --pobranie danych z tabeli urlopów
-- SELECT
-- COALESCE(used_from_current_year, 0),
-- COALESCE(overdue, 0)
-- INTO
-- existing_used_from_current_year,
-- existing_overdue
-- FROM meteurosystem.hr_leave_balances_new
-- WHERE employee_id   = NEW.employee_id
-- AND leave_type_id = 2;

-- new_remaining_holiday :=existing_overdue + new_leave_in_current_year - existing_used_from_current_year;

-- --wywołanie aktualizacji wpisów w tabeli meteurosystem.hr_leave_balances_new

-- UPDATE meteurosystem.hr_leave_balances_new
-- SET
-- remaining_holiday = new_remaining_holiday,
-- current_year = new_leave_in_current_year,
-- next_year = new_leave_in_next_year
-- WHERE employee_id = NEW.employee_id AND leave_type_id = 2;

-- END IF;
-- RETURN NEW;
-- END;
-- $BODY$;


-- ALTER FUNCTION meteurosystem.fn_on_leave_entitlement_change() OWNER TO testdbuser;



-- Porządkowe usunięcie triggerów (idempotentne powtarzalne uruchomienie)

DROP TRIGGER IF EXISTS trg_hr_info_after_insert_update_constrac_end_date ON meteurosystem.hr_info;

-- # TODO: do usunięcia 
--DROP TRIGGER IF EXISTS trg_hr_info_after_insert_update_leave_entitlement ON meteurosystem.hr_info;


DROP TRIGGER IF EXISTS trg_log_hr_info_changes ON meteurosystem.hr_info;

-- Uwaga: Dla TRIGGERÓW AFTER o tym samym czasie wykonania kolejność = leksykograficzna po nazwie TG_NAME
-- Jeśli chcesz wymusić kolejność, nazwij je np. "trg_10_...", "trg_20_..."
 -- Trigger: kontrakt (INSERT + UPDATE OF contract_end_date)

CREATE TRIGGER trg_hr_info_after_insert_update_constrac_end_date AFTER
INSERT
OR
UPDATE OF contract_end_date ON meteurosystem.hr_info
FOR EACH ROW EXECUTE FUNCTION meteurosystem.fn_update_hr_leave_balances();

-- Trigger: leave_entitlement (INSERT + UPDATE OF leave_entitlement)

-- # TODO: do usunięcia
-- CREATE TRIGGER trg_hr_info_after_insert_update_leave_entitlement AFTER
-- INSERT
-- OR
-- UPDATE OF leave_entitlement ON meteurosystem.hr_info
-- FOR EACH ROW EXECUTE FUNCTION meteurosystem.fn_on_leave_entitlement_change();

-- Trigger: ogólny log (po każdym INSERT/UPDATE)

CREATE TRIGGER trg_log_hr_info_changes AFTER
INSERT
OR
UPDATE ON meteurosystem.hr_info
FOR EACH ROW EXECUTE FUNCTION meteurosystem.fn_log_generic_changes();
---------------------
------------------------------


-- FUNCTION: meteurosystem.get_admin_leave_report()

-- DROP FUNCTION IF EXISTS meteurosystem.get_admin_leave_report();

CREATE OR REPLACE FUNCTION meteurosystem.get_admin_leave_report(
	)
    RETURNS TABLE("Nazwisko i Imię" text, "Uw zaległy" numeric, "Uw aktualny rok" numeric, "UŻ" numeric, "HO" numeric) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
select
CONCAT(p.p_nazwisko, ' ', p.p_imie) as "Nazwisko i Imię",
u.overdue as "Uw zaległy",
u.remaining_holiday-u.overdue as "Uw aktualny rok",
l.remaining_holiday as "UŻ",
h.remaining_holiday as "HO"
from meteurosystem.hr_info i
left join tb_pracownicy p on i.employee_id=p.p_idpracownika
left join meteurosystem.hr_leave_balances_new u on u.employee_id =i.employee_id and u.leave_type_id=2
left join meteurosystem.hr_leave_balances_new l on l.employee_id = i.employee_id and l.leave_type_id = 8
left join meteurosystem.hr_leave_balances_new h on h.employee_id =i.employee_id and h.leave_type_id=10
where p.p_czyaktywny='true'
$BODY$;

ALTER FUNCTION meteurosystem.get_admin_leave_report()
    OWNER TO testdbuser;


-- # TODO: NEW (UPDATE!!!)
--------------------------------------------------
--------------------------------------------------

-- FUNCTION: meteurosystem.hr_get_subordinate_list(integer)

-- DROP FUNCTION IF EXISTS meteurosystem.hr_get_subordinate_list(integer);

CREATE OR REPLACE FUNCTION meteurosystem.hr_get_subordinate_list(
    in_sup_id integer
)
RETURNS TABLE (
    supervisor_name text,
    supervisor_id   integer,
    worker          text,
    worker_id       integer
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE subordinates AS (
      -- start: bezpośredni podwładni szefa
      SELECT
          h.employee_id,
          h.supervisor_id,
          1 AS level,
          h.supervisor_id AS root,
          h.employee_id::text AS path
      FROM meteurosystem.hr_employee_hierarchy h
      WHERE h.supervisor_id = in_sup_id

      UNION ALL

      -- schodzimy w dół struktury
      SELECT
          h.employee_id,
          h.supervisor_id,
          r.level + 1,
          r.root,
          r.path || ' -> ' || h.employee_id::text
      FROM meteurosystem.hr_employee_hierarchy h
      JOIN subordinates r
        ON h.supervisor_id = r.employee_id
  )
  SELECT
      concat_ws(' ', sup.p_nazwisko, sup.p_imie)                         AS supervisor_name,
      subordinates.supervisor_id                                          AS supervisor_id,
      concat_ws(' ', wrk.p_nazwisko, wrk.p_imie)                          AS worker,
      subordinates.employee_id                                            AS worker_id
  FROM subordinates
  JOIN public.tb_pracownicy sup ON sup.p_idpracownika = subordinates.root
  JOIN public.tb_pracownicy wrk ON wrk.p_idpracownika = subordinates.employee_id
  WHERE wrk.p_czyaktywny = true
  ORDER BY subordinates.level, subordinates.employee_id;
END;
$$;

ALTER FUNCTION meteurosystem.hr_get_subordinate_list(integer)
  OWNER TO testdbuser;

--------------------------------------------------
--------------------------------------------------
-- FUNCTION: meteurosystem.get_subordinate_leave_report(integer)

-- DROP FUNCTION IF EXISTS meteurosystem.get_subordinate_leave_report(integer);

CREATE OR REPLACE FUNCTION meteurosystem.get_subordinate_leave_report(
	sup_id integer)
    RETURNS TABLE("Nazwisko i Imię" text, "Uw zaległy" numeric, "Uw aktualny rok" numeric, "UŻ" integer, "HO" integer) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
WITH sup_list AS (
    SELECT unnest(
        CASE
            WHEN sup_id = 388 THEN ARRAY[212,278,388,666]
            ELSE ARRAY[sup_id]
        END
    ) AS s_id
),
prac AS (
    SELECT worker_id
    FROM sup_list
    CROSS JOIN LATERAL meteurosystem.hr_get_subordinate_list(s_id)
    
    UNION ALL
    
    SELECT 25 AS worker_id
    WHERE sup_id = 388
)
SELECT
    u."Nazwisko i Imię",
    u."Uw zaległy",
    u."Uw pozostały do wykorzystania"-u."Uw zaległy" as "Uw aktualny rok",
	l.remaining_holiday as "UŻ",
	h.remaining_holiday as "HO"
FROM prac p
left JOIN meteurosystem.hr_raport_urlopy u ON p.worker_id = u."ID"
left join meteurosystem.hr_leave_balances_new l on l.employee_id = p.worker_id and l.leave_type_id = 8
left join meteurosystem.hr_leave_balances_new h on h.employee_id = p.worker_id and h.leave_type_id = 10
$BODY$;

ALTER FUNCTION meteurosystem.get_subordinate_leave_report(integer)
    OWNER TO testdbuser;


--------------------------------------------------
--------------------------------------------------
-- # TODO: NA PODSTAWIE TEJ FUNKCJI ZBUDUJ PODGLAD DELEGACJI NA INNE STANOWISKO
-- FUNCTION: meteurosystem.hr_gen_leave_entry_all()

-- DROP FUNCTION IF EXISTS meteurosystem.hr_gen_leave_entry_all();

CREATE OR REPLACE FUNCTION meteurosystem.hr_gen_leave_entry_all(
	)
    RETURNS TABLE(employee_id integer, data_wpisu date, skrot text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
	 #variable_conflict use_column
	
begin 
	return query

SELECT
r.employee_id,
--start_date,
(generate_series(r.start_date, r.end_date, '1 day'))::date AS data_wpisu,
concat(t.skrot,' - ',t.nazwa) as typ
--end_date, leave_type_id, status, submitted_at, approved_at, approver_id, requested_days, requester
	FROM meteurosystem.hr_leave_requests r
	join meteurosystem.hr_types_hol_req t on t.id=r.leave_type_id
	where r.status in (1,2)
	order by data_wpisu;
	end;
$BODY$;

ALTER FUNCTION meteurosystem.hr_gen_leave_entry_all()
    OWNER TO postgres;

--------------------------------------------------
--------------------------------------------------