create table game_save_medal
(
    id                  uuid                                  not null
        primary key,
    game_save_id        uuid                                  not null,
    season_id           uuid                                  not null,
    trophy_id           int                                   not null,
    game_save_player_id uuid                                  not null,
    player_id           mediumtext                            not null,
    position            int                                   null,
    created_at          timestamp default current_timestamp() null,
    updated_at          timestamp default current_timestamp() not null,
    constraint game_save_medal_pk
        unique (season_id, trophy_id, game_save_player_id, position),
    constraint game_save_medal_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_medal_game_save_player_id_fk
        foreign key (game_save_player_id) references game_save_player (id),
    constraint game_save_medal_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id),
    constraint game_save_medal_ref_trophy_id_fk
        foreign key (trophy_id) references ref_trophy (id)
);
