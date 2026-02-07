create table game_save_chess_title
(
    id             uuid                                  not null
        primary key,
    game_save_id   uuid                                  not null,
    player_id      bigint                                not null,
    chess_title_id int                                   not null,
    created_at     timestamp default current_timestamp() not null,
    updated_at     timestamp default current_timestamp() not null,
    constraint game_save_chess_title_pk
        unique (game_save_id, player_id, chess_title_id),
    constraint game_save_chess_title_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_chess_title_ref_chess_title_id_fk
        foreign key (chess_title_id) references ref_chess_title (id)
);
