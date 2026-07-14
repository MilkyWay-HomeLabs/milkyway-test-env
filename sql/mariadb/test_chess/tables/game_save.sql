create table game_save
(
    id                   uuid                                  not null
        primary key,
    name                 varchar(255)                          not null,
    game_save_player_id  uuid                                  not null,
    player_id            bigint                                not null,
    status_id            int                                   null,
    current_game_date    date      default '2024-01-01'        not null,
    current_game_year    int       default 2024                null,
    current_game_month   int       default 0                   null,
    achievement_progress double    default 0                   not null,
    created_at           timestamp default current_timestamp() not null,
    updated_at           timestamp default current_timestamp() not null on update current_timestamp(),
    next_step_id         uuid                                  null,
    constraint uk_game_save_name
        unique (name),
    constraint game_save_game_statuses_id_fk
        foreign key (status_id) references ref_status (id)
);

create index game_save_status_id_fk
    on game_save (status_id);

INSERT INTO test_chess.game_save (id, name, game_save_player_id, player_id, status_id, current_game_date, current_game_year, current_game_month, achievement_progress, created_at, updated_at, next_step_id) VALUES ('123e4567-e89b-12d3-a456-426614174000', 'TEST GAME SAVE 001', '713e4567-e89b-12d3-a456-426614174000', 1, 1, '2025-07-01', 2025, 7, 6, '2025-07-10 07:50:55', '2025-08-19 11:06:28', '566e4567-e89b-12d3-a456-426614174000');
