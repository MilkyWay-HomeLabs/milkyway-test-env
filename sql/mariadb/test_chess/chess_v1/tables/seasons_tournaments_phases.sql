create table seasons_tournaments_phases
(
    season_id     uuid          not null,
    tournament_id int           not null,
    phase_id      int           not null,
    phase_name    varchar(50)   null,
    status_id     int default 1 not null,
    groups_count  int default 1 null,
    groups_size   int default 4 null,
    type_id       int           null,
    primary key (season_id, tournament_id, phase_id),
    constraint seasons_tournaments_phases_statuses_id_fk
        foreign key (status_id) references statuses (id),
    constraint seasons_tournaments_phases_tournament_phase_types_id_fk
        foreign key (type_id) references tournament_phase_types (id)
);

