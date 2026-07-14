create table template_fourth_tournament_entry
(
    group_id          int not null,
    group_position_id int not null,
    ranking_position  int null,
    pair_id           int null,
    primary key (group_id, group_position_id)
);

