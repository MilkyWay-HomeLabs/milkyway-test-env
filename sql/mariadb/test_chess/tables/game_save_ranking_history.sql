create table game_save_ranking_history
(
    id           uuid                                     not null
        primary key,
    game_save_id uuid                                     not null,
    player_id    bigint                                   not null,
    date         date                                     not null comment 'store postion differecne from last update',
    position     int                                      null,
    points       int          default 500                 null,
    win_ratio    float(23, 0) default 0                   null,
    wins         int          default 0                   null,
    draws        int          default 0                   null,
    loses        int          default 0                   null,
    created_at   timestamp    default current_timestamp() not null,
    updated_at   timestamp    default current_timestamp() not null,
    constraint game_save_ranking_history_pk
        unique (game_save_id, date, player_id),
    constraint game_save_ranking_history_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade
);
