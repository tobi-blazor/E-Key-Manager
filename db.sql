-- Kassenbuch

-- auto-generated definition
create table "Ausgaben"
(
  "Id"                text                     not null
    constraint "PK_Ausgaben"
      primary key,
  "AusgabenKategorie" integer                  not null,
  "Bezahlmethode"     integer                  not null,
  "EmpfängerName"     text    default ''::text not null,
  "EmpfängerIban"     text,
  "BeschlussDatum"    timestamp with time zone,
  "Titel"             text                     not null,
  "Betrag"            numeric                  not null,
  "Konto"             integer                  not null,
  "Notizen"           text,
  "ErstellDatum"      timestamp with time zone not null,
  "AusführDatum"      timestamp with time zone not null,
  "Trinkgeld"         numeric default 0.0      not null
);

alter table "Ausgaben"
  owner to kasse_user;



-- auto-generated definition
create table "Einnahmen"
(
  "Id"                text                     not null
    constraint "PK_Einnahmen"
      primary key,
  "EinnahmeKategorie" integer                  not null,
  "Titel"             text                     not null,
  "Betrag"            numeric                  not null,
  "Konto"             integer                  not null,
  "Notizen"           text,
  "ErstellDatum"      timestamp with time zone not null,
  "AusführDatum"      timestamp with time zone not null,
  "EinzahlName"       text default ''::text    not null
);

alter table "Einnahmen"
  owner to kasse_user;

-- auto-generated definition
create table "Anhänge"
(
  "Id"             uuid   not null
    constraint "PK_Anhänge"
      primary key,
  "Datei"          bytea  not null,
  "Dateiname"      text   not null,
  "DateiExtension" text   not null,
  "DateiSize"      bigint not null,
  "AusgabeId"      text
    constraint "FK_Anhänge_Ausgaben_AusgabeId"
      references "Ausgaben",
  "EinnahmeId"     text
    constraint "FK_Anhänge_Einnahmen_EinnahmeId"
      references "Einnahmen"
);

alter table "Anhänge"
  owner to kasse_user;

create index "IX_Anhänge_AusgabeId"
  on "Anhänge" ("AusgabeId");

create index "IX_Anhänge_EinnahmeId"
  on "Anhänge" ("EinnahmeId");

-- Ekey-manager
DROP TABLE IF EXISTS ekey CASCADE ;
DROP TABLE IF EXISTS student CASCADE ;
DROP TABLE IF EXISTS ausleihe CASCADE ;

CREATE TABLE ekey(
                   ekeyid TEXT PRIMARY KEY,
                   besitzer TEXT CHECK(besitzer = ANY('{FSR,Student,verloren}')) NOT NULL,
                   zustand TEXT CHECK(zustand = ANY('{defekt,gesperrt,funktioniert}')) NOT NULL,
                   berechtigung TEXT CHECK ( berechtigung=ANY('{STUD,FSRF,FSR}') ) NOT NULL,
                   notiz TEXT
);

CREATE TABLE student(
                      matrnr INTEGER PRIMARY KEY,
                      vorname TEXT NOT NULL ,
                      nachname TEXT NOT NULL,
                      email TEXT NOT NULL
);

CREATE TABLE ausleihe(
                       ausleihnr INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                       matrnr INTEGER,
                       ekeyid TEXT,
                       beginn timestamp NOT NULL,
                       ende timestamp DEFAULT NULL,
                       notiz TEXT,
                       letzte_rückmeldung DATE,
                       hat_studienbescheinigung BOOLEAN,
                       pfand INTEGER DEFAULT 25,
                       UNIQUE(ekeyid,ende),
                       FOREIGN KEY (matrnr) REFERENCES student(matrnr),
                       FOREIGN KEY (ekeyid) REFERENCES ekey(ekeyid)

);



/* TODO
CREATE TABLE warteliste(
                         Mail varchar(90) PRIMARY KEY,
                         RegisterDate date
);
*/

--
-- Funktionen/Trigger
--

--Wenn eine ausleihe eingefügt/beendet wird, wird der besitzer gewechselt und in kasse eingefügt
CREATE OR REPLACE FUNCTION switchschluesselbesitzer() RETURNS TRIGGER AS $$
DECLARE
    currbesitz TEXT;
    keyid TEXT ; -- Access the first argument passed to the trigger
    pfand INTEGER;
BEGIN
    keyid := NEW.ekeyid;
    pfand := NEW.pfand;
    SELECT besitzer INTO currbesitz FROM ekey WHERE ekey.ekeyid = keyid;


    -- Corrected CASE statement syntax for PL/pgSQL
    IF currbesitz = 'FSR' THEN
        --25 von student nehmen
        currbesitz := 'Student';
        INSERT INTO "Einnahmen" ("EinnahmeKategorie", "Titel","Betrag","Konto", "Notizen", "ErstellDatum", "AusführDatum", "EinzahlName") VALUES (4, 'E-Key Ausleihe von: ' || NEW.matrnr, pfand, 0, 'Ekey wurde ausgeliehen', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NEW.ausleihnr);
    ELSE
        -- Handle other cases or do nothing
    END IF;

    UPDATE ekey SET besitzer = currbesitz WHERE ekey.ekeyid = keyid;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER ausleihe AFTER INSERT ON ausleihe
FOR EACH ROW EXECUTE PROCEDURE switchschluesselbesitzer();

-- wenn ekey gesperrt wird pfand zurück nehmen

-- key zurück geben
CREATE OR REPLACE FUNCTION keyzurueckgeben(keyid TEXT) RETURNS TEXT AS $$
DECLARE
    pfandwert INTEGER;
    currbesitz TEXT;
    status TEXT;
    oldausleihid INTEGER;
    oldmatrnr INTEGER;
BEGIN
    SELECT besitzer INTO currbesitz FROM ekey WHERE ekey.ekeyid = keyid;
    SELECT zustand INTO status FROM ekey WHERE ekey.ekeyid = keyid;
    SELECT pfand INTO pfandwert FROM ausleihe where ekeyid=keyid AND ende IS NULL;
    SELECT ausleihnr INTO oldausleihid FROM ausleihe where ekeyid=keyid AND ende IS NULL;
    SELECT ausleihe.matrnr INTO oldmatrnr FROM ausleihe where ekeyid=keyid AND ende IS NULL;

    IF currbesitz = 'Student' THEN
        --wird an FSR zurück gegeben
        IF status = 'defekt' OR status='funktioniert' THEN
            -- Student ist für rückzahlung freigegeben
            INSERT INTO "Ausgaben"("AusgabenKategorie", "Titel","Betrag","Konto", "Notizen", "ErstellDatum", "AusführDatum", "EmpfängerName", "Bezahlmethode") VALUES (15, 'E-Key Ausleihe von: ' || oldmatrnr , pfandwert, 0, 'Ekey wurde zurückgegeben', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, oldausleihid, 0 );
        END IF;
    ELSE
    END IF;

    UPDATE ekey SET besitzer='FSR' WHERE ekeyid=keyid;
    UPDATE ausleihe SET ende =CURRENT_TIMESTAMP WHERE ekeyid=keyid AND ende IS NULL;
    RETURN keyid;
END;
$$ LANGUAGE plpgsql;


-- key sperren, Pfand einbehalten
CREATE OR REPLACE FUNCTION keysperren(keyid TEXT) RETURNS TEXT AS $$
DECLARE
    pfandwert INTEGER;
    currbesitz TEXT;
    aleihnr INTEGER;
    oldmatrnr INTEGER;
BEGIN
    SELECT besitzer INTO currbesitz FROM ekey WHERE ekey.ekeyid = keyid;


    IF currbesitz !='FSR' THEN
        SELECT pfand INTO pfandwert FROM ausleihe where ekeyid=keyid AND ende IS NULL;
        SELECT ausleihnr INTO aleihnr FROM ausleihe where ekeyid=keyid AND ende IS NULL;
        SELECT matrnr INTO oldmatrnr FROM ausleihe where ekeyid=keyid AND ende IS NULL;
        INSERT INTO "Ausgaben" ("AusgabenKategorie", "Titel","Betrag","Konto", "Notizen", "ErstellDatum", "AusführDatum", "EmpfängerName", "Bezahlmethode") VALUES (15, 'E-Key Ausleihe von: ' || oldmatrnr , 0, 0, 'Pfand wurde einbehalten', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, aleihnr, 0 );
        UPDATE ausleihe SET ende=CURRENT_TIMESTAMP WHERE ekeyid=keyid AND ende IS NULL;
    END IF;

    UPDATE ekey SET zustand='gesperrt' WHERE ekeyid=keyid;
    RETURN keyid;
END;
$$ LANGUAGE plpgsql;

-- Key war gesperrt und wird zurück genommen
CREATE OR REPLACE FUNCTION keyzurueck(keyid TEXT) RETURNS TEXT AS $$
DECLARE
    currzustand TEXT;
BEGIN
    SELECT zustand INTO currzustand FROM ekey WHERE ekey.ekeyid = keyid;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Key mit ID % nicht gefunden', keyid;
    END IF;

    IF currzustand ='gesperrt' THEN
        UPDATE ekey SET besitzer='FSR' WHERE ekeyid=keyid;
    ELSE
        RAISE EXCEPTION 'Key mit ID % ist nicht gesperrt', keyid;
    END IF;

    RETURN keyid;
END;
$$ LANGUAGE plpgsql;


-- Key wird entsperrt
CREATE OR REPLACE FUNCTION keyentsperren(keyid TEXT, note TEXT) RETURNS TEXT AS $$
DECLARE
  currzustand TEXT;
  currbesitzer TEXT;
BEGIN
  SELECT zustand INTO currzustand FROM ekey WHERE ekey.ekeyid = keyid;
  SELECT besitzer INTO currbesitzer FROM ekey WHERE ekey.ekeyid = keyid;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Key mit ID % nicht gefunden', keyid;
  END IF;

  IF currzustand ='gesperrt' THEN
    IF currbesitzer='FSR' THEN
      UPDATE ekey SET zustand='funktioniert', notiz=note WHERE ekeyid=keyid;
    ELSE
      RAISE EXCEPTION 'Key mit ID % ist nicht im FSR Bestand', keyid;
    END IF;
  ELSE
    RAISE EXCEPTION 'Key mit ID % ist nicht gesperrt', keyid;
  END IF;

  RETURN keyid;
END;
$$ LANGUAGE plpgsql;


-- Beispiel inserts
INSERT INTO ekey (ekeyID, besitzer, zustand, berechtigung, notiz) VALUES ('24CHRXXXX', 'Student', 'funktioniert', 'STUD', NULL), ('35CHRXXXX', 'FSR', 'defekt', 'FSRF', NULL);

INSERT INTO student (matrnr, vorname, nachname, email) VALUES (7200000,'ABC', 'DEF', 'ABC.DEF000@stud.fh-dortmund.de'), (7220300,'ahoi', 'piraten', 'omgeinemail.DEF000@stud.fh-dortmund.de');

INSERT INTO ausleihe (matrnr, ekeyid, beginn, ende, notiz, letzte_rückmeldung, hat_studienbescheinigung) VALUES (7200000,'35CHRXXXX',CURRENT_TIMESTAMP, null, null, null, true), (7220300,'24CHRXXXX',CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'hat rumgezickt', current_timestamp, false);

SELECT * FROM Ausleihe NATURAL JOIN student NATURAL JOIN ekey;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ekey_manager;
