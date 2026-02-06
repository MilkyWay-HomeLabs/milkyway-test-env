create table enum_game_result
(
    id         tinyint unsigned                       not null
        primary key,
    code       varchar(20)                            not null,
    name       varchar(100)                           not null,
    points     decimal(3, 1)                          not null,
    sort_order tinyint unsigned                       not null,
    is_active  tinyint(1) default 1                   null,
    created_at timestamp  default current_timestamp() null,
    constraint uk_result_code
        unique (code)
)
    comment 'Dictionary of scores chess games';
