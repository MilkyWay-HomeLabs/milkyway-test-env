create table refresh_token_incidents
(
    id            bigint auto_increment
        primary key,
    token_id      bigint                                not null,
    user_id       bigint                                not null,
    jti           varchar(255)                          not null,
    version       varchar(255)                          not null,
    incident_time timestamp default current_timestamp() null,
    ip_address    varchar(45)                           null,
    user_agent    text                                  null,
    description   text                                  null,
    constraint refresh_token_incidents_ibfk_1
        foreign key (token_id) references refresh_tokens (token_id),
    constraint refresh_token_incidents_ibfk_2
        foreign key (user_id) references users (user_id)
);
    engine = InnoDB;

create index token_id
    on refresh_token_incidents (token_id);

create index user_id
    on refresh_token_incidents (user_id);
