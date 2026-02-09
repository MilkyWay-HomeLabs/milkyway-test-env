create table access_tokens
(
    token_id        bigint auto_increment
        primary key,
    user_id         bigint                                  null,
    token           varchar(500)                            not null,
    expiration_date datetime                                not null,
    created_at      timestamp   default current_timestamp() null,
    type            varchar(10) default 'ACCESS'            not null,
    constraint access_tokens_ibfk_1
        foreign key (user_id) references users (user_id)
)
    engine = InnoDB;

create index user_id
    on access_tokens (user_id);

