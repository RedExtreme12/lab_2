DROP TABLE owner_book_info;
DROP TABLE invoice_details;
DROP TABLE owner_invoice;
DROP TABLE book CASCADE CONSTRAINTS;
DROP TABLE author CASCADE CONSTRAINTS;
DROP TABLE publishing_house CASCADE CONSTRAINTS;
DROP TABLE seller;
DROP TABLE stock;
DROP TABLE other;
DROP TABLE owner CASCADE CONSTRAINTS;
DROP TABLE invoice CASCADE CONSTRAINTS;

DROP SEQUENCE book_sequence; 
DROP SEQUENCE author_sequence; 
DROP SEQUENCE publishing_house_sequence; 


CREATE SEQUENCE book_sequence
    MINVALUE 1
    START WITH 1
    INCREMENT BY 1
    CACHE 20;
    
CREATE SEQUENCE author_sequence
    MINVALUE 1
    START WITH 1
    INCREMENT BY 1
    CACHE 20;
   
CREATE SEQUENCE publishing_house_sequence
    MINVALUE 1
    START WITH 1
    INCREMENT BY 1
    CACHE 20;



CREATE TABLE author (
    id           INTEGER,
    fio          VARCHAR2(30 CHAR) NOT NULL,
    birth_date   DATE NOT NULL
);

ALTER TABLE author ADD CONSTRAINT author_pk PRIMARY KEY ( id );



CREATE TABLE book (
    id           INTEGER,
    name          VARCHAR2(15 CHAR) NOT NULL,
    publishing_house_id  INTEGER NOT NULL,
    author_id    INTEGER NOT NULL
);


CREATE INDEX book_author on book(author_id);
CREATE INDEX book_publishing_house on book(publishing_house_id);
ALTER TABLE book ADD CONSTRAINT book_pk PRIMARY KEY ( id );

CREATE TABLE invoice (
    id                      INTEGER,
    "date"                  DATE NOT NULL,
    operation_description   VARCHAR2(20 CHAR) NOT NULL
    CHECK (operation_description in ('seller-seller','seller-stock','stock-seller')),
    buying_price            NUMBER NOT NULL CHECK (buying_price >= 0),
    selling_price           NUMBER NOT NULL CHECK (selling_price >= 0)
);

ALTER TABLE invoice ADD CONSTRAINT invoice_pk PRIMARY KEY ( id );

CREATE TABLE invoice_details (
    invoice_id   INTEGER,
    book_id      INTEGER,
    amount       INTEGER NOT NULL CHECK (amount > 0)
);

ALTER TABLE invoice_details ADD CONSTRAINT invoice_details_id PRIMARY KEY ( invoice_id,
                                                                           book_id );

CREATE TABLE other (
    id   INTEGER
);

ALTER TABLE other ADD CONSTRAINT other_pk PRIMARY KEY ( id );

CREATE TABLE owner (
    id        INTEGER,
    address   VARCHAR2(25 CHAR) NOT NULL
);

ALTER TABLE owner ADD CONSTRAINT owner_pk PRIMARY KEY ( id );

CREATE TABLE owner_book_info (
    owner_id   INTEGER,
    book_id    INTEGER,
    amount     INTEGER NOT NULL
);

ALTER TABLE owner_book_info ADD CONSTRAINT owner_book_info_od PRIMARY KEY ( owner_id,
                                                                           book_id );

CREATE TABLE owner_invoice (
    owner_id     INTEGER,
    invoice_id   INTEGER
);

ALTER TABLE owner_invoice ADD CONSTRAINT owner_invoice_id PRIMARY KEY ( owner_id,
                                                                         invoice_id );

CREATE TABLE publishing_house (
    id        INTEGER,
    name      VARCHAR2(15 CHAR) NOT NULL,
    address   VARCHAR2(25 CHAR) NOT NULL
);

ALTER TABLE publishing_house ADD CONSTRAINT publishing_house_pk PRIMARY KEY ( id );

CREATE TABLE seller (
    id               INTEGER,
    fio              VARCHAR2(30 CHAR) NOT NULL,
    seller_percent   NUMBER NOT NULL CHECK (seller_percent >= 0)
);

ALTER TABLE seller ADD CONSTRAINT seller_pk PRIMARY KEY ( id );

CREATE TABLE stock (
    id             INTEGER,
    director_fio   VARCHAR2(30 CHAR) NOT NULL
);

ALTER TABLE stock ADD CONSTRAINT stock_pk PRIMARY KEY ( id );

ALTER TABLE book
    ADD CONSTRAINT book_author_fk FOREIGN KEY ( author_id )
        REFERENCES author ( id )
        ON DELETE CASCADE;

ALTER TABLE book
    ADD CONSTRAINT book_publishing_house_fk FOREIGN KEY ( publishing_house_id )
        REFERENCES publishing_house ( id )
        ON DELETE CASCADE;

ALTER TABLE invoice_details
    ADD CONSTRAINT relation_4_book_fk FOREIGN KEY ( book_id )
        REFERENCES book ( id )
        ON DELETE CASCADE;

ALTER TABLE invoice_details
    ADD CONSTRAINT relation_4_invoice_fk FOREIGN KEY ( invoice_id )
        REFERENCES invoice ( id )
        ON DELETE CASCADE;

ALTER TABLE owner_invoice
    ADD CONSTRAINT relation_6_invoice_fk FOREIGN KEY ( invoice_id )
        REFERENCES invoice ( id )
        ON DELETE CASCADE;

ALTER TABLE owner_invoice
    ADD CONSTRAINT relation_6_owner_fk FOREIGN KEY ( owner_id )
        REFERENCES owner ( id )
        ON DELETE CASCADE;

ALTER TABLE owner_book_info
    ADD CONSTRAINT relation_8_book_fk FOREIGN KEY ( book_id )
        REFERENCES book ( id )
        ON DELETE CASCADE;

ALTER TABLE owner_book_info
    ADD CONSTRAINT relation_8_owner_fk FOREIGN KEY ( owner_id )
        REFERENCES owner ( id )
        ON DELETE CASCADE;

ALTER TABLE other
    ADD CONSTRAINT other_owner_fk FOREIGN KEY ( id )
        REFERENCES owner ( id )
        ON DELETE CASCADE;

ALTER TABLE seller
    ADD CONSTRAINT seller_owner_fk FOREIGN KEY ( id )
        REFERENCES owner ( id )
        ON DELETE CASCADE;

ALTER TABLE stock
    ADD CONSTRAINT stock_owner_fk FOREIGN KEY ( id )
        REFERENCES owner ( id )
        ON DELETE CASCADE;

CREATE OR REPLACE TRIGGER fkntm_book BEFORE
    UPDATE OF publishing_house_id,author_id ON book
BEGIN
    raise_application_error(-20225,'Non Transferable FK constraint  on table BOOK is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_invoice_details BEFORE
    UPDATE OF invoice_id,book_id ON invoice_details
BEGIN
    raise_application_error(-20225,'Non Transferable FK constraint  on table INVOICE_DETAILS is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_owner_invoice BEFORE
    UPDATE OF owner_id,invoice_id ON owner_invoice
BEGIN
    raise_application_error(-20225,'Non Transferable FK constraint  on table OWNER_INVOICE is violated');
END;
/

CREATE OR REPLACE TRIGGER arc_fkarc_2_stock BEFORE
    INSERT OR UPDATE OF id ON stock
    FOR EACH ROW
DECLARE
    d   INTEGER;
BEGIN
    SELECT
        a.id
    INTO d
    FROM
        owner a
    WHERE
        a.id =:new.id;

    IF ( d IS NULL) THEN
        raise_application_error(-20223,'FK STOCK_OWNER_FK in Table STOCK violates Arc constraint on Table OWNER - discriminator column id doesn''t have value 1'
        );
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        NULL;
    WHEN OTHERS THEN
        RAISE;
END;
/

CREATE OR REPLACE TRIGGER arc_fkarc_2_other BEFORE
    INSERT OR UPDATE OF id ON other
    FOR EACH ROW
DECLARE
    d   INTEGER;
BEGIN
    SELECT
        a.id
    INTO d
    FROM
        owner a
    WHERE
        a.id =:new.id;

    IF ( d IS NULL ) THEN
        raise_application_error(-20223,'FK OTHER_OWNER_FK in Table OTHER violates Arc constraint on Table OWNER - discriminator column id doesn''t have value 3'
        );
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        NULL;
    WHEN OTHERS THEN
        RAISE;
END;
/

CREATE OR REPLACE TRIGGER arc_fkarc_2_seller BEFORE
    INSERT OR UPDATE OF id ON seller
    FOR EACH ROW
DECLARE
    d   INTEGER;
BEGIN
    SELECT
        a.id
    INTO d
    FROM
        owner a
    WHERE
        a.id =:new.id;

    IF ( d IS NULL) THEN
        raise_application_error(-20223,'FK SELLER_OWNER_FK in Table SELLER violates Arc constraint on Table OWNER - discriminator column id doesn''t have value 2'
        );
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        NULL;
    WHEN OTHERS THEN
        RAISE;
END;
/

CREATE OR REPLACE TRIGGER check_invoice_date
  BEFORE INSERT OR UPDATE ON invoice
  FOR EACH ROW
BEGIN
  IF( :new."date" < date '1900-01-01' or 
      :new."date" > sysdate )
  THEN
    RAISE_APPLICATION_ERROR( 
      -20001, 
      'Invoice date must be later than Jan 1, 1900 and earlier than today' );
  END IF;
END;
/

CREATE OR REPLACE TRIGGER check_birth_date
  BEFORE INSERT OR UPDATE ON author
  FOR EACH ROW
BEGIN
  IF( :new.birth_date < date '1900-01-01' or 
      :new.birth_date > sysdate )
  THEN
    RAISE_APPLICATION_ERROR( 
      -20001, 
      'Author date of birth must be later than Jan 1, 1900 and earlier than today' );
  END IF;
END;
/

CREATE OR REPLACE TRIGGER publishing_house_trigger
  BEFORE INSERT ON publishing_house FOR EACH ROW
  BEGIN
    :NEW.id := publishing_house_sequence.nextval;
  END;
/

CREATE OR REPLACE TRIGGER author_trigger
  BEFORE INSERT ON author FOR EACH ROW
  BEGIN
    :NEW.id := author_sequence.nextval;
  END;
/

CREATE OR REPLACE TRIGGER book_trigger
  BEFORE INSERT ON book FOR EACH ROW
  BEGIN
    :NEW.id := book_sequence.nextval;
  END;
/


ALTER TABLE publishing_house ADD head_publishing_house_id INTEGER;


INSERT INTO publishing_house (name, address) VALUES ('Pearson','190 High Holborn');
INSERT INTO publishing_house (name, address) VALUES ( 'Bertelsmann','LaPass');
INSERT INTO publishing_house (name, address)  VALUES ('Wiley','Donnahan');
INSERT INTO publishing_house (name, address) VALUES ( 'EKSMO-AST','Green');

INSERT INTO author (fio, birth_date) VALUES ('Михаил Афанасьевич Булгаков', TO_DATE('15-May-1991', 'DD-MON-YYYY'));
INSERT INTO author (fio, birth_date) VALUES ('Александр Сергеевич Пушкин', TO_DATE('06-Jun-1999', 'DD-MON-YYYY'));
INSERT INTO author (fio, birth_date) VALUES ('Федор Михайлович Достоевский', TO_DATE('11-Nov-1921', 'DD-MON-YYYY'));

INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Белая гвардия', 2, 1);
INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Собачье сердце', 1, 1);
INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Идиот', 4, 3);
INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Евгений Онегин', 3, 2);
INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Дубровский', 2, 2);
INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Бесы', 4, 3);
INSERT INTO book (name, publishing_house_id, author_id) VALUES ('Роковые яйца', 1, 1);

INSERT INTO OWNER VALUES (1, 'Minsk');
INSERT INTO OWNER VALUES (2, 'Kiev');
INSERT INTO OWNER VALUES (3, 'Bialystok');
INSERT INTO OWNER VALUES (4, 'Calefornia');
INSERT INTO OWNER VALUES (5, 'New York');
INSERT INTO OWNER VALUES (6, 'Praga');

INSERT INTO SELLER VALUES (1, 'Ivan Ivanov', 12);
INSERT INTO SELLER VALUES (2, 'Ivan Petrov', 25);
INSERT INTO SELLER VALUES (6, 'Lyk Mert', 50);

INSERT INTO STOCK VALUES (3, 'Lury Dry');
INSERT INTO STOCK VALUES (4, 'Ema Qwa');
INSERT INTO STOCK VALUES (5, 'Liza Stel');

INSERT INTO OWNER_BOOK_INFO VALUES (1,1, 10);
INSERT INTO OWNER_BOOK_INFO VALUES (3,1, 24);
INSERT INTO OWNER_BOOK_INFO VALUES (5,3, 2);
INSERT INTO OWNER_BOOK_INFO VALUES (6,4, 12);
INSERT INTO OWNER_BOOK_INFO VALUES (2,5, 1);
INSERT INTO OWNER_BOOK_INFO VALUES (2,2, 20);


INSERT INTO INVOICE VALUES (1, SYSDATE, 'seller-stock', 25, 26);
INSERT INTO INVOICE VALUES (2, SYSDATE, 'seller-seller', 14, 21);
INSERT INTO INVOICE VALUES (3, SYSDATE, 'stock-seller', 34, 10);
INSERT INTO INVOICE VALUES (4, SYSDATE, 'seller-stock', 10, 20);
INSERT INTO INVOICE VALUES (5, SYSDATE, 'seller-seller', 62, 31);
INSERT INTO INVOICE VALUES (6, SYSDATE, 'stock-seller', 5, 69);
INSERT INTO INVOICE VALUES (7, SYSDATE, 'seller-stock', 14, 14);
INSERT INTO INVOICE VALUES (8, SYSDATE, 'seller-seller', 100, 2);
INSERT INTO INVOICE VALUES (9, SYSDATE, 'stock-seller', 2, 35);
INSERT INTO INVOICE VALUES (10, SYSDATE, 'seller-stock', 10, 10);
INSERT INTO INVOICE VALUES (11, SYSDATE, 'seller-seller', 11, 12);
INSERT INTO INVOICE VALUES (12, SYSDATE, 'stock-seller', 13, 14);

INSERT INTO OWNER_INVOICE VALUES (1,1);
INSERT INTO OWNER_INVOICE VALUES (3,1);
INSERT INTO OWNER_INVOICE VALUES (2,2);
INSERT INTO OWNER_INVOICE VALUES (6,2);
INSERT INTO OWNER_INVOICE VALUES (3,3);
INSERT INTO OWNER_INVOICE VALUES (6,3);
INSERT INTO OWNER_INVOICE VALUES (2,4);
INSERT INTO OWNER_INVOICE VALUES (4,4);
INSERT INTO OWNER_INVOICE VALUES (6,5);
INSERT INTO OWNER_INVOICE VALUES (1,5);
INSERT INTO OWNER_INVOICE VALUES (3,6);
INSERT INTO OWNER_INVOICE VALUES (6,6);
INSERT INTO OWNER_INVOICE VALUES (1,7);
INSERT INTO OWNER_INVOICE VALUES (4,7);
INSERT INTO OWNER_INVOICE VALUES (6,8);
INSERT INTO OWNER_INVOICE VALUES (2,8);
INSERT INTO OWNER_INVOICE VALUES (3,9);
INSERT INTO OWNER_INVOICE VALUES (1,9);
INSERT INTO OWNER_INVOICE VALUES (6,10);
INSERT INTO OWNER_INVOICE VALUES (4,10);
INSERT INTO OWNER_INVOICE VALUES (1,11);
INSERT INTO OWNER_INVOICE VALUES (2,11);                              
INSERT INTO OWNER_INVOICE VALUES (5,12);
INSERT INTO OWNER_INVOICE VALUES (2,12);


INSERT INTO INVOICE_DETAILS VALUES (1,3,2);
INSERT INTO INVOICE_DETAILS VALUES (2,2,3);
INSERT INTO INVOICE_DETAILS VALUES (3,1,1);
INSERT INTO INVOICE_DETAILS VALUES (4,4,2);
INSERT INTO INVOICE_DETAILS VALUES (5,6,4);
INSERT INTO INVOICE_DETAILS VALUES (6,5,3);
INSERT INTO INVOICE_DETAILS VALUES (7,1,1);
INSERT INTO INVOICE_DETAILS VALUES (8,4,2);
INSERT INTO INVOICE_DETAILS VALUES (9,5,4);
INSERT INTO INVOICE_DETAILS VALUES (10,2,1);
INSERT INTO INVOICE_DETAILS VALUES (11,6,2);
INSERT INTO INVOICE_DETAILS VALUES (12,3,1);