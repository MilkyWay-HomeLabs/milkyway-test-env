-- Create users/roles
-- Note: In a test environment, we assume a fresh volume.
-- If roles exist, these commands might throw a notice/error which is fine for init scripts.
--
-- This file is committed to a public repository: passwords are placeholders.
-- Replace every CHANGE_ME with the value from the corresponding key in env/db/postgres.env
-- before initialising an empty volume. Runs only on an empty data directory — to change a
-- password on a live database use ALTER USER instead.
CREATE USER backup WITH LOGIN PASSWORD 'CHANGE_ME';   -- POSTGRES_BACKUP_PASSWORD
CREATE USER hacman WITH LOGIN PASSWORD 'CHANGE_ME';   -- HACMAN_PASSWORD
CREATE USER wolf WITH LOGIN PASSWORD 'CHANGE_ME';     -- personal superuser account
CREATE USER players WITH LOGIN PASSWORD 'CHANGE_ME';  -- PLAYERS_PASSWORD
CREATE USER element WITH LOGIN PASSWORD 'CHANGE_ME';  -- ELEMENT_PASSWORD

-- Create databases with assigned ownership
CREATE DATABASE hacman OWNER hacman;
CREATE DATABASE test_hacman OWNER hacman;
CREATE DATABASE test_players OWNER players;
-- element-rest-api owns its database because Flyway creates the whole schema at
-- startup (ddl-auto: validate, migrations are the source of truth). Ownership is
-- what gives it CREATE on `public`: since PostgreSQL 15 that schema is owned by
-- pg_database_owner rather than granting CREATE to PUBLIC.
CREATE DATABASE test_element OWNER element;

-- Grant privileges to wolf user
GRANT ALL PRIVILEGES ON DATABASE hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE test_hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE test_players TO wolf;
GRANT ALL PRIVILEGES ON DATABASE test_element TO wolf;

-- Grant the backup user read access, per database.
--
-- GRANT ... ON SCHEMA / ON ALL TABLES only ever applies to the database you are
-- CONNECTED to — the preceding "GRANT CONNECT ON DATABASE <x>" does not switch you into
-- it. The original version ran all nine statements while still connected to `postgres`,
-- so the backup user got SELECT on nothing, and pg_dump of test_hacman failed with
-- "permission denied for table level_scores" for months while the job still reported
-- success. The \connect lines below are the whole fix.
--
-- ALTER DEFAULT PRIVILEGES only covers tables created *afterwards* by the granting role,
-- so it does not retroactively cover tables an application already created. If an app
-- adds tables later as its own user, re-run the GRANT for that database.
--
-- TABLES ARE NOT ENOUGH: pg_dump also reads every sequence's last_value, so a database
-- whose sequences are unreadable fails outright — and it fails *early*, producing a
-- 0-byte dump rather than a partial one. test_element did exactly that ("permission
-- denied for sequence award_result_id_seq") the first time it was dumped, with SELECT on
-- all 37 tables already granted. Grant SEQUENCES alongside TABLES, every time.

\connect hacman
GRANT CONNECT ON DATABASE hacman TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;

\connect test_hacman
GRANT CONNECT ON DATABASE test_hacman TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;

\connect test_players
GRANT CONNECT ON DATABASE test_players TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;

-- test_element is empty at this point: Flyway builds the schema on first start of
-- element-rest-api, as the `element` user. That is exactly the case the note above
-- warns about, so the default privileges are granted FOR ROLE element — without
-- that, every table Flyway creates would be invisible to the backup user and the
-- dump would silently omit the entire database.
\connect test_element
GRANT CONNECT ON DATABASE test_element TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES FOR ROLE element IN SCHEMA public GRANT SELECT ON TABLES TO backup;
ALTER DEFAULT PRIVILEGES FOR ROLE element IN SCHEMA public GRANT SELECT ON SEQUENCES TO backup;


