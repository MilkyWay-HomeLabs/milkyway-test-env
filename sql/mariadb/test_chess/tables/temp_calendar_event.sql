create table temp_calendar_event
(
    id            int auto_increment
        primary key,
    tournament_id int     not null,
    phase_id      int     not null,
    round         int     not null,
    month         tinyint not null comment 'from 1 to 12',
    week          tinyint not null comment '1-4',
    day_of_week   int     not null comment '1-monday, 7-sunday',
    constraint ref_calendar_template_pk_2
        unique (tournament_id, round, phase_id)
);
