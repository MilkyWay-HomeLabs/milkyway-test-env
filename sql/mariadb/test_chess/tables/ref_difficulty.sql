create table ref_difficulty
(
    id                 int             not null
        primary key,
    name               varchar(100)    null,
    description        varchar(255)    null,
    best_move_requests int             null,
    stats_multiplier   float default 1 not null,
    constraint ref_difficulty_pk_2
        unique (name)
);
