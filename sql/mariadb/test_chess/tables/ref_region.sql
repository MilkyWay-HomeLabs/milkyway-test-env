create table ref_region
(
    id   int      not null
        primary key,
    name tinytext null,
    constraint ref_region_pk
        unique (name) using hash
);
