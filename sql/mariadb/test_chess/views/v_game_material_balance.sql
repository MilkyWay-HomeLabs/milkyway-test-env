create definer = chess@`%` view v_game_material_balance as
select `gc`.`game_id`                                                            AS `game_id`,
       sum(case when `gc`.`is_white` then -`ept`.`value` else `ept`.`value` end) AS `material_balance`,
       sum(case when `gc`.`is_white` then 1 else 0 end)                          AS `white_pieces_lost`,
       sum(case when `gc`.`is_white` = 0 then 1 else 0 end)                      AS `black_pieces_lost`,
       group_concat(
               concat(if(`gc`.`is_white`, 'W', 'B'), `ept`.`code`, '@', `gc`.`board_position`, '#', `gc`.`move_number`)
               order by `gc`.`move_number` ASC separator ',')                    AS `capture_sequence`
from (`test_chess`.`game_captured_pieces` `gc` join `test_chess`.`enum_piece_type` `ept`
      on (`gc`.`piece_type_id` = `ept`.`id`))
group by `gc`.`game_id`;

