create table game_types
(
    id             int auto_increment
        primary key,
    name           varchar(100) null,
    board_theme_id int          not null,
    constraint game_types_board_themes_id_fk
        foreign key (board_theme_id) references board_themes (id)
);

