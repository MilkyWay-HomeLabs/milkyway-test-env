create table ref_player_cpu_subgroup
(
    id       int         not null
        primary key,
    name     varchar(50) null,
    group_id int         null,
    constraint ref_player_cpu_subgroup_ref_player_group_id_fk
        foreign key (group_id) references ref_player_cpu_group (id)
);
