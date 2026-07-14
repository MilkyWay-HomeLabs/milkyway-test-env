create table game_scores
(
    id                 uuid                               not null
        primary key,
    status             varchar(100) default 'NOT STARTED' null,
    type               varchar(100)                       null,
    engine_score       float                              null,
    normalized_score   float                              null,
    percentage_score   float                              null,
    white_player_id    bigint                             not null,
    black_player_id    bigint                             not null,
    black_player_score varchar(50)                        null,
    white_player_score varchar(50)                        null
);

