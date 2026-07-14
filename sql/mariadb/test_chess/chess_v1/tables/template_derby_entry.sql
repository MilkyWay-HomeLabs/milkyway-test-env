create table template_derby_entry
(
    tree_id     int null comment 'store id of tournament tree position',
    phase_id    int not null,
    position_id int not null,
    group_id    int not null,
    primary key (phase_id, position_id, group_id)
);

