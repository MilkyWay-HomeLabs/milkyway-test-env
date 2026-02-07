create table ref_award
(
    id          int auto_increment
        primary key,
    name        varchar(100) not null,
    description varchar(255) null,
    constraint ref_award_pk_2
        unique (name)
);
