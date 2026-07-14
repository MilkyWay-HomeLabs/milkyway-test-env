create table ref_trophy
(
    id          int          not null
        primary key,
    name        varchar(50)  null,
    description varchar(255) null,
    constraint ref_trophy_pk_2
        unique (name)
);
