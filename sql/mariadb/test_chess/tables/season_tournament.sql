create table season_tournament
(
    id            uuid                                  not null
        primary key,
    name          varchar(100)                          null,
    game_save_id  uuid                                  null,
    season_id     uuid                                  null,
    tournament_id int                                   null,
    status_id     int                                   null,
    created_at    timestamp default current_timestamp() not null,
    updated_at    timestamp default current_timestamp() not null,
    constraint season_tournament_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint season_tournament_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id),
    constraint season_tournament_ref_status_id_fk
        foreign key (status_id) references ref_status (id),
    constraint season_tournament_ref_tournament_id_fk
        foreign key (tournament_id) references ref_tournament (id)
);
