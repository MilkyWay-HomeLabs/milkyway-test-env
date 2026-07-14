create table template_first_world_cup_entry
(
    group_id    int    not null,
    position_id int    not null,
    player_id   bigint null,
    primary key (group_id, position_id)
);

