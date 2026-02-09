create table game_save_trophy
(
    id              uuid                                  not null
        primary key,
    game_save_id    uuid                                  not null,
    trophy_id       int                                   not null,
    best_place      int                                   null,
    times           int       default 1                   null,
    first_season_id uuid                                  null,
    created_at      timestamp default current_timestamp() not null,
    updated_at      timestamp default current_timestamp() not null,
    constraint game_save_trophy_pk_2
        unique (best_place, game_save_id, trophy_id),
    constraint game_save_trophy_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_trophy_game_save_season_id_fk
        foreign key (first_season_id) references game_save_season (id),
    constraint game_save_trophy_ref_trophy_id_fk
        foreign key (trophy_id) references ref_trophy (id)
);
