create table ref_status
(
    id          int          not null
        primary key,
    name        varchar(100) null,
    description varchar(255) null,
    constraint ref_status_pk
        unique (name)
);
