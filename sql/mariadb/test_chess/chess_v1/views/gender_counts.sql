create definer = chess@`%` view gender_counts as
select `g`.`id` AS `gender_id`, `g`.`name` AS `gender`, count(0) AS `counts`
from (`chess`.`players` `p` join `chess`.`genders` `g` on (`p`.`gender_id` = `g`.`id`))
group by `g`.`id`, `g`.`name`
order by count(0) desc;

