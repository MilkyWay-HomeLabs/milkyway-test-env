create table ref_achievement_type
(
    id          int auto_increment
        primary key,
    name        varchar(100) not null,
    description varchar(255) null,
    constraint achievement_type_pk_2
        unique (name)
);
