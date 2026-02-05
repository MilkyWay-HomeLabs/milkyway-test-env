create table users
(
    id             bigint                                not null
        primary key,
    email          varchar(255)                          null,
    first_name     varchar(255)                          null,
    last_name      varchar(255)                          null,
    login          varchar(45)                           not null,
    age            int                                   null,
    birth_date     date                                  null,
    gender_id      int                                   null,
    nationality_id int                                   null,
    updated_at     timestamp default current_timestamp() null comment 'used for store timestamp of updated user data for all tables in nebula database',
    constraint UK_ow0gan20590jrb00upg3va2fn
        unique (login),
    constraint users_genders_id_fk
        foreign key (gender_id) references genders (id),
    constraint users_nationalities_id_fk
        foreign key (nationality_id) references nationalities (id)
)
    engine = InnoDB;

