create table settings_other
(
    game_save_id  uuid                    not null
        primary key,
    bonus_content tinyint(1)   default 0  null,
    content_key   varchar(100) default '' null
);

