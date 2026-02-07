create table ref_tournament_group
(
    id   int         not null
        primary key,
    name varchar(50) null,
    constraint ref_tournament_group_pk_2
        unique (name)
);
