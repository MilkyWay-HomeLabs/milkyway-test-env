create table seasons_tournaments_phases_groups
(
    season_id     uuid          not null,
    tournament_id int           not null,
    phase_id      int           not null,
    group_id      int           not null,
    group_name    varchar(25)   null,
    status_id     int default 1 null,
    primary key (season_id, tournament_id, phase_id, group_id),
    constraint seasons_tournaments_phases_groups_statuses_id_fk
        foreign key (status_id) references statuses (id)
);

