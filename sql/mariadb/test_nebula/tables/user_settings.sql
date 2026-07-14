create table user_settings
(
    user_id    bigint auto_increment
        primary key,
    general_id bigint not null,
    sound_id   bigint not null,
    constraint user_settings_user_id_uindex
        unique (user_id),
    constraint user_settings_user_settings_general_user_id_fk
        foreign key (general_id) references user_settings_general (user_id),
    constraint user_settings_user_settings_sound_user_id_fk
        foreign key (sound_id) references user_settings_sound (user_id)
)
    engine = InnoDB;

