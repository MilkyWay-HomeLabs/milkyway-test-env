create table users_games
(
    user_id bigint not null,
    game_id int    not null,
    primary key (user_id, game_id)
)
    engine = InnoDB;

