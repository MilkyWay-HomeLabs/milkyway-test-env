-- Create users/roles
-- Note: In a test environment, we assume a fresh volume.
-- If roles exist, these commands might throw a notice/error which is fine for init scripts.
CREATE
USER hacman WITH LOGIN PASSWORD 'hacman-secret-password';
CREATE
USER wolf WITH LOGIN PASSWORD 'wolf-secret-password';

-- Create databases with assigned ownership
CREATE
DATABASE hacman OWNER hacman;
CREATE
DATABASE test_hacman OWNER hacman;

-- Grant privileges to wolf user
GRANT ALL PRIVILEGES ON DATABASE
hacman TO wolf;
GRANT ALL PRIVILEGES ON DATABASE
test_hacman TO wolf;