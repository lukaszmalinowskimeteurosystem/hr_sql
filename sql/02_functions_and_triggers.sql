--hr_info: ok
--hr_leave_balances: ok
--hr_leave_requests: 






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





--TODO do usunięcia
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

--TODO do usunięcia 
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

--TODO do usunięcia
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


