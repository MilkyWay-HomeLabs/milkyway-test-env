create table season_group_player
(
    id                  uuid                                     not null
        primary key,
    game_save_id        uuid                                     not null,
    season_id           uuid                                     not null,
    tournament_id       uuid                                     not null,
    phase_id            uuid                                     not null,
    group_id            uuid                                     not null,
    game_save_player_id uuid                                     not null,
    player_id           bigint                                   null,
    position            int unsigned                             null,
    points              int          default 0                   null,
    wins                int unsigned default 0                   null,
    draws               int unsigned default 0                   null,
    loses               int unsigned default 0                   null,
    matches             int unsigned default 0                   null,
    pair_id             int                                      null,
    created_at          timestamp    default current_timestamp() not null,
    updated_at          timestamp    default current_timestamp() not null invisible,
    constraint season_group_player_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint season_group_player_game_save_player_id_fk
        foreign key (game_save_player_id) references game_save_player (id),
    constraint season_group_player_game_save_season_id_fk
        foreign key (season_id) references game_save_season (id),
    constraint season_group_player_season_tournament_group_id_fk
        foreign key (group_id) references season_phase_group (id),
    constraint season_group_player_season_tournament_id_fk
        foreign key (tournament_id) references season_tournament (id),
    constraint season_group_player_season_tournament_phase_id_fk
        foreign key (phase_id) references season_tournament_phase (id)
);
