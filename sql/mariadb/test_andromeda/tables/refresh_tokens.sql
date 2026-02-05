create table refresh_tokens
(
    token_id        bigint auto_increment
        primary key,
    user_id         bigint                                  not null,
    token           varchar(500)                            not null,
    expiration_date datetime                                not null,
    created_at      timestamp   default current_timestamp() null,
    type            varchar(10) default 'REFRESH'           not null,
    constraint refresh_tokens_users_user_id_fk
        foreign key (user_id) references users (user_id)
)
    engine = InnoDB;

