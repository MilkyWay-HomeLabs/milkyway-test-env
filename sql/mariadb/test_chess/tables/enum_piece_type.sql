create table enum_piece_type
(
    id         tinyint unsigned not null
        primary key,
    code       char             not null,
    name       varchar(20)      not null,
    value      decimal(4, 1)    not null,
    sort_order tinyint unsigned not null,
    constraint uk_piece_code
        unique (code)
)
    comment 'Dictionary of piece types';
