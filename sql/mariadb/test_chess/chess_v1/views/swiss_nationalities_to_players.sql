create definer = chess@`%` view swiss_nationalities_to_players as
select `sngn`.`group_id` AS `group_id`, `p`.`id` AS `player`, `n`.`id` AS `nationality`
from ((`chess`.`players` `p` join `chess`.`nationalities` `n`
       on (`p`.`nationality_id` = `n`.`id`)) join `chess`.`swiss_national_groups_nationalities` `sngn`
      on (`sngn`.`nationality_id` = `n`.`id`))
order by `p`.`id` desc;

