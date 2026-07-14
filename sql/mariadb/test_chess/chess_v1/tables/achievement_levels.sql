create table achievement_levels
(
    achievement_id int not null,
    level          int not null,
    value          int null,
    primary key (achievement_id, level)
);

