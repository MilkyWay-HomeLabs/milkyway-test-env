create table ref_rules
(
    id            int         not null
        primary key,
    name          varchar(50) null,
    total_time    int         null,
    time_per_move int         null,
    constraint ref_rules_pk
        unique (name)
);
