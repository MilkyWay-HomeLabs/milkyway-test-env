create table ref_player_cpu
(
    id                bigint not null
        primary key,
    total_points      int    null,
    concentration     int    null,
    `analyze`         int    null,
    intelligence      int    null,
    reliability       int    null,
    timing            int    null,
    subgroup_id       int    null,
    subgroup_position int    null,
    constraint ref_player_cpu_pk
        unique (subgroup_id, subgroup_position),
    constraint ref_player_cpu_ref_player_cpu_subgroup_id_fk
        foreign key (subgroup_id) references ref_player_cpu_subgroup (id)
);
