create table game_saves
(
    id                          uuid                      not null,
    player_id                   bigint                    not null,
    status_id                   int                       null,
    current_game_date           date default '2024-01-01' not null,
    current_game_year           int  default 2024         null,
    current_game_month          int  default 0            null,
    next_step_id                int  default 1            null,
    next_tournament_id_to_build int  default 0            null,
    next_phase_id_to_build      int  default 0            null,
    primary key (id, player_id),
    constraint game_saves_game_save_next_step_id_fk
        foreign key (next_step_id) references game_save_next_step (id),
    constraint game_saves_game_statuses_id_fk
        foreign key (status_id) references statuses (id)
);

