create table game_save_medals
(
    game_save_id uuid   not null,
    season_id    uuid   not null,
    trophy_id    int    not null,
    player_id    bigint not null,
    position     int    null,
    primary key (game_save_id, season_id, trophy_id, player_id)
)
    comment 'store earned gold, silver and bronze medals';

