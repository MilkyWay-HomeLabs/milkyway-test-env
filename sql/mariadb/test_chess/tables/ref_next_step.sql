create table ref_next_step
(
    id          int auto_increment
        primary key,
    name        varchar(50)     null,
    description varchar(255)    null,
    priority    int default 100 null comment 'lower means it should be first executed, used to organize order in situation if more than one step is executed in same calendar day',
    constraint ref_next_step_pk
        unique (name)
);
