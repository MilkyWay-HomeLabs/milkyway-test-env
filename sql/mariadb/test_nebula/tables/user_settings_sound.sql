create table user_settings_sound
(
    user_id        bigint auto_increment
        primary key,
    muted          tinyint(1) default 0   null,
    volume_master  int        default 100 null,
    volume_music   int        default 100 null,
    volume_effects int        default 100 null,
    volume_voices  int        default 100 null,
    battle_cry     tinyint(1) default 1   null,
    constraint user_settings_sound_id_uindex
        unique (user_id)
)
    engine = InnoDB;

