create table swiss_national_groups
(
    id          int auto_increment
        primary key,
    name        varchar(50)  null,
    description varchar(255) null,
    region_id   int          not null
);

