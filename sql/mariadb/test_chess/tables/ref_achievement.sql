create table ref_achievement
(
    id            int                  not null
        primary key,
    type_id       int                  null,
    name          tinytext             null,
    description   tinytext             null,
    icon_url      tinytext             null,
    is_increasing tinyint(1) default 1 not null,
    constraint ref_achievement_ref_achievement_type_id_fk
        foreign key (type_id) references ref_achievement_type (id)
);
