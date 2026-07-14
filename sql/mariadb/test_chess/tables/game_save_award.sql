create table game_save_award
(
    id                       uuid                                  not null
        primary key,
    game_save_id             uuid                                  not null,
    season_id                uuid                                  not null,
    award_id                 int                                   not null,
    best_game_save_player_id uuid                                  not null,
    best_player_id           bigint                                null,
    best_score               double                                null,
    player_score             double                                null,
    created_at               timestamp default current_timestamp() not null,
    updated_at               timestamp default current_timestamp() not null,
    constraint game_save_award_pk
        unique (game_save_id, season_id, award_id),
    constraint game_save_award_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_save_award_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id)
);
