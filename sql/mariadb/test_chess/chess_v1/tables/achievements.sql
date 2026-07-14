create table achievements
(
    id            int                  not null
        primary key,
    name          tinytext             null,
    type_id       int                  not null,
    description   tinytext             null,
    icon_url      tinytext             null,
    is_increasing tinyint(1) default 1 not null,
    constraint achievements_achievement_types_id_fk
        foreign key (type_id) references achievement_types (id)
);

