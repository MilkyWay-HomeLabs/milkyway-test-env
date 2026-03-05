create table confirmation_tokens
(
    token_id        bigint auto_increment
        primary key,
    user_id         bigint                                  not null,
    token           varchar(255)                            not null,
    created_at      timestamp   default current_timestamp() not null,
    expiration_date datetime                                not null,
    type            varchar(15) default 'CONFIRMATION'      not null,
    version         int                                     null,
    jti             varchar(100)                            null,
    revoked         tinyint(1)  default 0                   null
);

create index confirmation_tokens_users_user_id_fk
    on confirmation_tokens (user_id);

    engine = InnoDB;
