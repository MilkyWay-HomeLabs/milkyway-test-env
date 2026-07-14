create table temp_player
(
    id             bigint               not null
        primary key,
    first_name     varchar(50)          null,
    last_name      varchar(50)          null,
    nick_name      varchar(50)          null,
    gender_id      int                  null,
    nationality_id int                  null,
    birth_date     date                 null,
    game_age       int                  null,
    is_human       tinyint(1) default 0 null,
    constraint temp_player_ref_gender_id_fk
        foreign key (gender_id) references ref_gender (id),
    constraint temp_player_ref_nationality_id_fk
        foreign key (nationality_id) references ref_nationality (id)
);
