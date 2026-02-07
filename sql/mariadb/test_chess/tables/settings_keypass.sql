create table settings_keypass
(
    id           uuid                                   not null
        primary key,
    game_save_id uuid                                   not null,
    keypass      tinyint unsigned                       not null,
    is_active    tinyint(1) default 1                   not null,
    created_at   timestamp  default current_timestamp() not null,
    updated_at   timestamp  default current_timestamp() not null,
    constraint settings_keypass_pk
        unique (game_save_id, keypass),
    constraint settings_keypass_enum_keypass_id_fk
        foreign key (keypass) references enum_keypass (id),
    constraint settings_keypass_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade
);
