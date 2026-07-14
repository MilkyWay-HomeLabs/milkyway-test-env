create definer = chess@`%` view nationality_counts as
select `n`.`id` AS `nationality_id`, `n`.`name` AS `nationality`, `r`.`name` AS `region`, count(0) AS `counts`
from ((`chess`.`players` `p` join `chess`.`nationalities` `n`
       on (`p`.`nationality_id` = `n`.`id`)) join `chess`.`regions` `r` on (`r`.`id` = `n`.`region_id`))
group by `n`.`id`, `n`.`name`, `r`.`name`
order by count(0) desc;

