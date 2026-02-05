create table user_achievements
(
    user_id        bigint not null,
    achievement_id int    not null,
    progress       int    null,
    level          int    null,
    value          int    null,
    primary key (user_id, achievement_id),
    constraint user_achievements_achievements_id_fk
        foreign key (achievement_id) references achievements (id),
    constraint user_achievements_users_id_fk
        foreign key (user_id) references users (id)
)
    engine = InnoDB;

