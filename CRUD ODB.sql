-- *******************************************************************************
-- *******************************************************************************
-- * 																		     
-- *   Temat projektu:         Zawodnicy NBA                                                      
-- * 																		     
-- *******************************************************************************

-- *******************************************************************************
-- *
-- 							B A Z A   O B I E K T O W A
-- *
-- *******************************************************************************

-- -------------------------------------------------------------------------------
-- TWORZENIE TYPÓW OBIEKTOWYCH I ICH METOD   [CREATE TYPE]                                         
-- -------------------------------------------------------------------------------


CREATE OR REPLACE TYPE wlasciciel_obj;
/

CREATE OR REPLACE TYPE klub_obj;
/

CREATE OR REPLACE TYPE glowny_sedzia_obj;
/

CREATE OR REPLACE TYPE zawodnik_obj;
/

CREATE OR REPLACE TYPE mecz_obj;
/

CREATE OR REPLACE TYPE manager_obj;
/

CREATE OR REPLACE TYPE statystykizawodnika_obj;
/

CREATE OR REPLACE TYPE osoba_obj AS OBJECT (
    imie             VARCHAR2(20 CHAR),
    nazwisko         VARCHAR2(20 CHAR),
    data_urodzenia   DATE,
    kraj_pochodzenia VARCHAR2(56 CHAR)
) NOT FINAL;
/

CREATE OR REPLACE TYPE glowny_sedzia_obj UNDER osoba_obj (
    id_sedziego INTEGER
) NOT FINAL;
/

CREATE OR REPLACE TYPE zawodnik_sklad_varray IS
    VARRAY(15) OF REF zawodnik_obj;
/

CREATE OR REPLACE TYPE klub_obj AS OBJECT (
    id_klubu         INTEGER,
    nazwa_klubu      VARCHAR2(50 CHAR),
    lokalizacja      VARCHAR2(50 CHAR),
    data_zalozenia   DATE,
    arena            VARCHAR2(30 CHAR),
    sklad            zawodnik_sklad_varray,
    wlasciciel_klubu REF wlasciciel_obj,
    MAP MEMBER FUNCTION wiek_klubu RETURN INTEGER
) NOT FINAL;
/

CREATE OR REPLACE TYPE kontuzje_obj AS OBJECT (
    id_kontuzji INTEGER,
    opis        VARCHAR2(100 CHAR),
    ORDER MEMBER FUNCTION porownajkontuzje (k kontuzje_obj) RETURN INTEGER
) NOT FINAL;
/

CREATE OR REPLACE TYPE zawodnik_col IS
    TABLE OF REF zawodnik_obj;
/

CREATE OR REPLACE TYPE manager_obj UNDER osoba_obj (
    id_managera           INTEGER,
    data_wejscia_na_rynek DATE,
    zawodnicy_manager     zawodnik_col,
    MEMBER FUNCTION czas_na_rynku RETURN VARCHAR2
) NOT FINAL;
/

CREATE OR REPLACE TYPE statystyki_zawodnika_col IS
    TABLE OF REF statystykizawodnika_obj;
/

CREATE OR REPLACE TYPE mecz_obj AS OBJECT (
    id_meczu              INTEGER,
    gospodarze            REF klub_obj,
    goscie                REF klub_obj,
    glowny_sedzia         REF glowny_sedzia_obj,
    data_meczu            DATE,
    statystyki_zawodnikow statystyki_zawodnika_col,
    zawodnicy_mecz        zawodnik_col,
    STATIC FUNCTION dzien_mecz (data DATE) RETURN VARCHAR2
) NOT FINAL;
/

-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

CREATE OR REPLACE TYPE statystyki_obj AS OBJECT (
    punkty     INTEGER,
    asysty     INTEGER,
    zbiorki    INTEGER,
    przechwyty INTEGER,
    bloki      INTEGER
) NOT FINAL;
/

CREATE OR REPLACE TYPE statystykizawodnika_obj UNDER statystyki_obj (
    id_statystyk INTEGER,
    zawodnik_ref REF zawodnik_obj,
    mecz_ref     REF mecz_obj
) NOT FINAL;
/

CREATE OR REPLACE TYPE wlasciciel_obj UNDER osoba_obj (
    id_wlasciciela       INTEGER,
    data_przejecia_klubu DATE
) NOT FINAL;
/

-- predefined type, no DDL - XMLTYPE

CREATE OR REPLACE TYPE mecze_col IS
    TABLE OF REF mecz_obj;
/

CREATE OR REPLACE TYPE kontuzje_col IS
    TABLE OF kontuzje_obj;
/

CREATE OR REPLACE TYPE zawodnik_obj UNDER osoba_obj (
    id_zawodnika   INTEGER,
    pozycja        VARCHAR2(17 CHAR),
    rok_draftu     INTEGER,
    wzrost         NUMBER(5, 2),
    waga           INTEGER,
    klub           REF klub_obj,
    manager        REF manager_obj,
    mecze_zawodnik mecze_col,
    kontuzje       kontuzje_col
) NOT FINAL;
/

CREATE OR REPLACE TYPE wlasciciel_col IS
    TABLE OF REF wlasciciel_obj;
/

CREATE OR REPLACE TYPE zawodnik_varray IS
    VARRAY(24) OF zawodnik_obj;
/

CREATE OR REPLACE TYPE BODY manager_obj AS

    MEMBER FUNCTION czas_na_rynku RETURN VARCHAR2 IS

    daysAgo NUMBER;
    monthsAgo NUMBER;
    yearsAgo NUMBER;

    daysAgo_Relative NUMBER;
    monthsAgo_Relative NUMBER;

    result VARCHAR2(255);

    BEGIN
        daysAgo := FLOOR(CURRENT_DATE - data_wejscia_na_rynek);
        monthsAgo := FLOOR(MONTHS_BETWEEN(CURRENT_DATE, data_wejscia_na_rynek));
        yearsAgo := FLOOR(monthsAgo / 12);

        daysAgo_Relative := MOD(daysAgo, EXTRACT(DAY FROM LAST_DAY(CURRENT_DATE)));
        monthsAgo_Relative := MOD(monthsAgo - yearsAgo * 12, yearsAgo * 12);

        IF yearsAgo > 0 THEN
            result := yearsAgo || ' lat, ';
        END IF;

        IF monthsAgo > 0 THEN
            result := result || monthsAgo_Relative || ' miesiecy, ';
        END IF;

        IF daysAgo_Relative IS NULL THEN
            daysAgo_Relative := 0;
        END IF;

        result := result || daysAgo_Relative || ' dni.';

        RETURN result;
    END czas_na_rynku;

END;
/
CREATE OR REPLACE TYPE BODY mecz_obj AS
    STATIC FUNCTION dzien_mecz (data DATE) RETURN VARCHAR2
    IS
        odp varchar2(255);
    BEGIN
        IF TO_CHAR(data, 'DY') IN ('SO', 'N ') THEN
            IF data < SYSDATE THEN
                odp:='Danego dnia ';
                return odp || 'nie ma meczów, to weekend.';
            ELSE
                odp:='Danego dnia ';
                return odp || 'był weekend i nie było meczów';
            END IF;
        ELSE
            IF data > SYSDATE THEN
                odp:='Danego dnia ';
                return odp || 'są mecze.';
            ELSE
                odp:='Danego dnia ';
                return odp || 'były mecze.';
            END IF;
        END IF;
    END;
END;
/

CREATE OR REPLACE TYPE BODY kontuzje_obj AS
ORDER MEMBER FUNCTION porownajkontuzje (k kontuzje_obj)
  RETURN INTEGER
	IS
	BEGIN
 IF LENGTH(opis) < LENGTH(k.opis) THEN
	RETURN -1; 
 ELSIF LENGTH(opis) > LENGTH(k.opis) THEN
	RETURN 1; 
 ELSE
	RETURN 0;
 END IF;
END;
END;
/


CREATE OR REPLACE TYPE body klub_obj IS
    MAP MEMBER FUNCTION wiek_klubu RETURN INTEGER IS
    BEGIN
        RETURN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM data_zalozenia);
    END;
END;
/
-- -------------------------------------------------------------------------------
-- TWORZENIE TABEL OBIEKTOWYCH   [CREATE TABLE]                                         
-- -------------------------------------------------------------------------------


CREATE TABLE glowny_sedzia_tab OF glowny_sedzia_obj (
    imie NOT NULL,
    nazwisko NOT NULL,
    data_urodzenia NOT NULL,
    id_sedziego NOT NULL
);

CREATE TABLE klub_tab OF klub_obj (
    id_klubu NOT NULL,
    nazwa_klubu NOT NULL,
    lokalizacja NOT NULL,
    arena NOT NULL,
    wlasciciel_klubu NOT NULL
);

CREATE TABLE kontuzje_tab OF kontuzje_obj (
    id_kontuzji NOT NULL,
    opis NOT NULL
);

CREATE TABLE manager_tab OF manager_obj (
    imie NOT NULL,
    nazwisko NOT NULL,
    data_urodzenia NOT NULL,
    id_managera NOT NULL,
    data_wejscia_na_rynek NOT NULL
)
NESTED TABLE zawodnicy_manager 
--  WARNING: Using column name as default storage_table name for nested column Zawodnicy_manager 
 STORE AS zawodnicy_manager;

CREATE TABLE mecz_tab OF mecz_obj (
    id_meczu NOT NULL,
    gospodarze NOT NULL,
    goscie NOT NULL,
    data_meczu NOT NULL
)
    NESTED TABLE statystyki_zawodnikow 
--  WARNING: Using column name as default storage_table name for nested column Statystyki_zawodnikow 
     STORE AS statystyki_zawodnikow
    NESTED TABLE zawodnicy_mecz 
--  WARNING: Using column name as default storage_table name for nested column Zawodnicy_mecz 
     STORE AS zawodnicy_mecz;

CREATE TABLE statystykizawodnika_tab OF statystykizawodnika_obj (
    punkty NOT NULL,
    asysty NOT NULL,
    zbiorki NOT NULL,
    id_statystyk NOT NULL,
    zawodnik_ref NOT NULL,
    mecz_ref NOT NULL
);

CREATE TABLE wlasciciel_tab OF wlasciciel_obj (
    imie NOT NULL,
    nazwisko NOT NULL,
    data_urodzenia NOT NULL,
    id_wlasciciela NOT NULL
);

CREATE TABLE zawodnik_tab OF zawodnik_obj (
    imie NOT NULL,
    nazwisko NOT NULL,
    data_urodzenia NOT NULL,
    id_zawodnika NOT NULL,
    rok_draftu NOT NULL,
    wzrost NOT NULL,
    waga NOT NULL,
    klub NOT NULL
)
    NESTED TABLE mecze_zawodnik 
--  WARNING: Using column name as default storage_table name for nested column Mecze_zawodnik 
     STORE AS mecze_zawodnik
    NESTED TABLE kontuzje 
--  WARNING: Using column name as default storage_table name for nested column Kontuzje 
     STORE AS kontuzje;

-- -------------------------------------------------------------------------------
-- POLECENIA:   5 X INSERT  DO KAŻDEJ Z TABEL                                                
-- -------------------------------------------------------------------------------


INSERT INTO GLOWNY_SEDZIA_TAB (IMIE, NAZWISKO, DATA_URODZENIA, KRAJ_POCHODZENIA, ID_SEDZIEGO) VALUES ('Sean', 'Wright', TO_DATE('1971-08-29 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', '1');
INSERT INTO GLOWNY_SEDZIA_TAB (IMIE, NAZWISKO, DATA_URODZENIA, KRAJ_POCHODZENIA, ID_SEDZIEGO) VALUES ('Pat', 'Fraher', TO_DATE('1974-01-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', '2');
INSERT INTO GLOWNY_SEDZIA_TAB (IMIE, NAZWISKO, DATA_URODZENIA, KRAJ_POCHODZENIA, ID_SEDZIEGO) VALUES ('Courtney', 'Kirkland', TO_DATE('1974-10-22 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', '3');
INSERT INTO GLOWNY_SEDZIA_TAB (IMIE, NAZWISKO, DATA_URODZENIA, KRAJ_POCHODZENIA, ID_SEDZIEGO) VALUES ('David', 'Guthrie', TO_DATE('1974-05-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', '4');
INSERT INTO GLOWNY_SEDZIA_TAB (IMIE, NAZWISKO, DATA_URODZENIA, KRAJ_POCHODZENIA, ID_SEDZIEGO) VALUES ('Dedric', 'Taylor', TO_DATE('1975-11-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', '5');



INSERT INTO KONTUZJE_TAB (ID_KONTUZJI, OPIS) VALUES ('1', 'Skrecenie lewej kostki');
INSERT INTO KONTUZJE_TAB (ID_KONTUZJI, OPIS) VALUES ('2', 'Skrecenie prawej kostki');
INSERT INTO KONTUZJE_TAB (ID_KONTUZJI, OPIS) VALUES ('3', 'Zerwanie wiezadla krzyzowego przedniego');
INSERT INTO KONTUZJE_TAB (ID_KONTUZJI, OPIS) VALUES ('4', 'Zlamanie V kosci srodstopia');
INSERT INTO KONTUZJE_TAB (ID_KONTUZJI, OPIS) VALUES ('5', 'Zlamanie podstawy paliczka blizszego palca V');



INSERT INTO WLASCICIEL_TAB (ID_WLASCICIELA, IMIE, NAZWISKO, DATA_PRZEJECIA_KLUBU, DATA_URODZENIA, KRAJ_POCHODZENIA) VALUES ('1', 'Joseph', 'Lacob', TO_DATE('2010-07-15 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1956-01-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki');
INSERT INTO WLASCICIEL_TAB (ID_WLASCICIELA, IMIE, NAZWISKO, DATA_PRZEJECIA_KLUBU, DATA_URODZENIA, KRAJ_POCHODZENIA) VALUES ('2', 'James', 'Dolan', TO_DATE('1999-11-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1955-05-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki');
INSERT INTO WLASCICIEL_TAB (ID_WLASCICIELA, IMIE, NAZWISKO, DATA_PRZEJECIA_KLUBU, DATA_URODZENIA, KRAJ_POCHODZENIA) VALUES ('3', 'Wyc', 'Grousbeck', TO_DATE('2002-04-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1961-06-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki');
INSERT INTO WLASCICIEL_TAB (ID_WLASCICIELA, IMIE, NAZWISKO, DATA_PRZEJECIA_KLUBU, DATA_URODZENIA, KRAJ_POCHODZENIA) VALUES ('4', 'Mark', 'Cuban', TO_DATE('2000-01-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1958-07-31 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki');
INSERT INTO WLASCICIEL_TAB (ID_WLASCICIELA, IMIE, NAZWISKO, DATA_PRZEJECIA_KLUBU, DATA_URODZENIA, KRAJ_POCHODZENIA) VALUES ('5', 'Marc', 'Lasry', TO_DATE('2014-03-20 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1959-09-23 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Maroko');



INSERT INTO MANAGER_TAB (ID_MANAGERA, IMIE, NAZWISKO, DATA_WEJSCIA_NA_RYNEK, DATA_URODZENIA, KRAJ_POCHODZENIA, ZAWODNICY_MANAGER) VALUES ('1', 'Jeff', 'Austin', TO_DATE('1973-06-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1951-07-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939')));
INSERT INTO MANAGER_TAB (ID_MANAGERA, IMIE, NAZWISKO, DATA_WEJSCIA_NA_RYNEK, DATA_URODZENIA, KRAJ_POCHODZENIA, ZAWODNICY_MANAGER) VALUES ('2', 'Benjamin', 'Armstrong', TO_DATE('2006-07-15 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1967-09-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565')));
INSERT INTO MANAGER_TAB (ID_MANAGERA, IMIE, NAZWISKO, DATA_WEJSCIA_NA_RYNEK, DATA_URODZENIA, KRAJ_POCHODZENIA, ZAWODNICY_MANAGER) VALUES ('3', 'Jeffrey', 'Wechsler', TO_DATE('2005-11-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1962-07-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1628369')));
INSERT INTO MANAGER_TAB (ID_MANAGERA, IMIE, NAZWISKO, DATA_WEJSCIA_NA_RYNEK, DATA_URODZENIA, KRAJ_POCHODZENIA, ZAWODNICY_MANAGER) VALUES ('4', 'Bill', 'Duffy', TO_DATE('1985-11-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1961-05-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')));
INSERT INTO MANAGER_TAB (ID_MANAGERA, IMIE, NAZWISKO, DATA_WEJSCIA_NA_RYNEK, DATA_URODZENIA, KRAJ_POCHODZENIA, ZAWODNICY_MANAGER) VALUES ('5', 'Alex', 'Saratsis', TO_DATE('2005-04-07 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('1975-02-22 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Stany Zjednoczone Ameryki', ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '203507')));



INSERT INTO KLUB_TAB (ID_KLUBU, NAZWA_KLUBU, LOKALIZACJA, DATA_ZALOZENIA, ARENA, WLASCICIEL_KLUBU, SKLAD) VALUES ('10', 'Golden State Warriors', 'San Francisco, CA', TO_DATE('1946-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Chase Center', (SELECT REF(w) FROM WLASCICIEL_TAB w WHERE w.ID_WLASCICIELA = '1'), ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939')));
INSERT INTO KLUB_TAB (ID_KLUBU, NAZWA_KLUBU, LOKALIZACJA, DATA_ZALOZENIA, ARENA, WLASCICIEL_KLUBU, SKLAD) VALUES ('20', 'New York Knicks', 'New York City, NY', TO_DATE('1946-06-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Madison Square Garden', (SELECT REF(w) FROM WLASCICIEL_TAB w WHERE w.ID_WLASCICIELA = '2'), ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565')));
INSERT INTO KLUB_TAB (ID_KLUBU, NAZWA_KLUBU, LOKALIZACJA, DATA_ZALOZENIA, ARENA, WLASCICIEL_KLUBU, SKLAD) VALUES ('2', 'Boston Celtics', 'Boston, MA', TO_DATE('1946-06-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'TD Garden', (SELECT REF(w) FROM WLASCICIEL_TAB w WHERE w.ID_WLASCICIELA = '3'), ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1628369')));
INSERT INTO KLUB_TAB (ID_KLUBU, NAZWA_KLUBU, LOKALIZACJA, DATA_ZALOZENIA, ARENA, WLASCICIEL_KLUBU, SKLAD) VALUES ('7', 'Dallas Mavericks', 'Dallas, TX', TO_DATE('1980-05-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'American Airlines Center', (SELECT REF(w) FROM WLASCICIEL_TAB w WHERE w.ID_WLASCICIELA = '4'), ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')));
INSERT INTO KLUB_TAB (ID_KLUBU, NAZWA_KLUBU, LOKALIZACJA, DATA_ZALOZENIA, ARENA, WLASCICIEL_KLUBU, SKLAD) VALUES ('17', 'Milwaukee Bucks', 'Milwaukee, WI', TO_DATE('1968-01-22 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Fiserv Forum', (SELECT REF(w) FROM WLASCICIEL_TAB w WHERE w.ID_WLASCICIELA = '5'), ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '203507')));



INSERT INTO ZAWODNIK_TAB (ID_ZAWODNIKA, IMIE, NAZWISKO, DATA_URODZENIA, POZYCJA, KRAJ_POCHODZENIA, ROK_DRAFTU, WZROST, WAGA, KLUB, MANAGER, KONTUZJE, MECZE_ZAWODNIK) VALUES ('201939', 'Stephen', 'Curry', TO_DATE('1988-03-14 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Rozgrywajacy', 'Stany Zjednoczone Ameryki', '2009', '188', '84', (SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 10), (SELECT REF(m) FROM MANAGER_TAB m WHERE m.ID_MANAGERA = 1), KONTUZJE_COL(KONTUZJE_OBJ(1,'Skrecenie lewej kostki')), MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200233'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200222')));
INSERT INTO ZAWODNIK_TAB (ID_ZAWODNIKA, IMIE, NAZWISKO, DATA_URODZENIA, POZYCJA, KRAJ_POCHODZENIA, ROK_DRAFTU, WZROST, WAGA, KLUB, MANAGER, KONTUZJE, MECZE_ZAWODNIK) VALUES ('201565', 'Derrick', 'Rose', TO_DATE('1988-10-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Rozgrywajacy', 'Stany Zjednoczone Ameryki', '2008', '191', '91', (SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 20), (SELECT REF(m) FROM MANAGER_TAB m WHERE m.ID_MANAGERA = 2), KONTUZJE_COL(KONTUZJE_OBJ(1,'Skrecenie lewej kostki')), MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200233'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200111')));
INSERT INTO ZAWODNIK_TAB (ID_ZAWODNIKA, IMIE, NAZWISKO, DATA_URODZENIA, POZYCJA, KRAJ_POCHODZENIA, ROK_DRAFTU, WZROST, WAGA, KLUB, MANAGER, KONTUZJE, MECZE_ZAWODNIK) VALUES ('1628369', 'Jayson', 'Tatum', TO_DATE('1998-03-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Niski skrzydlowy', 'Stany Zjednoczone Ameryki', '2017', '203', '95', (SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 2), (SELECT REF(m) FROM MANAGER_TAB m WHERE m.ID_MANAGERA = 3), KONTUZJE_COL(KONTUZJE_OBJ(1,'Skrecenie lewej kostki')), MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200170')));
INSERT INTO ZAWODNIK_TAB (ID_ZAWODNIKA, IMIE, NAZWISKO, DATA_URODZENIA, POZYCJA, KRAJ_POCHODZENIA, ROK_DRAFTU, WZROST, WAGA, KLUB, MANAGER, KONTUZJE, MECZE_ZAWODNIK) VALUES ('1629029', 'Luka', 'Doncic', TO_DATE('1999-02-28 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Rozgrywajacy', 'Slowenia', '2018', '201', '104', (SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 7), (SELECT REF(m) FROM MANAGER_TAB m WHERE m.ID_MANAGERA = 4), KONTUZJE_COL(KONTUZJE_OBJ(2,'Skrecenie prawej kostki')), MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200170'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200311'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200222'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200111')));
INSERT INTO ZAWODNIK_TAB (ID_ZAWODNIKA, IMIE, NAZWISKO, DATA_URODZENIA, POZYCJA, KRAJ_POCHODZENIA, ROK_DRAFTU, WZROST, WAGA, KLUB, MANAGER, KONTUZJE, MECZE_ZAWODNIK) VALUES ('203507', 'Giannis', 'Antetokounmpo', TO_DATE('1994-12-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Srodkowy', 'Grecja', '2013', '213', '110', (SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 17), (SELECT REF(m) FROM MANAGER_TAB m WHERE m.ID_MANAGERA = 5), KONTUZJE_COL(KONTUZJE_OBJ(2,'Skrecenie prawej kostki')), MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200311')));



INSERT INTO MECZ_TAB (STATYSTYKI_ZAWODNIKOW, ID_MECZU, GOSPODARZE, GOSCIE, GLOWNY_SEDZIA, DATA_MECZU, ZAWODNICY_MECZ) VALUES (STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '8'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '9')),
'22200233', 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 10), 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 20),
(SELECT REF(s) FROM GLOWNY_SEDZIA_TAB s WHERE s.ID_SEDZIEGO = 1),
TO_DATE('2022-06-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939'), (SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565')));

INSERT INTO MECZ_TAB (STATYSTYKI_ZAWODNIKOW, ID_MECZU, GOSPODARZE, GOSCIE, GLOWNY_SEDZIA, DATA_MECZU, ZAWODNICY_MECZ) VALUES (STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '1'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '2')),
'22200170', 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 2), 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 7),
(SELECT REF(s) FROM GLOWNY_SEDZIA_TAB s WHERE s.ID_SEDZIEGO = 2),
TO_DATE('2022-06-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1628369'), (SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')));

INSERT INTO MECZ_TAB (STATYSTYKI_ZAWODNIKOW, ID_MECZU, GOSPODARZE, GOSCIE, GLOWNY_SEDZIA, DATA_MECZU, ZAWODNICY_MECZ) VALUES (STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '3'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '4')),
'22200311', 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 17), 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 7),
(SELECT REF(s) FROM GLOWNY_SEDZIA_TAB s WHERE s.ID_SEDZIEGO = 3),
TO_DATE('2022-11-30 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '203507'), (SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')));

INSERT INTO MECZ_TAB (STATYSTYKI_ZAWODNIKOW, ID_MECZU, GOSPODARZE, GOSCIE, GLOWNY_SEDZIA, DATA_MECZU, ZAWODNICY_MECZ) VALUES (STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '5'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '10')),
'22200222', 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 10), 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 7),
(SELECT REF(s) FROM GLOWNY_SEDZIA_TAB s WHERE s.ID_SEDZIEGO = 4),
TO_DATE('2022-10-11 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939'), (SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')));

INSERT INTO MECZ_TAB (STATYSTYKI_ZAWODNIKOW, ID_MECZU, GOSPODARZE, GOSCIE, GLOWNY_SEDZIA, DATA_MECZU, ZAWODNICY_MECZ) VALUES (STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_TAB s WHERE s.id_statystyk = '6'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '7')),
'22200111', 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 20), 
(SELECT REF(k) FROM KLUB_TAB k WHERE k.ID_KLUBU = 7),
(SELECT REF(s) FROM GLOWNY_SEDZIA_TAB s WHERE s.ID_SEDZIEGO = 5),
TO_DATE('2022-10-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565'), (SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')));



INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('1','30', '6', '5', '2', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200170')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('2','22', '7', '3', '2', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1628369'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200170')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('3','31', '3', '10', '2', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200311')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('4','18', '3', '3', '1', '1',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '203507'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200311')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('5','40', '8', '11', '1', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200222')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('6','27', '12', '11', '2', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200111')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('7','10', '12', '10', '2', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200111')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('8','11', '8', '3', '1', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '0022200233')
);

INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('9','22', '13', '12', '4', '0',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '0022200233')
);


INSERT INTO STATYSTYKIZAWODNIKA_TAB (ID_STATYSTYK, PUNKTY, ASYSTY, ZBIORKI, PRZECHWYTY, BLOKI, ZAWODNIK_REF, MECZ_REF) VALUES ('10','28', '9', '11', '2', '2',
(SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029'),
(SELECT REF(m) FROM mecz_tab m WHERE m.id_meczu = '22200222')
);

-- -------------------------------------------------------------------------------
-- POLECENIA:   5 X UPDATE  DO WSZYSTKICH TABEL                                               
-- -------------------------------------------------------------------------------


UPDATE mecz_tab SET statystyki_zawodnikow = STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '8'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '9')) WHERE id_meczu = '22200233';
UPDATE mecz_tab SET statystyki_zawodnikow = STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '1'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '2')) WHERE id_meczu = '22200170';
UPDATE mecz_tab SET statystyki_zawodnikow = STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '3'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '4')) WHERE id_meczu = '22200311';
UPDATE mecz_tab SET statystyki_zawodnikow = STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '7'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '6')) WHERE id_meczu = '22200111';
UPDATE mecz_tab SET statystyki_zawodnikow = STATYSTYKI_ZAWODNIKA_COL((SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '5'), (SELECT REF(s) FROM STATYSTYKIZAWODNIKA_tab s WHERE s.id_statystyk = '10')) WHERE id_meczu = '22200222';
UPDATE klub_tab SET sklad = ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939')) WHERE id_klubu = '10';
UPDATE klub_tab SET sklad = ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565')) WHERE id_klubu = '20';
UPDATE klub_tab SET sklad = ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1628369')) WHERE id_klubu = '2';
UPDATE klub_tab SET sklad = ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')) WHERE id_klubu = '7';
UPDATE klub_tab SET sklad = ZAWODNIK_SKLAD_VARRAY((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '203507')) WHERE id_klubu = '17';
UPDATE manager_tab SET zawodnicy_manager = ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201939')) WHERE id_managera = '1';
UPDATE manager_tab SET zawodnicy_manager = ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '201565')) WHERE id_managera = '2';
UPDATE manager_tab SET zawodnicy_manager = ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1628369')) WHERE id_managera = '3';
UPDATE manager_tab SET zawodnicy_manager = ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '1629029')) WHERE id_managera = '4';
UPDATE manager_tab SET zawodnicy_manager = ZAWODNIK_COL((SELECT REF(z) FROM zawodnik_tab z WHERE z.id_zawodnika = '203507')) WHERE id_managera = '5';
UPDATE zawodnik_tab SET mecze_zawodnik = MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200233'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200222')) WHERE id_zawodnika = '201939';
UPDATE zawodnik_tab SET mecze_zawodnik = MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200233'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200111')) WHERE id_zawodnika = '201565';
UPDATE zawodnik_tab SET mecze_zawodnik = MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200170')) WHERE id_zawodnika = '1628369';
UPDATE zawodnik_tab SET mecze_zawodnik = MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200170'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200311'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200222'), (SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200111')) WHERE id_zawodnika = '1629029';
UPDATE zawodnik_tab SET mecze_zawodnik = MECZE_COL((SELECT REF(m) FROM MECZ_TAB m WHERE m.ID_MECZU = '22200311')) WHERE id_zawodnika = '203507';
UPDATE zawodnik_tab SET kontuzje = KONTUZJE_COL(KONTUZJE_OBJ(2,'Skrecenie prawej kostki'), KONTUZJE_OBJ(1,'Skrecenie lewej kostki'));
UPDATE wlasciciel_tab SET id_wlasciciela = 6 where id_wlasciciela = 1;
UPDATE wlasciciel_tab SET id_wlasciciela = 7 where id_wlasciciela = 2;
UPDATE wlasciciel_tab SET id_wlasciciela = 8 where id_wlasciciela = 3;
UPDATE wlasciciel_tab SET id_wlasciciela = 9 where id_wlasciciela = 4;
UPDATE wlasciciel_tab SET id_wlasciciela = 10 where id_wlasciciela = 5;
UPDATE statystykizawodnika_tab SET bloki = 3 where deref(zawodnik_ref).id_zawodnika = 201939 and deref(mecz_ref).id_meczu = 22200222;
UPDATE statystykizawodnika_tab SET asysty = 3 where deref(zawodnik_ref).id_zawodnika = 1628369 and deref(mecz_ref).id_meczu = 22200170;
UPDATE statystykizawodnika_tab SET zbiorki = 3 where deref(zawodnik_ref).id_zawodnika = 203507 and deref(mecz_ref).id_meczu = 22200311;
UPDATE statystykizawodnika_tab SET przechwyty = 3 where deref(zawodnik_ref).id_zawodnika = 1629029 and deref(mecz_ref).id_meczu = 22200222;
UPDATE statystykizawodnika_tab SET bloki = 3 where deref(zawodnik_ref).id_zawodnika = 201565 and deref(mecz_ref).id_meczu = 22200233;
UPDATE kontuzje_tab SET id_kontuzji = 6 where id_kontuzji = 1;
UPDATE kontuzje_tab SET id_kontuzji = 7 where id_kontuzji = 2;
UPDATE kontuzje_tab SET id_kontuzji = 8 where id_kontuzji = 3;
UPDATE kontuzje_tab SET id_kontuzji = 9 where id_kontuzji = 4;
UPDATE kontuzje_tab SET id_kontuzji = 10 where id_kontuzji = 5;
UPDATE glowny_sedzia_tab SET id_sedziego = 6 where id_sedziego = 1;
UPDATE glowny_sedzia_tab SET id_sedziego = 7 where id_sedziego = 2;
UPDATE glowny_sedzia_tab SET id_sedziego = 8 where id_sedziego = 3;
UPDATE glowny_sedzia_tab SET id_sedziego = 9 where id_sedziego = 4;
UPDATE glowny_sedzia_tab SET id_sedziego = 10 where id_sedziego = 5;

-- -------------------------------------------------------------------------------
-- POLECENIA:   10 X SELECT                                                     
-- -------------------------------------------------------------------------------

SELECT (m.imie || ' ' || m.nazwisko) as Manager, m.czas_na_rynku()
FROM manager_tab m
WHERE m.id_managera = 2;

SELECT (z.imie || ' ' || z.nazwisko) AS zawodnik, LISTAGG((deref(value(k)).imie || ' ' || deref(value(k)).nazwisko), ', ') AS Zawodnicy
FROM manager_tab z, TABLE(z.zawodnicy_manager) k
WHERE z.id_managera = 1
GROUP BY z.imie, z.nazwisko;


SELECT a.nazwa_klubu,
       a.id_klubu,
       DEREF(VALUE(s)).imie AS Imie
FROM   klub_tab a
       CROSS JOIN TABLE( a.sklad ) s;

SELECT m.id_meczu,
DEREF(VALUE(z)).imie || ' ' || DEREF(VALUE(z)).nazwisko AS Zawodnik,
DEREF(VALUE(s)).punkty as Punkty,
DEREF(VALUE(s)).asysty as Asysty,
DEREF(VALUE(s)).zbiorki as Zbiorki
FROM mecz_tab m, statystykizawodnika_tab st
CROSS JOIN TABLE(m.zawodnicy_mecz) z
CROSS JOIN TABLE(m.statystyki_zawodnikow) s where st.id_statystyk = '4' and deref(value(s)).id_statystyk = '4' and deref(value(z)).id_zawodnika = deref(zawodnik_ref).id_zawodnika;

SELECT (z.imie || ' ' || z.nazwisko) as Manager, (DEREF(VALUE(k)).imie || ' ' || DEREF(VALUE(k)).nazwisko) as Zawodnik from manager_tab z CROSS JOIN TABLE(z.zawodnicy_manager) k;


SELECT m.id_meczu,
DEREF(VALUE(z)).imie || ' ' || DEREF(VALUE(z)).nazwisko AS Zawodnik,
DEREF(VALUE(s)).punkty as Punkty,
DEREF(VALUE(s)).asysty as Asysty,
DEREF(VALUE(s)).zbiorki as Zbiorki
FROM mecz_tab m, statystykizawodnika_tab st
CROSS JOIN TABLE(m.zawodnicy_mecz) z
CROSS JOIN TABLE(m.statystyki_zawodnikow) s where st.id_statystyk = deref(value(s)).id_statystyk and deref(value(z)).id_zawodnika = deref(zawodnik_ref).id_zawodnika;

SELECT k.id_klubu, k.nazwa_klubu,
(DEREF(k.wlasciciel_klubu).imie || ' ' || DEREF(k.wlasciciel_klubu).nazwisko) AS Wlasciciel
FROM klub_tab k;

SELECT mecz_obj.dzien_mecz(TO_DATE('2022-11-25','yyyy-mm-dd')) FROM DUAL;

SELECT mecz_obj.dzien_mecz(TO_DATE('2022-11-27','yyyy-mm-dd')) FROM DUAL;

SELECT mecz_obj.dzien_mecz(TO_DATE('2022-11-26','yyyy-mm-dd')) FROM DUAL;

SELECT mecz_obj.dzien_mecz(TO_DATE('2023-11-27','yyyy-mm-dd')) FROM DUAL;

select k.nazwa_klubu, k.data_zalozenia, k.wiek_klubu() as Wiek_klubu from klub_tab k CROSS JOIN TABLE(k.sklad) z;

SELECT k.nazwa_klubu, 
       LISTAGG((deref(value(s)).imie || ' ' ||deref(value(s)).nazwisko), ', ') WITHIN GROUP (ORDER BY deref(value(s)).imie) as sklad_klubu
FROM klub_tab k, 
     TABLE(k.sklad) s
GROUP BY k.nazwa_klubu;

SELECT z.imie || ' ' || z.nazwisko AS zawodnik, LISTAGG(k.opis, ', ') AS kontuzje
FROM zawodnik_tab z, TABLE(z.kontuzje) k, mecz_tab m, table(m.zawodnicy_mecz) zm
WHERE m.id_meczu = 22200222
AND  deref(value(zm)).id_zawodnika = z.id_zawodnika
GROUP BY z.imie, z.nazwisko;


-- -------------------------------------------------------------------------------
-- POLECENIA:   5 X DELETE  DO WSZYSTKICH TABEL                                               
-- -------------------------------------------------------------------------------


DELETE from glowny_sedzia_tab where id_sedziego = 6;
DELETE from glowny_sedzia_tab where imie = 'Pat';
DELETE from glowny_sedzia_tab where nazwisko like '%a%';
DELETE from glowny_sedzia_tab where id_sedziego = 9;
DELETE from glowny_sedzia_tab where kraj_pochodzenia = 'Stany Zjednoczone Ameryki';
DELETE from kontuzje_tab where id_kontuzji = 6;
DELETE from kontuzje_tab where id_kontuzji = 7;
DELETE from kontuzje_tab where id_kontuzji = 8;
DELETE from kontuzje_tab where id_kontuzji = 9;
DELETE from kontuzje_tab where id_kontuzji = 10;
DELETE from wlasciciel_tab where id_wlasciciela = 6;
DELETE from wlasciciel_tab where imie = 'Wyc';
DELETE from wlasciciel_tab where id_wlasciciela = 9;
DELETE from wlasciciel_tab where kraj_pochodzenia = 'Stany Zjednoczone Ameryki';
DELETE from wlasciciel_tab where nazwisko like '%a%';
DELETE from manager_tab where id_managera = 1;
DELETE FROM manager_tab WHERE id_managera IN (SELECT id_managera FROM manager_tab m, TABLE(m.zawodnicy_manager) z WHERE deref(value(z)).id_zawodnika = 1628369);
DELETE from manager_tab WHERE id_managera IN (SELECT id_managera FROM manager_tab m, TABLE(m.zawodnicy_manager) z WHERE deref(value(z)).waga = 95);
DELETE from manager_tab WHERE id_managera IN (SELECT id_managera FROM manager_tab m, TABLE(m.zawodnicy_manager) z WHERE deref(value(z)).kraj_pochodzenia = 'Grecja');
DELETE from manager_tab WHERE data_urodzenia <= '2010-04-01';
DELETE from klub_tab WHERE id_klubu IN (SELECT id_klubu FROM klub_tab m, TABLE(m.sklad) z WHERE deref(value(z)).id_zawodnika = 201939);
DELETE from klub_tab WHERE id_klubu IN (SELECT id_klubu FROM klub_tab m, TABLE(m.sklad) z WHERE deref(value(z)).rok_draftu = 2008);
DELETE from klub_tab WHERE id_klubu IN (SELECT id_klubu FROM klub_tab m, TABLE(m.sklad) z WHERE (deref(value(z)).kraj_pochodzenia = 'Stany Zjednoczone Ameryki') and (deref(value(z)).data_urodzenia <= '1998-04-01'));
DELETE from klub_tab WHERE id_klubu = 7;
DELETE from klub_tab WHERE id_klubu IN (SELECT id_klubu FROM klub_tab m WHERE deref(wlasciciel_klubu).imie = 'Marc');
DELETE from mecz_tab WHERE id_meczu = 22200233;
DELETE from mecz_tab WHERE id_meczu IN (SELECT id_meczu from mecz_tab m WHERE m.data_meczu <= '2010-04-01');
DELETE from mecz_tab WHERE id_meczu IN (SELECT id_meczu from mecz_tab m WHERE deref(goscie).nazwa_klubu = 'Golden State Warriors');
DELETE from mecz_tab WHERE id_meczu IN (SELECT id_meczu from mecz_tab m WHERE deref(gospodarze).nazwa_klubu = 'Golden State Warriors');
DELETE from mecz_tab WHERE id_meczu IN (SELECT id_meczu from mecz_tab m WHERE deref(glowny_sedzia).imie = 'Pat');
DELETE FROM statystykizawodnika_tab WHERE id_statystyk IN (SELECT id_statystyk from statystykizawodnika_tab where deref(zawodnik_ref).id_zawodnika = 201939 and deref(mecz_ref).id_meczu = 22200222);
DELETE FROM statystykizawodnika_tab WHERE id_statystyk IN (SELECT id_statystyk from statystykizawodnika_tab where deref(zawodnik_ref).id_zawodnika = 1628369 and deref(mecz_ref).id_meczu = 22200170);
DELETE FROM statystykizawodnika_tab WHERE id_statystyk IN (SELECT id_statystyk from statystykizawodnika_tab where deref(zawodnik_ref).id_zawodnika = 203507 and deref(mecz_ref).id_meczu = 22200311);
DELETE FROM statystykizawodnika_tab WHERE id_statystyk IN (SELECT id_statystyk from statystykizawodnika_tab where deref(zawodnik_ref).id_zawodnika = 1629029 and deref(mecz_ref).id_meczu = 22200222);
DELETE FROM statystykizawodnika_tab WHERE id_statystyk = 7;
DELETE FROM zawodnik_tab WHERE id_zawodnika IN (SELECT id_zawodnika from zawodnik_tab z, table(z.kontuzje) k where value(k).opis = 'Skrecenie prawej kostki' and z.imie = 'Jason');
DELETE FROM zawodnik_tab WHERE id_zawodnika IN (SELECT id_zawodnika from zawodnik_tab where id_zawodnika = 1628369);
DELETE FROM zawodnik_tab WHERE id_zawodnika IN (SELECT id_zawodnika from zawodnik_tab where waga = 95);
DELETE FROM zawodnik_tab WHERE id_zawodnika IN (SELECT id_zawodnika from zawodnik_tab where kraj_pochodzenia = 'Grecja');
DELETE FROM zawodnik_tab WHERE id_zawodnika IN (SELECT id_zawodnika from zawodnik_tab where data_urodzenia <= '2001-04-01');



-- -------------------------------------------------------------------------------
-- USUWANIE STRUKTURY BAZY DANYCH     [DROP TABLE, DROP TYPE]                                       
-- -------------------------------------------------------------------------------



DROP TABLE GLOWNY_SEDZIA_TAB CASCADE CONSTRAINTS;
DROP TABLE KLUB_TAB CASCADE CONSTRAINTS;
DROP TABLE KONTUZJE_TAB CASCADE CONSTRAINTS;
DROP TABLE MANAGER_TAB CASCADE CONSTRAINTS;
DROP TABLE MECZ_TAB CASCADE CONSTRAINTS;
DROP TABLE STATYSTYKIZAWODNIKA_TAB CASCADE CONSTRAINTS;
DROP TABLE WLASCICIEL_TAB CASCADE CONSTRAINTS;
DROP TABLE ZAWODNIK_TAB CASCADE CONSTRAINTS;


DROP TYPE GLOWNY_SEDZIA_OBJ FORCE;
DROP TYPE KLUB_OBJ FORCE;
DROP TYPE KONTUZJE_OBJ FORCE;
DROP TYPE MANAGER_OBJ FORCE;
DROP TYPE MECZ_OBJ FORCE;
DROP TYPE OSOBA_OBJ FORCE;
DROP TYPE STATYSTYKIZAWODNIKA_OBJ FORCE;
DROP TYPE STATYSTYKI_OBJ FORCE;
DROP TYPE WLASCICIEL_OBJ FORCE;
DROP TYPE ZAWODNIK_OBJ FORCE;
DROP TYPE KONTUZJE_COL FORCE;
DROP TYPE MECZE_COL FORCE;
DROP TYPE STATYSTYKI_ZAWODNIKA_COL FORCE;
DROP TYPE WLASCICIEL_COL FORCE;
DROP TYPE ZAWODNIK_COL FORCE;
DROP TYPE ZAWODNIK_SKLAD_VARRAY FORCE;
DROP TYPE ZAWODNIK_VARRAY FORCE;
