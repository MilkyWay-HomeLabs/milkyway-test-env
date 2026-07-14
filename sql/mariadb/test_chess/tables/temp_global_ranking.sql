create table temp_global_ranking
(
    player_id         bigint            not null
        primary key,
    position          int               not null,
    points            int   default 500 not null,
    actual_win_in_row int   default 0   not null,
    best_win_in_row   int   default 0   not null,
    win_ratio         float default 0   not null,
    wins              int   default 0   not null,
    draws             int   default 0   not null,
    loses             int   default 0   not null
);
