create table ref_chess_title
(
    id          int          not null
        primary key,
    name        varchar(100) not null,
    code        varchar(3)   not null,
    description varchar(255) null,
    constraint ref_chess_title_pk_2
        unique (name),
    constraint ref_chess_title_pk_3
        unique (code)
);
