create table games
(
    id       int auto_increment
        primary key,
    name     varchar(100)         null,
    enable   tinyint(1) default 0 null,
    icon_url varchar(255)         null,
    page_url varchar(255)         null,
    constraint games_id_uindex
        unique (id)
)
    engine = InnoDB;

