create table player_subgroups
(
    id       int         not null
        primary key,
    name     varchar(50) not null,
    group_id int         null,
    constraint player_subgroups_player_groups_id_fk
        foreign key (group_id) references player_groups (id)
);

