create definer = chess@`%` view v_player_award_trophy_stats as
select `gsaw`.`game_save_id`                                                      AS `game_save_id`,
       `gsaw`.`season_id`                                                         AS `season_id`,
       `gsaw`.`best_game_save_player_id`                                          AS `player_id`,
       (select count(0)
        from `test_chess`.`game_save_award` `a`
        where `a`.`game_save_id` = `gsaw`.`game_save_id`
          and `a`.`best_game_save_player_id` = `gsaw`.`best_game_save_player_id`) AS `total_awards`,
       (select count(0)
        from `test_chess`.`game_save_award` `a`
        where `a`.`game_save_id` = `gsaw`.`game_save_id`
          and `a`.`season_id` = `gsaw`.`season_id`
          and `a`.`best_game_save_player_id` = `gsaw`.`best_game_save_player_id`) AS `season_awards`,
       (select count(0)
        from `test_chess`.`game_save_medal` `m`
        where `m`.`game_save_id` = `gsaw`.`game_save_id`
          and `m`.`game_save_player_id` = `gsaw`.`best_game_save_player_id`
          and `m`.`position` = 1)                                                 AS `total_trophies`,
       (select count(0)
        from `test_chess`.`game_save_medal` `m`
        where `m`.`game_save_id` = `gsaw`.`game_save_id`
          and `m`.`season_id` = `gsaw`.`season_id`
          and `m`.`game_save_player_id` = `gsaw`.`best_game_save_player_id`
          and `m`.`position` = 1)                                                 AS `season_trophies`
from `test_chess`.`game_save_award` `gsaw`;

-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '713e4567-e89b-12d3-a456-426614174000', 1, 1, 3, 3);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '723e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '733e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '743e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '753e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '763e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '773e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '783e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '793e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
-- INSERT INTO test_chess.v_player_award_trophy_stats (game_save_id, season_id, player_id, total_awards, season_awards, total_trophies, season_trophies) VALUES ('123e4567-e89b-12d3-a456-426614174000', '550e8400-e29b-41d4-a716-446655440000', '7a3e4567-e89b-12d3-a456-426614174000', 1, 1, 0, 0);
