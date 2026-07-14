create table ref_tournament
(
    id                  int          not null
        primary key,
    name                varchar(50)  null,
    description         varchar(255) null,
    tournament_type_id  int          null,
    tournament_group_id int          null,
    interval_years      int          null,
    first_season        int          null,
    constraint ref_tournament_pk_2
        unique (name),
    constraint ref_tournament_ref_tournament_group_id_fk
        foreign key (tournament_group_id) references ref_tournament_group (id),
    constraint ref_tournament_ref_tournament_type_id_fk
        foreign key (tournament_type_id) references ref_tournament_type (id)
);
