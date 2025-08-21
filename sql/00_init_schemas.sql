-- Schematy i rozsądne ustawienia

CREATE SCHEMA IF NOT EXISTS meteurosystem;

-- public zostawiamy (będzie tabela tb_pracownicy)
 -- Przydatne rozszerzenia do debugowania

CREATE EXTENSION IF NOT EXISTS pgcrypto;


CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log tabelka do testów triggerów

CREATE TABLE IF NOT EXISTS meteurosystem.hr_trigger_log ( id bigserial PRIMARY KEY,
																																																										ts timestamptz NOT NULL DEFAULT now(),
																																																										operation text NOT NULL,
																																																										trigger_name text NOT NULL,
																																																										table_name text NOT NULL,
																																																										row_id int, employee_id int, who text NOT NULL DEFAULT current_user,
																																																										old_row jsonb,
																																																										new_row jsonb);

COMMENT ON TABLE meteurosystem.hr_trigger_log IS 'Centralny log wywołań funkcji/triggerów na potrzeby testów.';