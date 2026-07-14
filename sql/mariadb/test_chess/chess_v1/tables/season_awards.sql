create table season_awards
(
    season_id    uuid   not null,
    award_id     int    not null,
    game_save_id uuid   not null,
    owner_id     bigint null,
    owner_score  double null,
    player_score double null,
    primary key (season_id, award_id)
);

