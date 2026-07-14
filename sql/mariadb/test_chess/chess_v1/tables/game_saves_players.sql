create table game_saves_players
(
    game_save_id uuid   not null,
    player_id    bigint not null,
    primary key (game_save_id, player_id)
);

