create table game_score
(
    game_id    uuid                                   not null,
    player_id  uuid                                   not null,
    is_white   tinyint(1) default 1                   null,
    type_id    tinyint unsigned                       null,
    result_id  tinyint unsigned                       null,
    points     decimal(3, 1)                          null,
    created_at timestamp  default current_timestamp() not null,
    primary key (game_id, player_id),
    constraint game_score_enum_game_result_id_fk
        foreign key (result_id) references enum_game_result (id),
    constraint game_score_enum_game_score_type_id_fk
        foreign key (type_id) references enum_game_score_type (id),
    constraint game_score_game_id_fk
        foreign key (game_id) references game (id)
            on delete cascade
);
