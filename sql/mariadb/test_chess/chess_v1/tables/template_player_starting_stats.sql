create table template_player_starting_stats
(
    player_id          bigint not null
        primary key,
    group_id           int    not null,
    group_position_id  int    null,
    stats_points_index int    not null comment 'Store index in array stats_points_table',
    total_stat_points  int    not null comment 'Store sum of total starting points to distribution',
    rank_position      int    null comment 'Store starting rank position',
    rank_points        int    null comment 'Store starting rank points'
);

