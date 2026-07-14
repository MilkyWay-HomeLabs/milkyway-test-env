create table seasons_tournaments
(
    season_id     uuid          not null,
    tournament_id int           not null,
    status_id     int default 1 not null,
    primary key (season_id, tournament_id),
    constraint seasons_tournaments_statuses_id_fk
        foreign key (status_id) references statuses (id),
    constraint seasons_tournaments_tournaments_id_fk
        foreign key (tournament_id) references tournaments (id)
);

