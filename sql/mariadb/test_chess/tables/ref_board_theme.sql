create table ref_board_theme
(
    id                    int         not null
        primary key,
    name                  varchar(50) null,
    white_field           varchar(7)  null,
    white_field_selected  varchar(7)  null,
    white_field_possible  varchar(7)  null,
    white_field_last_move varchar(7)  null,
    white_field_best_move varchar(7)  null,
    black_field           varchar(7)  null,
    black_field_selected  varchar(7)  null,
    black_field_possible  varchar(7)  null,
    black_field_last_move varchar(7)  null,
    black_field_best_move varchar(7)  null,
    border_color          varchar(7)  null,
    icons_catalog         varchar(20) null,
    constraint ref_board_theme_pk_2
        unique (name)
);
