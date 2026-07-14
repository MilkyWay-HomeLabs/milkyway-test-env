create table update_log
(
    id          int auto_increment
        primary key,
    update_type varchar(50)                           null,
    update_time timestamp default current_timestamp() null
);
