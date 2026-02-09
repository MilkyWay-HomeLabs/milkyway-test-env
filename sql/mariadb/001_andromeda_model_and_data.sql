-- Andromeda Database Initialization
USE `test_andromeda`;

-- =============================================================================
-- 1. STRUCTURE (Models)
-- =============================================================================
SOURCE /docker-entrypoint-initdb.d/test_andromeda/tables/roles.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/tables/users.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/tables/user_roles.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/tables/access_tokens.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/tables/confirmation_tokens.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/tables/refresh_tokens.sql;

-- =============================================================================
-- 2. DATA (Seed data)
-- =============================================================================
SOURCE /docker-entrypoint-initdb.d/test_andromeda/test_data/roles.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/test_data/users.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/test_data/user_roles.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/test_data/access_tokens.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/test_data/confirmation_tokens.sql;
SOURCE /docker-entrypoint-initdb.d/test_andromeda/test_data/refresh_tokens.sql;