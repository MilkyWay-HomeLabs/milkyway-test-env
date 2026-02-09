create table game_save_season
(
    id           uuid                                  not null
        primary key,
    game_save_id uuid                                  not null,
    name         varchar(100)                          not null,
    status_id    int                                   not null,
    year         int                                   null,
    ranking_id   int                                   null,
    created_at   timestamp default current_timestamp() not null,
    updated_at   timestamp default current_timestamp() not null,
    constraint game_save_season_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_season_ref_ranking_id_fk
        foreign key (ranking_id) references ref_ranking (id),
    constraint game_save_season_ref_status_id_fk
        foreign key (status_id) references ref_status (id)
);
