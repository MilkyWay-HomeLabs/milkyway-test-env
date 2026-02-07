create definer = chess@`%` view v_nationality_counts as
select `gsp`.`id` AS `game_save_id`,
       `n`.`id`   AS `nationality_id`,
       `n`.`name` AS `nationality`,
       `r`.`id`   AS `region_id`,
       `r`.`name` AS `region`,
       count(0)   AS `counts`
from ((`test_chess`.`game_save_player` `gsp` join `test_chess`.`ref_nationality` `n`
       on (`gsp`.`nationality_id` = `n`.`id`)) join `test_chess`.`ref_region` `r` on (`r`.`id` = `n`.`region_id`))
group by `n`.`id`, `n`.`name`, `r`.`id`, `r`.`name`
order by `r`.`id`, count(0) desc;

-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('723e4567-e89b-12d3-a456-426614174000', 52, 'Cabo Verde', 1, 'Africa', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('783e4567-e89b-12d3-a456-426614174000', 128, 'Libya', 1, 'Africa', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('7a3e4567-e89b-12d3-a456-426614174000', 44, 'China', 5, 'Asia', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('743e4567-e89b-12d3-a456-426614174000', 109, 'Iraq', 5, 'Asia', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('773e4567-e89b-12d3-a456-426614174000', 150, 'Mongolia', 5, 'Asia', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('753e4567-e89b-12d3-a456-426614174000', 192, 'Saudi Arabia', 5, 'Asia', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('793e4567-e89b-12d3-a456-426614174000', 242, 'Viet Nam', 5, 'Asia', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('713e4567-e89b-12d3-a456-426614174000', 60, 'Germany', 7, 'Europe', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('763e4567-e89b-12d3-a456-426614174000', 112, 'Italy', 7, 'Europe', 1);
-- INSERT INTO test_chess.v_nationality_counts (game_save_id, nationality_id, nationality, region_id, region, counts) VALUES ('733e4567-e89b-12d3-a456-426614174000', 190, 'Russian Federation', 7, 'Europe', 1);
