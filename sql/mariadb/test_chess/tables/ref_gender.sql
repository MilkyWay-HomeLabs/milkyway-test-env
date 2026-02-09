create table ref_gender
(
    id   int      not null
        primary key,
    name tinytext null,
    constraint ref_gender_pk
        unique (name) using hash
);
