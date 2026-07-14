create table nationalities
(
    id        int auto_increment
        primary key,
    name      varchar(100) null,
    code      varchar(3)   not null,
    region_id int          null,
    constraint nationalities_code_uindex
        unique (code),
    constraint nationalities_id_uindex
        unique (id),
    constraint nationalities_regions_id_fk
        foreign key (region_id) references regions (id)
)
    engine = InnoDB;

