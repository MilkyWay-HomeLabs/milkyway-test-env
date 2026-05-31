-- Create users/roles
-- Note: In a test environment, we assume a fresh volume.
-- If roles exist, these commands might throw a notice/error which is fine for init scripts.
CREATE
USER backup WITH LOGIN PASSWORD 'REPLACE_WITH_STRONG_PASSWORD';
CREATE
USER hacman WITH LOGIN PASSWORD 'hacman-secret-password';
CREATE
USER players WITH LOGIN PASSWORD 'players-secret-password';
CREATE
USER wolf WITH LOGIN PASSWORD 'wolf-secret-password';

-- Create databases with assigned ownership
CREATE
DATABASE hacman OWNER hacman;
CREATE
DATABASE test_hacman OWNER hacman;
CREATE
DATABASE test_players OWNER players;

-- Grant privileges to wolf user
GRANT ALL PRIVILEGES ON DATABASE
hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE
test_hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE
test_players TO wolf;

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
