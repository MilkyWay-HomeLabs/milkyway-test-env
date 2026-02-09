create table enum_game_score_type
(
    id           tinyint unsigned                       not null
        primary key,
    code         varchar(30)                            not null,
    name         varchar(100)                           not null,
    description  varchar(255)                           null,
    points_white decimal(3, 1)                          not null,
    points_black decimal(3, 1)                          not null,
    sort_order   tinyint unsigned                       not null,
    is_active    tinyint(1) default 1                   null,
    created_at   timestamp  default current_timestamp() null,
    constraint uk_score_type_code
        unique (code)
)
    comment 'Dictionary of type chess results';
