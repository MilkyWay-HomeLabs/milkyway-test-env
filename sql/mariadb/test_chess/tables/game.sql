create table game
(
    id              uuid                                  not null
        primary key,
    name            varchar(255)                          null,
    game_save_id    uuid                                  null,
    season_id       uuid                                  null,
    white_player_id uuid                                  not null,
    black_player_id uuid                                  not null,
    status_id       int                                   null,
    rules_id        int                                   null,
    game_type_id    int                                   not null,
    tournament_id   int                                   null,
    phase_id        int                                   null,
    group_id        int                                   null,
    date            date                                  null,
    updated_at      timestamp default current_timestamp() not null,
    created_at      timestamp default current_timestamp() not null,
    constraint game_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_game_save_player_id_fk
        foreign key (white_player_id) references game_save_player (id),
    constraint game_game_save_player_id_fk_2
        foreign key (black_player_id) references game_save_player (id),
    constraint game_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id),
    constraint game_ref_game_type_id_fk
        foreign key (game_type_id) references ref_game_type (id),
    constraint game_ref_rules_id_fk
        foreign key (rules_id) references ref_rules (id),
    constraint game_ref_status_id_fk
        foreign key (status_id) references ref_status (id),
    constraint game_ref_tournament_id_fk
        foreign key (tournament_id) references ref_tournament (id)
);
