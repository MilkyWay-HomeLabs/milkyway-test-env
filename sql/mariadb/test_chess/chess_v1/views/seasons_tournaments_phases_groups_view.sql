create definer = chess@`%` view seasons_tournaments_phases_groups_view as
select `s`.`id`             AS `id`,
       `s`.`name`           AS `name`,
       `s`.`game_save_id`   AS `game_save_id`,
       `s`.`year`           AS `year`,
       `st`.`tournament_id` AS `tournament_id`,
       `t`.`name`           AS `tournament_name`,
       `stp`.`phase_id`     AS `phase_id`,
       `stp`.`phase_name`   AS `phase_name`,
       `stpgv`.`group_id`   AS `group_id`,
       `stpgv`.`group_name` AS `group_name`
from ((((`chess`.`seasons_tournaments_phases_groups` `stpgv` join `chess`.`seasons_tournaments_phases` `stp`
         on (`stpgv`.`phase_id` = `stp`.`phase_id`)) join `chess`.`seasons_tournaments` `st`
        on (`stp`.`tournament_id` = `st`.`tournament_id`)) join `chess`.`seasons` `s`
       on (`s`.`id` = `stpgv`.`season_id`)) join `chess`.`tournaments` `t` on (`st`.`tournament_id` = `t`.`id`));

