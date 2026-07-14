create definer = chess@`%` view v_region_count as
select `r`.`id` AS `region_id`, `r`.`name` AS `region`, count(0) AS `counts`
from ((`test_chess`.`game_save_player` `gsp` join `test_chess`.`ref_nationality` `n`
       on (`gsp`.`nationality_id` = `n`.`id`)) join `test_chess`.`ref_region` `r` on (`r`.`id` = `n`.`region_id`))
group by `r`.`id`, `r`.`name`
order by count(0) desc;

-- INSERT INTO test_chess.v_region_count (region_id, region, counts) VALUES (5, 'Asia', 5);
-- INSERT INTO test_chess.v_region_count (region_id, region, counts) VALUES (7, 'Europe', 3);
-- INSERT INTO test_chess.v_region_count (region_id, region, counts) VALUES (1, 'Africa', 2);
