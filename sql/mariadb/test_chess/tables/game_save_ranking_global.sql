create table game_save_ranking_global
(
    id                  uuid                                     not null
        primary key,
    game_save_id        uuid                                     not null,
    game_save_player_id uuid                                     not null,
    player_id           bigint                                   not null,
    position            int                                      null,
    difference          int                                      null comment 'store postion differecne from last update',
    points              int          default 500                 null,
    actual_win_in_row   int          default 0                   null,
    best_win_in_row     int          default 0                   null,
    win_ratio           float(23, 0) default 0                   null,
    wins                int          default 0                   null,
    draws               int          default 0                   null,
    loses               int          default 0                   null,
    created_at          timestamp    default current_timestamp() not null,
    updated_at          timestamp    default current_timestamp() not null,
    constraint game_save_ranking_global_pk_2
        unique (player_id, game_save_id),
    constraint game_save_ranking_global_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade
);
