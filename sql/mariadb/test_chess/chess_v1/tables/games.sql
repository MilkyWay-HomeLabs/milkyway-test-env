create table games
(
    id              char(36)     not null
        primary key,
    game_save_id    uuid         not null,
    game_name       varchar(255) not null,
    white_player_id bigint       not null,
    black_player_id bigint       not null,
    status_id       int          null,
    rules_id        int          not null,
    game_type_id    int          null,
    season_id       uuid         not null,
    tournament_id   int          null,
    phase_id        int          null,
    group_id        int          null,
    date            date         not null,
    constraint games_game_types_id_fk
        foreign key (game_type_id) references game_types (id),
    constraint games_rules_id_fk
        foreign key (rules_id) references rules (id),
    constraint games_statuses_id_fk
        foreign key (status_id) references statuses (id)
);

