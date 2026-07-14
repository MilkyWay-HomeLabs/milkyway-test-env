create table achievements
(
    id          int auto_increment
        primary key,
    name        varchar(100) null,
    min_value   int          null,
    max_value   int          null,
    description varchar(255) null,
    icon_url    varchar(255) null comment 'path to the icon'
)
    engine = InnoDB;

