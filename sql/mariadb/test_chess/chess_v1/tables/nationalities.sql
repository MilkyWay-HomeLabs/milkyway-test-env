create table nationalities
(
    id        int      not null
        primary key,
    name      tinytext null,
    code      tinytext null,
    region_id int      null,
    constraint nationalities_regions_id_fk
        foreign key (region_id) references regions (id)
);

