-- Chess Database Initialization Script (v2.0.0)
-- This script orchestrates the loading process without modifying the folder structure.
USE `test_chess`;

-- =============================================================================
-- 1. TABLE STRUCTURE (Ordered by Foreign Key dependencies)
-- =============================================================================

-- Enums and Reference Tables (Level 0 - no dependencies)
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/enum_game_result.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/enum_game_score_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/enum_keypass.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/enum_piece_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_region.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_nationality.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_gender.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_status.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_difficulty.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_board_theme.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_game_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_rules.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_theme.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_chess_title.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_ranking.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_trophy.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_award.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_achievement_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_achievement.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_achievement_level.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_tournament_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_tournament_phase_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_tournament_group.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_tournament.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_player_cpu_group.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_player_cpu_subgroup.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_player_cpu.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/ref_next_step.sql;

SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_player.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_season.sql;

-- Settings and Logs
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/settings_display.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/settings_general.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/settings_keypass.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/settings_sound.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/update_log.sql;

-- Core Process Tables
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_captured_pieces.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_score.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/season_tournament.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/season_tournament_phase.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/season_phase_group.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/season_group_player.sql;

-- Detailed Relationships (Dependent on game_save)
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_achievement.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_achievement_counter.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_award.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_chess_title.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_medal.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_ranking_global.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_ranking_history.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_ranking_season.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_step.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/game_save_trophy.sql;

-- Temporary / Staging Tables
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/temp_calendar_event.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/temp_chess_title.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/temp_global_ranking.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/temp_player.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/tables/temp_tournament_phases.sql;

-- =============================================================================
-- 2. TEST DATA (Following the same dependency order as structure)
-- =============================================================================
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/enum_game_result.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/enum_game_score_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/enum_keypass.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/enum_piece_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_region.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_nationality.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_gender.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_status.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_difficulty.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_board_theme.sql;

SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_game_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_rules.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_theme.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_chess_title.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_ranking.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_trophy.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_award.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_achievement_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_achievement.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_achievement_level.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_tournament_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_tournament_phase_type.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_tournament_group.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_tournament.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_player_cpu_group.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_player_cpu_subgroup.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_player_cpu.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/ref_next_step.sql;

SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_player.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_season.sql;

-- Settings and Logs
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/settings_display.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/settings_general.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/settings_keypass.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/settings_sound.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/update_log.sql;

-- Core Process test_data
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_captured_pieces.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_score.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/season_tournament.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/season_tournament_phase.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/season_phase_group.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/season_group_player.sql;

-- Detailed Relationships (Dependent on game_save)
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_achievement.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_achievement_counter.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_award.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_chess_title.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_medal.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_ranking_global.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_ranking_history.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_ranking_season.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_step.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/game_save_trophy.sql;

-- Temporary / Staging test_data
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/temp_calendar_event.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/temp_chess_title.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/temp_global_ranking.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/temp_player.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/test_data/temp_tournament_phases.sql;

-- =============================================================================
-- 3. VIEWS AND LOGIC (Loaded last after all data exists)
-- =============================================================================

SOURCE /docker-entrypoint-initdb.d/test_chess/views/v_achievement_progress.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/views/v_game_material_balance.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/views/v_nationality_counts.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/views/v_player_award_trophy_stats.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/views/v_region_count.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/views/v_update_stats.sql;

-- Enable MariaDB Event Scheduler
SET GLOBAL event_scheduler = ON;

-- Note: Routines and Events require .sql extensions to be loaded via SOURCE
SOURCE /docker-entrypoint-initdb.d/test_chess/routines/update_achievement_progress.sql;
SOURCE /docker-entrypoint-initdb.d/test_chess/events/achievement_progress_update_event.sql;