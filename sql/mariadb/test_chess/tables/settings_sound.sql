create table settings_sound
(
    game_save_id   uuid                                   not null
        primary key,
    muted          tinyint(1) default 0                   null comment 'If true all sounds are muted',
    volume_master  int        default 100                 null,
    volume_music   int        default 100                 null,
    volume_effects int                                    null,
    created_at     timestamp  default current_timestamp() not null,
    updated_at     timestamp  default current_timestamp() not null,
    constraint settings_sound_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade
);
