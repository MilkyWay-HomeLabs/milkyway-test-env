create table tournaments
(
    id                  int auto_increment
        primary key,
    name                varchar(50)   not null,
    description         varchar(255)  null,
    tournament_type_id  int           not null,
    tournament_group_id int           not null,
    interval_years      int default 1 null,
    first_season        int default 1 null,
    constraint tournaments_tournament_group_id_fk
        foreign key (tournament_group_id) references tournament_groups (id),
    constraint tournaments_tournament_type_id_fk
        foreign key (tournament_type_id) references tournament_types (id)
);

