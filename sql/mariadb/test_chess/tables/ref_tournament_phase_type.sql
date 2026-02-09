create table ref_tournament_phase_type
(
    id          int          not null
        primary key,
    name        varchar(100) null,
    description varchar(255) null,
    constraint ref_tournament_phase_type_pk_2
        unique (name)
);
