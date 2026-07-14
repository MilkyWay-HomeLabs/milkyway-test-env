create table difficulty
(
    id                 int auto_increment
        primary key,
    name               varchar(100)  not null,
    description        varchar(255)  null,
    best_move_requests int default 0 null
);

