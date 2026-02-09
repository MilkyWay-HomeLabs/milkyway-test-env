create table achievement_levels
(
    achievement_id int not null,
    level          int not null,
    value          int not null,
    primary key (achievement_id, level),
    constraint achievement_levels_achievements_id_fk
        foreign key (achievement_id) references achievements (id)
)
    engine = InnoDB;

