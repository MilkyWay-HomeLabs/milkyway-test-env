create table enum_keypass
(
    id          tinyint unsigned                      not null
        primary key,
    code        varchar(20)                           not null,
    name        varchar(100)                          not null,
    description varchar(255)                          null,
    created_at  timestamp default current_timestamp() null,
    constraint uk_result_code
        unique (code)
)
    comment 'Dictionary of scores chess games';
