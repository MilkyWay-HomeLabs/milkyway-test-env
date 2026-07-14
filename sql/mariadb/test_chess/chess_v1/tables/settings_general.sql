create table settings_general
(
    game_save_id         uuid       not null
        primary key,
    auto_promotion_queen tinyint(1) null,
    difficulty_id        int        null
);

