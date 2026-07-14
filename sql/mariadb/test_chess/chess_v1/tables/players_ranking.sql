create table players_ranking
(
    ranking_id        int                                  not null,
    game_save_id      uuid                                 not null,
    player_id         bigint                               not null,
    points            int      default 0                   not null,
    position          int                                  not null,
    actual_win_in_row int      default 0                   null,
    win_ratio         float                                null,
    wins              int      default 0                   null,
    draws             int      default 0                   null,
    loses             int      default 0                   null,
    best_win_in_row   int      default 0                   null,
    difference        int      default 0                   null comment 'store difference position since last update',
    updated_at        datetime default current_timestamp() null,
    primary key (player_id, ranking_id, game_save_id)
);

