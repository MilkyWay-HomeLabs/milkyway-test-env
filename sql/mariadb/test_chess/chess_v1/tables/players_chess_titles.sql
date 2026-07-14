create table players_chess_titles
(
    player_id      bigint not null,
    chess_title_id int    not null,
    game_save_id   uuid   not null,
    primary key (player_id, game_save_id, chess_title_id)
);

