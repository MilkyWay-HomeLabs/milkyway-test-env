create table ref_game_type
(
    id             int          not null
        primary key,
    name           varchar(100) null,
    board_theme_id int          null,
    constraint ref_game_type_pk_2
        unique (name),
    constraint ref_game_type_ref_board_theme_id_fk
        foreign key (board_theme_id) references ref_board_theme (id)
);
