create table game_save_step
(
    id            uuid                                   not null
        primary key,
    next_step_id  int                                    not null,
    game_save_id  uuid                                   not null,
    season_id     uuid                                   not null,
    tournament_id uuid                                   null,
    phase_id      uuid                                   null,
    round         int                                    null,
    priority      int                                    not null,
    `order`       int                                    not null,
    date          date                                   null,
    completed     tinyint(1) default 0                   null,
    created_at    timestamp  default current_timestamp() not null,
    updated_at    timestamp  default current_timestamp() not null,
    constraint game_save_step_pk
        unique (game_save_id, `order`, season_id),
    constraint game_save_step_ref_next_step_id_fk
        foreign key (next_step_id) references ref_next_step (id)
);
