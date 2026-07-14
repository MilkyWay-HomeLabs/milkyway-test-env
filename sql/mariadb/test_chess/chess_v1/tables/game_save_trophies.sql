create table game_save_trophies
(
    game_save_id    uuid                                  not null,
    trophy_id       int                                   not null,
    best_place      int                                   null,
    times           int       default 0                   null,
    first_season_id uuid                                  null,
    updated_at      timestamp default current_timestamp() not null,
    primary key (game_save_id, trophy_id)
);

