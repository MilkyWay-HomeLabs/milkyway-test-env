create table template_round_date_calendar
(
    year             int                  not null,
    round_id         int                  not null,
    date             date                 null,
    tournament_id    int                  null,
    phase_id         int                  null,
    phase_round_id   int                  null,
    last_phase_round tinyint(1) default 0 null,
    month_id         int                  null,
    week_of_month    int                  null,
    day_of_week      int                  null,
    primary key (year, round_id)
);

