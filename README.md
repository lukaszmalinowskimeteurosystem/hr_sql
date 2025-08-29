# Testy triggerów Postgres (hr_info)

## Uruchomienie

1. `docker compose up -d`  # Postgres + automatyczne wykonanie SQL z ./sql
2. (opcjonalnie) Sprawdź bazę: `psql -h localhost -U testdbuser -d testdb` (hasło: `testdbpass`)
3. `cd app && python -m venv .venv && . .venv/bin/activate` (Windows: `.venv\\Scripts\\activate`)
4. `pip install -r requirements.txt`
5. `pytest -q`

## Notatki

- Dwa triggery z listą kolumn (na `contract_end_date` i `leave_entitlement`) odpalają się **również dla INSERT** – to zachowanie PostgreSQL.
- Jeśli w jednym UPDATE zmienisz obie kolumny, odpalą się **oba** triggery + ogólny log, a kolejność między AFTER triggerami określa nazwa (`TG_NAME`).
- Własne ciała funkcji możesz wgrać, podmieniając sekcję w `sql/02_functions_and_triggers.sql` i robiąc `docker compose down -v && docker compose up -d` (czysty start).

# TODO: Update this readme