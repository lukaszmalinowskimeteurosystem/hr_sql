import os
import pathlib
import time

import pytest
from psycopg import connect

ROOT = pathlib.Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"


@pytest.fixture(scope="session", autouse=True)
def _wait_for_db():
    # proste oczekiwanie na health (docker healthcheck zwykle wystarczy)
    host = os.getenv("PGHOST", "localhost")
    port = int(os.getenv("PGPORT", "5432"))
    for _ in range(60):
        try:
            with connect(
                host=host,
                port=port,
                dbname=os.getenv("PGDATABASE", "testdb"),
                user=os.getenv("PGUSER", "testdbuser"),
                password=os.getenv("PGPASSWORD", "testdbpass"),
            ) as _conn:
                return
        except Exception:
            time.sleep(1)
    raise RuntimeError("Database not ready")


@pytest.fixture(scope="session", autouse=True)
def bootstrap_db():
    # Nic do zrobienia: init wykonuje Postgres ze /docker-entrypoint-initdb.d
    # Ale możemy upewnić się, że tabele istnieją
    yield


@pytest.fixture(autouse=True)
def clean_log():
    # Czyścimy log przed każdym testem
    from app.db import execute

    execute("TRUNCATE meteurosystem.hr_trigger_log RESTART IDENTITY")
    yield
