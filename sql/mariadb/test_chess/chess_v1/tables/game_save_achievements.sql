create table game_save_achievements
(
    game_save_id   uuid             not null,
    achievement_id int              not null,
    score          double default 0 null,
    level          int    default 0 null,
    to_next_level  double           null,
    primary key (game_save_id, achievement_id)
);

