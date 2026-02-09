create definer = chess@`%` view v_update_stats as
with time_differences as (select `test_chess`.`update_log`.`update_type`                                                                                           AS `update_type`,
                                 `test_chess`.`update_log`.`update_time`                                                                                           AS `update_time`,
                                 timestampdiff(SECOND, `test_chess`.`update_log`.`update_time`,
                                               lead(`test_chess`.`update_log`.`update_time`, 1)
                                                    over ( partition by `test_chess`.`update_log`.`update_type` order by `test_chess`.`update_log`.`update_time`)) AS `seconds_between_updates`
                          from `test_chess`.`update_log`)
select `time_differences`.`update_type`                  AS `update_type`,
       count(0)                                          AS `update_count`,
       avg(`time_differences`.`seconds_between_updates`) AS `avg_seconds_between_updates`
from `time_differences`
group by `time_differences`.`update_type`;

-- INSERT INTO test_chess.v_update_stats (update_type, update_count, avg_seconds_between_updates) VALUES ('achievement_progress_success (rows: 0)', 1, null);
-- INSERT INTO test_chess.v_update_stats (update_type, update_count, avg_seconds_between_updates) VALUES ('achievement_progress_success (rows: 1)', 1, null);
