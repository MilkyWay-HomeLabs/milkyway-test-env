create table game_player_statistics
(
    game_id          char(36)     not null,
    player_id        bigint       not null,
    score_result     varchar(10)  null comment 'Win, lose or draw with score type',
    figures_captured varchar(100) null comment 'store in varchar list of figures taken from other player',
    primary key (game_id, player_id)
);

