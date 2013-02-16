--- paste.sql

CREATE TABLE formats ( ---создает таблицу formats
    format_id serial PRIMARY KEY, ---autoincrementing integer
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE, --является копией колонки в users
    title varchar (64), --название, не более 64 символов
    code text, --хранилище для какого-то кода. текст
    created timestamp with time zone -- время создания. с учетом часового пояса.
);

ALTER TABLE formats OWNER TO lisp; --смена полльзователя
---дальше - хз
CREATE TRIGGER formats_insert_trigger 
    BEFORE INSERT ON formats
    FOR EACH ROW
    EXECUTE PROCEDURE rlf_created_fix();

CREATE OR REPLACE FUNCTION add_format_code (vlogin varchar(32), vtitle varchar(64), vcode text) RETURNS integer
    AS $$
DECLARE
   id integer;
   uid integer;
BEGIN
   SELECT nextval('formats_format_id_seq') INTO id;
   SELECT user_id INTO uid FROM users WHERE login = vlogin;   
   INSERT INTO formats (format_id, user_id, title, code) VALUES (id, uid, vtitle, vcode);
   RETURN id;
END;
$$
    LANGUAGE plpgsql;
