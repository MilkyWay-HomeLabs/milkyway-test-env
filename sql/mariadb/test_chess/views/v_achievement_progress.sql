create definer = chess@`%` view v_achievement_progress as
with achievement_stats as (select `gs`.`id`                                             AS `game_save_id`,
                                  coalesce(sum(`gsa`.`level`), 0)                       AS `total_points`,
                                  (select count(0) from `test_chess`.`ref_achievement`) AS `total_achievements`
                           from (`test_chess`.`game_save` `gs` left join `test_chess`.`game_save_achievement` `gsa`
                                 on (`gs`.`id` = `gsa`.`game_save_id`))
                           group by `gs`.`id`)
select `achievement_stats`.`game_save_id`                                                        AS `game_save_id`,
       `achievement_stats`.`total_points`                                                        AS `total_points`,
       `achievement_stats`.`total_achievements`                                                  AS `total_achievements`,
       `achievement_stats`.`total_points` * 100 /
       (`achievement_stats`.`total_achievements` * 5)                                            AS `calculated_progress`
from `achievement_stats`;

-- INSERT INTO test_chess.v_achievement_progress (game_save_id, total_points, total_achievements, calculated_progress) VALUES ('123e4567-e89b-12d3-a456-426614174000', 30, 100, 6.0000);
