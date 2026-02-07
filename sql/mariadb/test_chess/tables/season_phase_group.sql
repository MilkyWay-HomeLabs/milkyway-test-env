create table season_phase_group
(
    id            uuid                                  not null
        primary key,
    name          varchar(100)                          not null,
    game_save_id  uuid                                  not null,
    season_id     uuid                                  not null,
    tournament_id uuid                                  not null,
    phase_id      uuid                                  not null,
    group_id      int                                   not null,
    status_id     int                                   not null,
    created_at    timestamp default current_timestamp() not null,
    updated_at    timestamp default current_timestamp() not null,
    constraint season_phase_group_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint season_phase_group_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id),
    constraint season_phase_group_ref_status_id_fk
        foreign key (status_id) references ref_status (id),
    constraint season_phase_group_season_tournament_id_fk
        foreign key (tournament_id) references season_tournament (id),
    constraint season_phase_group_season_tournament_phase_id_fk
        foreign key (phase_id) references season_tournament_phase (id)
);
