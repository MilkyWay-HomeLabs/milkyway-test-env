create table temp_chess_title
(
    id             uuid   not null
        primary key,
    player_id      bigint not null,
    chess_title_id int    not null,
    constraint temp_chess_title_pk_2
        unique (player_id, chess_title_id)
);
