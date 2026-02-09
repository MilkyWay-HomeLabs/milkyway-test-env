create table confirmation_tokens
(
    token_id        bigint                                  not null
        primary key,
    user_id         bigint                                  not null,
    token           varchar(255)                            not null,
    created_at      timestamp   default current_timestamp() not null,
    expiration_date datetime                                not null,
    type            varchar(15) default 'CONFIRMATION'      not null,
    constraint confirmation_tokens_users_user_id_fk
        foreign key (user_id) references users (user_id)
)
    engine = InnoDB;

