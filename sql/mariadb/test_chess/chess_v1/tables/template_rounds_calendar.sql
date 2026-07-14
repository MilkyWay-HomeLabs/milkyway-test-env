create table template_rounds_calendar
(
    tournament_id    int                  not null,
    phase_id         int                  not null,
    round_id         int                  not null,
    last_phase_round tinyint(1) default 0 null,
    month_id         int                  null,
    week_of_month    int                  null,
    day_of_week      int                  null,
    primary key (tournament_id, phase_id, round_id)
);

