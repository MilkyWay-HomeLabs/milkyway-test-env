create table settings_sound
(
    game_save_id   uuid            not null
        primary key,
    master_volume  int default 100 null,
    music_volume   int default 100 null,
    effects_volume int default 100 null
);

