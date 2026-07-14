create table game_save_rankings
(
    game_save_id uuid          not null,
    ranking_id   int           not null,
    status_id    int default 1 null,
    primary key (ranking_id, game_save_id),
    constraint game_save_rankings_statuses_id_fk
        foreign key (status_id) references statuses (id)
);

