create table genders
(
    id   int auto_increment
        primary key,
    name varchar(10) not null,
    constraint genders_id_uindex
        unique (id)
)
    engine = InnoDB;

