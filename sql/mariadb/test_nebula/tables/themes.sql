create table themes
(
    id   int auto_increment
        primary key,
    name varchar(20) null,
    constraint themes_id_uindex
        unique (id)
)
    engine = InnoDB;

