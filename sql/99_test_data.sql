-- Dane przykładowe do szybkiego startu

INSERT INTO public.tb_pracownicy(p_idpracownika,p_imie, p_nazwisko)
VALUES (738, 'Jan','Kowalski'); -- id = 1

----
INSERT INTO public.tb_pracownicy(p_idpracownika,p_imie, p_nazwisko)
VALUES (406, 'Katarzyna','Szymaniak'); -- id = 1
      
----

INSERT INTO public.tb_pracownicy(p_idpracownika,p_imie, p_nazwisko)
VALUES (592, 'Łukasz','Malinowski'); -- id = 1

INSERT INTO meteurosystem.hr_contract_type (id, typ_umowy)
VALUES
(1, 'UP'),
(2, 'UZ'),
(3, 'Usługi');

INSERT INTO meteurosystem.hr_types_hol_req (nazwa, skrot, id, ograniczenie)
VALUES
('Urlop wypoczynkowy', 'UW', 2, 1),
('Opieka nad dzieckiem', 'OP', 7, 1),
('Urlop na żądanie', 'UŻ', 8, 1),
('Wyjazd służbowy', 'WS', 15, 0),
('Dzień wolny za święto', 'DWŚ', 13, 0),
('Nieobecność (umowa zlecenie / zewnętrzna)', 'NZ', 14, 0),
('Praca zdalna', 'HO', 10, 1),
('Urlop siła wyższa', 'UŚW', 11, 1),
('Dzień wolny w zamian za pracę w sobotę', 'NpDw', 1, 0),
('Zwolnienie lekarskie', 'Ch', 3, 0),
('Badania lekarskie', 'Bl', 4, 0),
('Urlop okolicznościowy', 'UOK', 5, 0),
('Nieobecnosc niepłatna', 'NN', 6, 0),
('Nieobecność płatna', 'NP', 9, 0),
('Urlop bezpłatny', 'UB', 12, 0);


-- INSERT INTO meteurosystem.hr_info(employee_id, employment_date, contract_end_date, leave_entitlement, umowa_id)
-- VALUES (738, '2025-08-04','2026-01-31',26,1);


