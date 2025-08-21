import os
import pathlib

from dotenv import load_dotenv
from psycopg import connect
from psycopg.rows import dict_row

ROOT = pathlib.Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")
load_dotenv()  # czyta .env z katalogu głównego projektu, jeśli uruchamiasz z root-a


def get_conn():
    dsn = {
        "host": os.getenv("PGHOST", "localhost"),
        "port": int(os.getenv("PGPORT", "55432")),
        "dbname": os.getenv("PGDATABASE", "testdb"),
        "user": os.getenv("PGUSER", "testdbuser"),
        "password": os.getenv("PGPASSWORD", "testdbpass"),
    }
    return connect(**dsn)


def fetchall(sql, params=None):
    with get_conn() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(sql, params or {})
            return cur.fetchall()


def execute(sql, params=None):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or {})
            conn.commit()


def fetchone(sql, params=None):
    with get_conn() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(sql, params or {})
            return cur.fetchone()


# if __name__ == "__main__":
#     print(
#         fetchall(
#             "select current_user, current_database(), inet_server_addr(), inet_server_port()"
#         )
#     )

if __name__ == "__main__":
    print(
        fetchall(
            "SELECT table_schema, table_name FROM information_schema.tables WHERE table_name = 'hr_trigger_log'"
        )
    )
