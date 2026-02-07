create table ref_theme
(
    id   int          not null
        primary key,
    name varchar(100) null,
    constraint ref_theme_pk_2
        unique (name)
);

