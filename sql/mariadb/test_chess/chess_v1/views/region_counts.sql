create definer = chess@`%` view region_counts as
select `r`.`id` AS `region_id`, `r`.`name` AS `region`, count(0) AS `counts`
from ((`chess`.`players` `p` join `chess`.`nationalities` `n`
       on (`p`.`nationality_id` = `n`.`id`)) join `chess`.`regions` `r` on (`n`.`region_id` = `r`.`id`))
group by `r`.`id`, `r`.`name`
order by count(0) desc;

