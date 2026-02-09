create table temp_tournament_phases
(
    id                     int                  not null
        primary key,
    tournament_id          int                  not null,
    phase_id               int                  not null,
    name                   varchar(50)          not null,
    description            varchar(255)         null,
    groups_count           int                  null,
    group_size             int                  null,
    type_id                int                  null,
    promotion_position     int                  null,
    degradation_position   int                  null,
    points_multiplier      double               null,
    starting_month         int        default 1 null comment '1 - for Jan, 12 - for Dec',
    updated_at_month_start tinyint(1) default 0 null comment 'flag if may be updated at START_MONTH process',
    constraint temp_tournament_phases_pk
        unique (tournament_id, phase_id),
    constraint temp_tournament_phases_ref_tournament_id_fk
        foreign key (tournament_id) references ref_tournament (id),
    constraint temp_tournament_phases_ref_tournament_phase_type_id_fk
        foreign key (type_id) references ref_tournament_phase_type (id)
);
