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

-- Create databases with assigned ownership
CREATE DATABASE hacman OWNER hacman;
CREATE DATABASE test_hacman OWNER hacman;
CREATE DATABASE test_players OWNER players;

-- Grant privileges to wolf user
GRANT ALL PRIVILEGES ON DATABASE hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE test_hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE test_players TO wolf;

-- Grant backup users
GRANT CONNECT ON DATABASE hacman TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;

GRANT CONNECT ON DATABASE test_hacman TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;

GRANT CONNECT ON DATABASE test_players TO backup;
GRANT USAGE ON SCHEMA public TO backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup;


