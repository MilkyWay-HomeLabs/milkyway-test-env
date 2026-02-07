create table game_save_achievement
(
    game_save_id   uuid                                  not null,
    achievement_id int                                   not null,
    score          double                                null,
    level          int                                   null,
    to_next_level  double                                null,
    created_at     timestamp default current_timestamp() not null,
    updated_at     timestamp default current_timestamp() not null,
    primary key (achievement_id, game_save_id),
    constraint game_save_achievement_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_achievement_ref_achievement_id_fk
        foreign key (achievement_id) references ref_achievement (id)
);
