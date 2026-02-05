-- Nebula Database Initialization
USE `test_nebula`;

-- =============================================================================
-- 1. STRUCTURE (Models)
-- =============================================================================

-- Dictionary and independent tables
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/regions.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/nationalities.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/genders.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/themes.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/games.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/achievements.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/achievement_levels.sql;

-- Main user table
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/users.sql;

-- Settings tables
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/user_settings_general.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/user_settings_sound.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/user_settings.sql;

-- Relational / Many-to-many tables
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/user_achievements.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/tables/users_games.sql;

-- =============================================================================
-- 2. DATA (Seed data)
-- =============================================================================

-- Load test data in the same dependency order
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/regions.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/nationalities.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/genders.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/themes.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/games.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/achievements.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/achievement_levels.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/users.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/user_settings_general.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/user_settings_sound.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/user_settings.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/user_achievements.sql;
SOURCE /docker-entrypoint-initdb.d/test_nebula/test_data/users_games.sql;