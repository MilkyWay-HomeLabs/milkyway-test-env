create table settings_display
(
    game_save_id uuid                 not null
        primary key,
    auto_change  tinyint(1) default 0 null,
    theme_id     int        default 1 null,
    constraint settings_display_themes_id_fk
        foreign key (theme_id) references themes (id)
);

