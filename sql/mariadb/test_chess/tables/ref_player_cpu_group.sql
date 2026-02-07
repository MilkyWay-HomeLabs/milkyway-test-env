create table ref_player_cpu_group
(
    id   int         not null
        primary key,
    name varchar(50) null,
    constraint ref_player_group_pk_2
        unique (name)
);
