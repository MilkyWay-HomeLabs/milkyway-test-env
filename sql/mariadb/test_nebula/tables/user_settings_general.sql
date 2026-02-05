create table user_settings_general
(
    user_id  bigint auto_increment
        primary key,
    theme_id int null,
    constraint user_settings_general_user_id_uindex
        unique (user_id),
    constraint user_settings_general_themes_id_fk
        foreign key (theme_id) references themes (id)
)
    engine = InnoDB;

