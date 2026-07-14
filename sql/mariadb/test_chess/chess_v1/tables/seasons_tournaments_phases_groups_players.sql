create table seasons_tournaments_phases_groups_players
(
    season_id     uuid          not null,
    tournament_id int           not null,
    phase_id      int           not null,
    group_id      int           not null,
    player_id     bigint        not null,
    game_save_id  uuid          not null,
    position      int           null,
    points        int default 0 null,
    wins          int default 0 null,
    loses         int default 0 null,
    draws         int default 0 null,
    matches       int default 0 null,
    pair_id       int default 1 not null,
    primary key (season_id, tournament_id, phase_id, group_id, player_id)
);

