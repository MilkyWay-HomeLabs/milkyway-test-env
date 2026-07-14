create table regions
(
    id   int auto_increment
        primary key,
    name varchar(20) not null,
    constraint regions_id_uindex
        unique (id)
)
    engine = InnoDB;

