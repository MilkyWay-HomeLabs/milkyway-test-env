create table template_league_starting_positions
(
    ranking_position int not null,
    phase_id         int not null,
    group_id         int not null,
    position_id      int not null,
    primary key (ranking_position, phase_id, group_id, position_id)
);

