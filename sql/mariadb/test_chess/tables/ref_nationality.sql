create table ref_nationality
(
    id        int      not null
        primary key,
    name      tinytext null,
    code      tinytext null,
    region_id int      null,
    constraint ref_nationality_pk_2
        unique (name) using hash,
    constraint ref_nationality_pk_3
        unique (code) using hash,
    constraint ref_nationality_ref_region_id_fk
        foreign key (region_id) references ref_region (id)
);
