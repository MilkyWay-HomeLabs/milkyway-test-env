create table rules
(
    id            int auto_increment
        primary key,
    name          varchar(50) null,
    total_time    int         not null comment 'store starting game time per player',
    time_per_move int         not null comment 'store time added per move'
);

