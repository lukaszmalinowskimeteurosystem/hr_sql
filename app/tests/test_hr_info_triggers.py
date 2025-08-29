import datetime as dt

from app.db import execute, fetchall, fetchone

#
# dodanie nowego pracownika
#


def test_first_insert_new_employe_738():
    # reset tabel zależnych od testu
    execute("TRUNCATE meteurosystem.hr_leave_balances_new RESTART IDENTITY CASCADE")
    execute("TRUNCATE meteurosystem.hr_info RESTART IDENTITY CASCADE")

    # insert do hr_info (reszta FK już istnieje w bazie!)
    execute(
        """
        INSERT INTO meteurosystem.hr_info(employee_id, employment_date, contract_end_date, leave_entitlement, umowa_id)
        VALUES (738, %s, %s, 26, 1)
        """,
        (dt.date(2025, 8, 4), dt.date(2026, 1, 31)),
    )

    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 and leave_type_id=2"
    )
    assert len(balances) == 1

    row = balances[0]
    assert row["leave_type_id"] == 2
    assert row["overdue"] == 0
    assert row["current_year"] == 11
    assert row["next_year"] == 3
    assert row["remaining_holiday"] == 11
    assert row["used_days"] == 0
    assert row["used_from_current_year"] == 0


#
# przedłużenie kontraktu dla praconiwka o rok
#
def test_extend_contract_creates_next_year_balance():
    # reset tabel zależnych
    execute("TRUNCATE meteurosystem.hr_leave_balances_new RESTART IDENTITY CASCADE")
    execute("TRUNCATE meteurosystem.hr_info RESTART IDENTITY CASCADE")

    # Insert: początkowa umowa (jak w poprzednim teście)
    execute(
        """
        INSERT INTO meteurosystem.hr_info(employee_id, employment_date, contract_end_date, leave_entitlement, umowa_id)
        VALUES (738, %s, %s, 26, 1)
        """,
        (dt.date(2025, 8, 4), dt.date(2026, 1, 31)),
    )

    # Update: przedłużamy kontrakt o kolejny rok (np. do końca 2026)
    execute(
        """
        UPDATE meteurosystem.hr_info
        SET contract_end_date = %s
        WHERE employee_id = 738
        """,
        (dt.date(2026, 12, 31),),
    )

    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 AND leave_type_id = 2"
    )
    assert len(balances) == 1

    row = balances[0]

    # Sprawdzenia:
    # - bieżący rok (2025) nadal 11 dni (umowa sierpień–grudzień 2025)
    # - przyszły rok (2026) -> pełny etat 26 dni
    assert row["current_year"] == 11
    assert row["next_year"] == 26
    assert row["remaining_holiday"] == 11  # zakładamy brak wykorzystania dni


def test_employee_termination_in_october_2025():
    # Reset tabel
    execute("TRUNCATE meteurosystem.hr_leave_balances_new RESTART IDENTITY CASCADE")
    execute("TRUNCATE meteurosystem.hr_info RESTART IDENTITY CASCADE")

    # 1. INSERT: pracownik zatrudniony w sierpniu 2025, kontrakt do stycznia 2026
    execute(
        """
        INSERT INTO meteurosystem.hr_info(employee_id, employment_date, contract_end_date, leave_entitlement, umowa_id)
        VALUES (738, %s, %s, 26, 1)
        """,
        (dt.date(2025, 8, 4), dt.date(2026, 1, 31)),
    )

    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 AND leave_type_id=2"
    )
    assert len(balances) == 1
    row = balances[0]
    assert row["current_year"] == 11
    assert row["next_year"] == 3
    assert row["remaining_holiday"] == 11

    # 2. UPDATE: przedłużenie umowy do stycznia 2027
    execute(
        """
        UPDATE meteurosystem.hr_info
        SET contract_end_date = %s
        WHERE employee_id = 738
        """,
        (dt.date(2027, 1, 31),),
    )

    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 AND leave_type_id=2"
    )
    row = balances[0]
    assert row["current_year"] == 11
    assert row["next_year"] == 26
    assert row["remaining_holiday"] == 11

    # 3. UPDATE: zakończenie umowy w październiku 2025
    execute(
        """
        UPDATE meteurosystem.hr_info
        SET contract_end_date = %s
        WHERE employee_id = 738
        """,
        (dt.date(2025, 10, 31),),
    )

    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 AND leave_type_id=2"
    )
    row = balances[0]
    assert row["leave_type_id"] == 2
    assert row["overdue"] == 0
    # VIII, IX, X → 3/12 * 26 ≈ 6.5 → zaokrąglenie w górę = 7
    assert row["current_year"] == 7
    assert row["next_year"] == 0
    assert row["remaining_holiday"] == 7


def test_wnioski_urlopowe():
    # Reset tabel
    execute("TRUNCATE meteurosystem.hr_leave_balances_new RESTART IDENTITY CASCADE")
    execute("TRUNCATE meteurosystem.hr_info RESTART IDENTITY CASCADE")

    # 1. Wyłączamy triggery na czas INSERT-u
    execute("ALTER TABLE meteurosystem.hr_info DISABLE TRIGGER ALL")

    # 2. INSERT pracownika z pominięciem triggerów
    execute(
        """
        INSERT INTO meteurosystem.hr_info(employee_id, employment_date, contract_end_date, leave_entitlement, umowa_id)
        VALUES (406, '2017-05-08', NULL, 26, 1)
    """
    )

    # 2.1 INSERT początkowych danych do hr_leave_balances_new
    execute(
        """
        INSERT INTO meteurosystem.hr_leave_balances_new(overdue, current_year, next_year, used_days, remaining_holiday, employee_id, leave_type_id, used_from_current_year)
        VALUES (0,26,26,24,18,406,2,8)
    """
    )

    # 3. Włączamy ponownie triggery
    execute("ALTER TABLE meteurosystem.hr_info ENABLE TRIGGER ALL")

    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 406 AND leave_type_id=2"
    )
    assert len(balances) == 1
    row = balances[0]
    assert row["overdue"] == 0
    assert row["current_year"] == 26
    assert row["next_year"] == 26
    assert row["used_days"] == 24
    assert row["remaining_holiday"] == 18
    assert row["employee_id"] == 406
    assert row["leave_type_id"] == 2
    assert row["used_from_current_year"] == 8

    ## 4 składamy i akceptujemy wniosek urlopowy
    row = fetchone(
        """
        INSERT INTO meteurosystem.hr_leave_requests(employee_id, start_date, end_date, leave_type_id, status, submitted_at, approved_at, approver_id, requested_days, requester)
        VALUES (406,'2025-07-29','2025-07-29',2,1,'2025-07-28 07:31:35.232843',NULL,NULL,1,406)
        RETURNING id
    """
    )
    new_id = row["id"]

    execute(
        """
       UPDATE meteurosystem.hr_leave_requests
       set status=2
       where id=%s
    """,
        (new_id,),
    )

    # 5  Teraz sprawdzamy stan bilansów
    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = %s AND leave_type_id = 2",
        (406,),  # parametry zapytania
    )
    assert len(balances) == 1

    row = balances[0]
    assert row["overdue"] == 0
    assert row["current_year"] == 26
    assert row["next_year"] == 26
    assert row["used_days"] == 25
    assert row["remaining_holiday"] == 17
    assert row["employee_id"] == 406
    assert row["leave_type_id"] == 2
    assert row["used_from_current_year"] == 9

    # 6 złożenie wniosku , akceptacja i jego anulowanie

    row = fetchone(
        """
        INSERT INTO meteurosystem.hr_leave_requests(employee_id, start_date, end_date, leave_type_id, status, submitted_at, approved_at, approver_id, requested_days, requester)
        VALUES (406,'2025-09-15','2025-09-19',2,1,'2025-08-28 07:31:35.232843',NULL,NULL,5,406)
        RETURNING id
    """
    )
    new_id = row["id"]
    # akceptacja wniosku
    execute(
        """
       UPDATE meteurosystem.hr_leave_requests
       set status=2
       where id=%s
    """,
        (new_id,),
    )
    # anulowanie wniosku
    execute(
        """
       UPDATE meteurosystem.hr_leave_requests
       set status=4
       where id=%s
    """,
        (new_id,),
    )

    # 5  Teraz sprawdzamy stan bilansów
    balances = fetchall(
        "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = %s AND leave_type_id = 2",
        (406,),  # parametry zapytania
    )
    assert len(balances) == 1

    row = balances[0]
    assert row["overdue"] == 0
    assert row["current_year"] == 26
    assert row["next_year"] == 26
    assert row["used_days"] == 25
    assert row["remaining_holiday"] == 17
    assert row["employee_id"] == 406
    assert row["leave_type_id"] == 2
    assert row["used_from_current_year"] == 9


####################################################################
# # 2. UPDATE: przedłużenie umowy do stycznia 2027
# execute(
#     """
#     UPDATE meteurosystem.hr_info
#     SET contract_end_date = %s
#     WHERE employee_id = 738
#     """,
#     (dt.date(2027, 1, 31),),
# )

# balances = fetchall(
#     "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 AND leave_type_id=2"
# )
# row = balances[0]
# assert row["current_year"] == 11
# assert row["next_year"] == 26
# assert row["remaining_holiday"] == 11

# # 3. UPDATE: zakończenie umowy w październiku 2025
# execute(
#     """
#     UPDATE meteurosystem.hr_info
#     SET contract_end_date = %s
#     WHERE employee_id = 738
#     """,
#     (dt.date(2025, 10, 31),),
# )

# balances = fetchall(
#     "SELECT * FROM meteurosystem.hr_leave_balances_new WHERE employee_id = 738 AND leave_type_id=2"
# )
# row = balances[0]
# assert row["leave_type_id"] == 2
# assert row["overdue"] == 0
# # VIII, IX, X → 3/12 * 26 ≈ 6.5 → zaokrąglenie w górę = 7
# assert row["current_year"] == 7
# assert row["next_year"] == 0
# assert row["remaining_holiday"] == 7
