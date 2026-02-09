create table season_tournament_phase
(
    id            uuid                                  not null
        primary key,
    name          varchar(50)                           null,
    game_save_id  uuid                                  null,
    season_id     uuid                                  null,
    tournament_id uuid                                  null,
    phase_id      int                                   not null,
    status_id     int                                   null,
    groups_count  int                                   null,
    groups_size   int                                   null,
    type_id       int                                   null,
    created_at    timestamp default current_timestamp() not null,
    updated_at    timestamp default current_timestamp() not null,
    constraint season_tournament_phase_pk
        unique (phase_id, game_save_id, season_id, tournament_id),
    constraint season_tournament_phase_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint season_tournament_phase_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id),
    constraint season_tournament_phase_ref_status_id_fk
        foreign key (status_id) references ref_status (id),
    constraint season_tournament_phase_ref_tournament_phase_type_id_fk
        foreign key (type_id) references ref_tournament_phase_type (id),
    constraint season_tournament_phase_season_tournament_id_fk
        foreign key (tournament_id) references season_tournament (id)
);
