create table ref_tournament_type
(
    id   int         not null
        primary key,
    name varchar(50) null,
    constraint ref_tournament_type_pk_2
        unique (name)
);
