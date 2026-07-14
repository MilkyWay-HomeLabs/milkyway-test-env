create table ref_achievement_level
(
    id             int auto_increment
        primary key,
    achievement_id int null,
    level          int null,
    value          int null,
    constraint ref_achievement_level_pk
        unique (achievement_id, level),
    constraint ref_achievement_level_ref_achievement_id_fk
        foreign key (achievement_id) references ref_achievement (id)
);
