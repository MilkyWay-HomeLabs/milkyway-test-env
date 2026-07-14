create table players
(
    id                bigint                 not null
        primary key,
    first_name        varchar(50)            null,
    last_name         varchar(50)            null,
    nick_name         varchar(50)            null,
    gender_id         int                    not null,
    nationality_id    int                    not null,
    birth_date        date                   null,
    game_age          int                    null,
    is_human          tinyint(1) default 0   not null,
    total_points      int        default 250 null,
    concentration     int        default 50  null,
    `analyze`         int        default 50  null,
    intelligence      int        default 50  null,
    reliability       int        default 50  null,
    timing            int        default 50  null,
    default_cpu       tinyint(1) default 0   null,
    subgroup_id       int                    null,
    subgroup_position int                    null,
    constraint players_genders_id_fk
        foreign key (gender_id) references genders (id),
    constraint players_nationalities_id_fk
        foreign key (nationality_id) references nationalities (id),
    constraint players_player_subgroups_id_fk
        foreign key (subgroup_id) references player_subgroups (id)
);

