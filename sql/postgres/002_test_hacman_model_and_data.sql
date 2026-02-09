-- Switch to test_hacman database
\c test_hacman

-- Load schema and data (using the same scripts for test environment)
\i /docker-entrypoint-initdb.d/test_hacman/hacman_schema.sql
\i /docker-entrypoint-initdb.d/test_hacman/galleries.sql
\i /docker-entrypoint-initdb.d/test_hacman/users.sql
\i /docker-entrypoint-initdb.d/test_hacman/user_galleries.sql