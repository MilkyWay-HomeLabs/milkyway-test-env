create table users
(
    user_id    bigint auto_increment
        primary key,
    username   varchar(255)                           not null,
    password   varchar(255)                           not null,
    email      varchar(255)                           not null,
    created_at timestamp  default current_timestamp() null,
    updated_at timestamp  default current_timestamp() null on update current_timestamp(),
    verified   tinyint(1) default 0                   null,
    blocked    tinyint(1) default 0                   null,
    constraint users_pk
        unique (username),
    constraint users_pk_2
        unique (email)
)
    engine = InnoDB;

