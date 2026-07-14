create table seasons
(
    id               uuid          not null
        primary key,
    game_save_id     uuid          not null,
    name             varchar(100)  null,
    year             int           not null,
    status_id        int           null,
    ranking_id       int           null,
    current_month_id int default 0 not null,
    constraint seasons_game_statuses_id_fk
        foreign key (status_id) references statuses (id)
);

