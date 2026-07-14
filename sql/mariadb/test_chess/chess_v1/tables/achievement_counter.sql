create table achievement_counter
(
    achievement_id int              not null,
    game_save_id   uuid             not null,
    value          double default 0 not null,
    primary key (achievement_id, game_save_id)
)
    comment 'Used for hard to calculate achievements';

