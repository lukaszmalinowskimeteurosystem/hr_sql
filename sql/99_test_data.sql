
TRUNCATE TABLE meteurosystem.hr_employee_hierarchy RESTART IDENTITY CASCADE;
TRUNCATE TABLE meteurosystem.hr_leave_balances_new RESTART IDENTITY CASCADE;
TRUNCATE TABLE meteurosystem.hr_leave_requests RESTART IDENTITY CASCADE;
TRUNCATE TABLE meteurosystem.hr_info RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.tb_pracownicy RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.ts_dzialy RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.ts_stanowisko RESTART IDENTITY CASCADE;
TRUNCATE TABLE meteurosystem.hr_contract_type RESTART IDENTITY CASCADE;
TRUNCATE TABLE meteurosystem.hr_types_hol_req RESTART IDENTITY CASCADE;


-- Dane przykładowe do szybkiego startu

-- INSERT INTO public.tb_pracownicy(p_idpracownika,p_imie, p_nazwisko)
-- VALUES (738, 'Jan','Kowalski'); -- id = 1

-- ----
-- INSERT INTO public.tb_pracownicy(p_idpracownika,p_imie, p_nazwisko)
-- VALUES (406, 'Katarzyna','Szymaniak'); -- id = 1
      
-- ----

-- INSERT INTO public.tb_pracownicy(p_idpracownika,p_imie, p_nazwisko)
-- VALUES (592, 'Łukasz','Malinowski'); -- id = 1

-- Czyścimy tabelę i resetujemy ID




INSERT INTO meteurosystem.hr_contract_type (id, typ_umowy)
VALUES
(1, 'UP'),
(2, 'UZ'),
(3, 'Usługi');


INSERT INTO public.ts_stanowisko (st_idstanowiska, st_nazwa, st_opis, st_grwbazie)
OVERRIDING SYSTEM VALUE
VALUES
(0, 'Nie dotyczy', NULL, NULL),
(2, 'Magazynier', 'Magazynier', 'szef'),
(74, 'OPERATIVA', 'Firma zewnętrzna', 'szef'),
(75, 'Product Development Manager', 'Sprzedaż', 'szef'),
(76, 'Kierownik ds. IT i Rozwoju Systemu ERP', 'Kierownik ds. IT i Rozwoju Systemu ERP', 'szef'),
(77, 'Kontroler Jakości Dostaw/Pracownik Produkcji ', 'Kontroler Jakości Dostaw/Pracownik Produkcji ', 'szef'),
(78, 'Specjalista ds. Logistyki Młodszy', 'Specjalista ds. Logistyki Młodszy', 'szef'),
(20, 'Spawacz', 'Spawacz', 'szef'),
(21, 'Ślusarz', 'Ślusarz', 'szef'),
(22, 'Operator Robota Spawalniczego', 'Operator Robota Spawalniczego', 'szef'),
(8, 'Specjalista ds. Zakupów', 'Specjalista ds. Zakupów', 'szef'),
(34, 'Księgowa', 'Księgowa', 'szef'),
(29, 'Praktykant', 'Praktykant', 'szef'),
(69, 'Kierownik Zmiany', 'Kierownik Zmiany', 'szef'),
(1, 'Dyrektor Zarządzający', 'Dyrektor Zarządzający', 'szef'),
(3, 'Inżynier CAD-CAM', 'Inżynier CAD-CAM', 'szef'),
(28, 'Inżynier Procesu', 'Inżynier Procesu', 'szef'),
(57, 'Pracownik Produkcji', 'Pracownik Produkcji', 'szef'),
(13, 'Operator Maszyn  CNC', 'Operator Maszyn  CNC', 'szef'),
(62, 'Ślusarz/Spawacz', '0', 'szef'),
(63, 'Kierownik ds. Planowania Produkcji', '0', 'szef'),
(64, 'Specjalista ds. HR', '0', 'szef'),
(68, 'Specjalista ds. Utrzymania Ruchu', 'Specjalista ds. Utrzymania Ruchu', 'szef'),
(65, 'Specjalista ds. Obsługi Klienta', '1', 'szef'),
(49, 'Logistyk wewnętrzny', 'Logistyk wewnętrzny', 'szef'),
(50, 'Inżynier CAD/CAM - Lider Zespołu', 'Inżynier CAD/CAM - Lider Zespołu', 'szef'),
(53, 'Inżynier CAD/CAM Młodszy', 'Inżynier CAD/CAM Młodszy', 'szef'),
(36, 'Inżynier/Technolog', 'Inżynier/Technolog', 'szef'),
(42, 'Inżynier/Technolog Młodszy', 'Inżynier/Technolog Młodszy', 'szef'),
(30, 'Inżynier/Technolog Starszy', 'Inżynier/Technolog Starszy', 'szef'),
(52, 'Inżynier/Technolog/Mistrz Spawalnik', 'Inżynier/Technolog/Mistrz Spawalnik', 'szef'),
(66, 'Junior Key Account Manager', 'Junior Key Account Manager', 'szef'),
(10, 'Key Account Manager', 'Key Account Manager', 'szef'),
(5, 'Kierownik ds. Obsługi Klienta', 'Kierownik ds. Obsługi Klienta', 'szef'),
(33, 'Kierownik ds. Utrzymania Obiektu', 'Kierownik ds. Utrzymania Obiektu', 'szef'),
(19, 'Kierownik Działu Logistyki i Gospodarki Magazynem', 'Kierownik Działu Logistyki i Gospodarki Magazynem', 'szef'),
(9, 'Kierownik Działu Technologiczno-Wdrożeniowego', 'Kierownik Działu Technologiczno-Wdrożeniowego', 'szef'),
(6, 'Kontroler Jakości/Narzędziowiec', 'Kontroler Jakości/Narzędziowiec', 'szef'),
(51, 'Lider Działu Technologiczno-Wdrożeniowego', 'Lider Działu Technologiczno-Wdrożeniowego', 'szef'),
(18, 'Magazynier/Kontroler Dostaw', 'Magazynier/Kontroler Dostaw', 'szef'),
(35, 'Magazynier ds. Kooperacji', 'Magazynier ds. Kooperacji', 'szef'),
(48, 'Magazynier Młodszy', 'Magazynier Młodszy', 'szef'),
(46, 'Magazynier Starszy', 'Magazynier Starszy', 'szef'),
(59, 'Magazynier Starszy/ Lider Zespołu', 'Magazynier Starszy/ Lider Zespołu', 'szef'),
(32, 'Magazynier/ Operator Maszyn CNC Młodszy', 'Magazynier/ Operator Maszyn CNC Młodszy', 'szef'),
(47, 'Magazynier/ Pracownik Gospodarczy/ Operator Maszyn CNC', 'Magazynier/ Pracownik Gospodarczy/Operator Maszyn CNC', 'szef'),
(60, 'Operator Kabiny Śrutowniczej', 'Operator Kabiny Śrutowniczej', 'szef'),
(26, 'Operator Maszyn CNC Młodszy', 'Operator Maszyn CNC Młodszy', 'szef'),
(16, 'Operator Maszyn CNC Starszy', 'Operator Maszyn CNC Starszy', 'szef'),
(56, 'Planista Produkcji', 'Planista Produkcji', 'szef'),
(37, 'Pomocnik Operatora Maszyn CNC', 'Pomocnik Operatora Maszyn CNC', 'szef'),
(17, 'Pracownik Produkcji Młodszy', 'Pracownik Produkcji Młodszy', 'szef'),
(27, 'Specjalista ds. Kooperacji', 'Specjalista ds. Kooperacji', 'szef'),
(55, 'Specjalista ds. Logistyki', 'Specjalista ds. Logistyki', 'szef'),
(45, 'Pracownik Produkcji/ Operator Kabiny Śrutowniczej', 'Pracownik Produkcji/Operator Kabiny Śrutowniczej', 'szef'),
(25, 'Pracownik Utrzymania Czystości', 'Pracownik Utrzymania Czystości', 'szef'),
(61, 'Quality Manager/ Główny Spawalnik/ Supervisor in Charge', 'Quality Manager/ Główny Spawalnik/ Supervisor in Charge', 'szef'),
(40, 'Spawacz/ Operator Robota Spawalniczego', 'Spawacz/ Operator Robota Spawalniczego', 'szef'),
(44, 'Spawacz/ Operator Robota Spawalniczego/ Lider Zespołu', 'Spawacz/ Operator Robota Spawalniczego/ Lider Zespołu', 'szef'),
(15, 'Specjalista ds. BHP', 'Specjalista ds. BHP', 'szef'),
(12, 'Specjalista ds. Kontroli Jakości', 'Specjalista ds. Kontroli Jakości', 'szef'),
(38, 'Specjalista ds. Magazynowych', 'Specjalista ds. Magazynowych', 'szef'),
(43, 'Specjalista ds. Obróbki Skrawaniem', 'Specjalista ds. Obróbki Skrawaniem', 'szef'),
(39, 'Specjalista ds. Zakupów Starszy', 'Specjalista ds. Zakupów Starszy', 'szef'),
(58, 'Ślusarz/ Lider Zespołu', 'Ślusarz/ Lider Zespołu', 'szef'),
(11, 'Ślusarz/ Monter', 'Ślusarz/ Monter', 'szef'),
(24, 'Koordynator Łańcucha Dostaw', 'Koordynator Łańcucha Dostaw', 'szef'),
(31, 'Dyrektor Finansowy', 'Dyrektor Finansowy', 'szef'),
(7, 'Dyrektor Handlowy', 'Dyrektor Handlowy', 'szef'),
(41, 'Ślusarz/ Monter/ Lider Zespołu', 'Ślusarz/ Monter/ Lider Zespołu', 'szef'),
(67, 'Kierownik Działu Obróbki Skrawaniem', 'Kierownik Działu Obróbki Skrawaniem', 'szef'),
(54, 'Kontroler Jakości', 'Kontroler Jakości', 'szef'),
(14, 'ZLECENIE', 'ZLECENIE', 'szef'),
(70, 'N/D', 'N/D', 'szef'),
(71, 'Magazynier/ Kontroler Jakości', 'Magazynier/ Kontroler Jakośc', 'szef'),
(72, 'IT PL HR', 'FIRMA ZEWNĘTRZNA', 'szef'),
(73, 'GLOBETEK', 'FIRMA ZEWNĘTRZNA', 'szef'),
(23, 'Operator Maszyn CNC Starszy/ Pracownik Utrzymania Ruchu', 'Operator Maszyn CNC Starszy/ Pracownik Utrzymania Ruchu', 'szef'),
(79, 'PAMIR ', 'Firma zew. ', 'szef'),
(80, 'SK WORK/KRIS MAR ', 'firma zew. ', 'szef'),
(81, 'Customer Development Specialist', 'Customer Development Specialist', 'szef'),
(82, 'Księgowy', 'Księgowy', 'szef'),
(83, 'Kierownik Działu Zakupów', 'Kierownik Działu Zakupów', 'szef'),
(84, 'Pracownik Produkcji/Monter Młodszy ', '.', 'szef'),
(85, 'Ślusarz Młodszy ', '.', 'szef'),
(86, 'HR Business Partner ', '.', 'szef'),
(87, 'Magazynier Starszy/Lider Zespołu ', 'Magazynier Starszy/Lider Zespołu', 'szef'),
(88, 'Specjalista ds. Planowania Produkcji ', 'Specjalista ds. Planowania Produkcji ', 'szef'),
(89, 'Customer Development Team Manager', 'Customer Development Team Manager', 'szef'),
(90, 'Spawacz/Operator Maszyn CNC ', 'Spawacz/Operator Maszyn CNC ', 'szef'),
(91, 'Operator Maszyn CNC Starszy/ Lider Zespołu ', 'Operator Maszyn CNC Starszy/ Lider Zespołu ', 'szef'),
(92, 'Spawacz/Trener', 'Spawacz/Trener', 'szef'),
(93, 'Pracownik Porządkowy ', 'Pracownik Porządkowy ', 'szef'),
(94, 'Specjalista ds. Kontroli Jakości/Operator Maszyn CNC Młodszy ', 'Specjalista ds Kontroli Jakości / Operator aMaszyn CNC Młodszy ', 'szef');

SELECT setval(pg_get_serial_sequence('public.ts_stanowisko','st_idstanowiska'),
              (SELECT MAX(st_idstanowiska) FROM public.ts_stanowisko));


--------------------------------------------------------------------------------
INSERT INTO public.ts_dzialy (dz_iddzialu, dz_nazwa) VALUES
(11, 'Marketing'),
(72, 'BHP'),
(1, 'Zarząd'),
(16, 'Utrzymanie Ruchu'),
(15, 'Z_N/D'),
(4, 'Z_N/D'),
(48, 'Z_N/D'),
(17, 'Z_N/D'),
(7, 'Z_N/D'),
(21, 'Z_N/D'),
(19, 'Z_N/D'),
(67, 'Śrutowanie'),
(53, 'Montaż'),
(14, 'HR'),
(71, 'Administracja'),
(56, 'Costa'),
(65, 'Prostowanie'),
(10, 'Finanse'),
(5, 'Administracja i Zarząd'),
(68, 'Ukosowanie'),
(6, 'Inżynierowie'),
(3, 'Koszty Sprzedaży'),
(13, 'Produkcja Ogólne'),
(18, 'Logistyka Wewnętrzna'),
(9, 'Zakupy'),
(66, 'Skrawanie'),
(12, 'Jakość'),
(52, 'Spawalnia'),
(73, 'Sprzedaż'),
(22, 'Technolodzy'),
(8, 'Magazyn'),
(41, 'Produkcja'),
(64, 'Lasery'),
(49, 'Prasy'),
(20, 'Działalność Pomocnicza'),
(50, 'Ślusarnia'),
(69, 'Ślusarnia Ogólne'),
(0, 'Nie dotyczy');

--------------------------------------------------------------------------------

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

-------------------------------------------------------
COPY public.tb_pracownicy (
    p_idpracownika,
    p_imie,
    p_nazwisko,
    dz_iddzialu,
    st_idstanowiska,
    p_czyaktywny
)
FROM '/csv/pracownicy.csv'
DELIMITER ';' CSV HEADER NULL '';
-------------------------------------------------------
--INSERT HIERRARCHI

COPY meteurosystem.hr_employee_hierarchy (
    employee_id, supervisor_id
)
FROM '/csv/hr_employee_hierarchy.csv'
DELIMITER ';' CSV HEADER NULL '';

-- INSERT INTO meteurosystem.hr_employee_hierarchy (employee_id, supervisor_id) VALUES
-- (663,212),
-- (668,80),
-- (582,278),
-- (638,80),
-- (680,52),
-- (686,80),
-- (544,406),
-- (131,403),
-- (278,388),
-- (715,212),
-- (629,278),
-- (466,80),
-- (431,80),
-- (118,80),
-- (717,278),
-- (210,212),
-- (445,52),
-- (682,52),
-- (692,80),
-- (224,80),
-- (578,251),
-- (497,80),
-- (359,80),
-- (52,403),
-- (583,80),
-- (315,406),
-- (685,80),
-- (601,388),
-- (639,80),
-- (697,406),
-- (553,212),
-- (496,52),
-- (591,52),
-- (468,80),
-- (487,80),
-- (565,25),
-- (606,80),
-- (700,80),
-- (698,406),
-- (588,406),
-- (403,251),
-- (580,251),
-- (649,406),
-- (54,212),
-- (592,403),
-- (559,278),
-- (710,52),
-- (657,80),
-- (91,80),
-- (718,52),
-- (706,80),
-- (348,212),
-- (610,80),
-- (721,251),
-- (589,80),
-- (666,388),
-- (399,80),
-- (103,80),
-- (388,251),
-- (283,251),
-- (324,406),
-- (363,80),
-- (681,212),
-- (701,80),
-- (471,212),
-- (423,80),
-- (162,406),
-- (120,80),
-- (406,403),
-- (707,80),
-- (281,388),
-- (102,80),
-- (65,406),
-- (633,80),
-- (455,80),
-- (75,80),
-- (74,212),
-- (389,80),
-- (627,666),
-- (133,80),
-- (564,251),
-- (454,80),
-- (385,80),
-- (398,80),
-- (80,403),
-- (405,666),
-- (684,39),
-- (550,39),
-- (628,39),
-- (240,39),
-- (585,39),
-- (411,39),
-- (483,39),
-- (705,39),
-- (665,39),
-- (541,39),
-- (452,39),
-- (670,39),
-- (723,39),
-- (720,39),
-- (719,39),
-- (602,39),
-- (630,283),
-- (507,283),
-- (526,283),
-- (691,283),
-- (212,388),
-- (68,406),
-- (664,80),
-- (637,80),
-- (491,80),
-- (729,80),
-- (480,403),
-- (625,403),
-- (730,80),
-- (728,666),
-- (699,80),
-- (39,403),
-- (702,80),
-- (98,80),
-- (382,80),
-- (460,80),
-- (678,80),
-- (658,80),
-- (676,80),
-- (635,80),
-- (530,80),
-- (708,80),
-- (462,666),
-- (662,212),
-- (674,406),
-- (688,406),
-- (25,388),
-- (86,402),
-- (677,402),
-- (738,278),
-- (712,402),
-- (479,402),
-- (402,403),
-- (727,406),
-- (522,80),
-- (644,80),
-- (713,80),
-- (703,80),
-- (724,80),
-- (704,80),
-- (733,278),
-- (612,52),
-- (620,80),
-- (722,80),
-- (734,80),
-- (711,80),
-- (422,406),
-- (736,80),
-- (739,212),
-- (740,212);


SELECT setval('meteurosystem.hr_employee_hierarchy_id_seq', (SELECT MAX(id) FROM meteurosystem.hr_employee_hierarchy));


----------HR_info-------
COPY meteurosystem.hr_info (employee_id, employment_date, contract_end_date, leave_entitlement, umowa_id
)
FROM '/csv/hr_info.csv'
DELIMITER ';' CSV HEADER NULL '';

----hr_saved_rcp_report-----
COPY meteurosystem.hr_saved_rcp_report (mpk, pracownik, id, stanowisko, data, start, koniec, czas_minuty, day_type, h_night, overtime, regular_time, "timestamp", edited_by
)
FROM '/csv/hr_saved_rcp_report_utf8.csv'
DELIMITER ';' CSV HEADER NULL '';