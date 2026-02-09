create table game_save_player
(
    id             uuid                                   not null
        primary key,
    game_save_id   uuid                                   not null,
    player_id      bigint                                 not null,
    first_name     varchar(50)                            null,
    last_name      varchar(50)                            null,
    nick_name      varchar(50)                            null,
    gender_id      int                                    null,
    nationality_id int                                    null,
    birth_date     date                                   null,
    game_age       int                                    null,
    is_human       tinyint(1) default 0                   null,
    created_at     timestamp  default current_timestamp() not null,
    updated_at     timestamp  default current_timestamp() not null,
    constraint game_save_player_pk_2
        unique (game_save_id, player_id),
    constraint game_save_player_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_player_ref_gender_id_fk
        foreign key (gender_id) references ref_gender (id),
    constraint game_save_player_ref_nationality_id_fk
        foreign key (nationality_id) references ref_nationality (id)
);
