create table board_themes
(
    id                    int auto_increment
        primary key,
    name                  varchar(50) not null,
    white_field           varchar(7)  null,
    white_field_selected  varchar(7)  null,
    white_field_possible  varchar(7)  null,
    white_field_last_move varchar(7)  not null,
    white_field_best_move varchar(7)  null,
    black_field           varchar(7)  not null,
    black_field_selected  varchar(7)  not null,
    black_field_possible  varchar(7)  not null,
    black_field_last_move varchar(7)  not null,
    black_field_best_move varchar(7)  not null,
    border_color          varchar(7)  not null,
    icons_catalog         varchar(20) not null
);

