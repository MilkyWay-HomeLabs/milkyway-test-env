create table template_tournament_phases
(
    tournament_id        int                         not null,
    phase_id             int                         not null,
    name                 varchar(50)                 null,
    description          varchar(255)                null,
    groups_count         int    default 1            not null,
    group_size           int    default 2            not null,
    type_id              int    default 1            not null,
    promotion_position   int    default 1            null,
    degradation_position int    default `group_size` null,
    points_multiplier    double default 1            null,
    primary key (tournament_id, phase_id)
);

