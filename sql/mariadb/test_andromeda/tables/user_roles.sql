create table user_roles
(
    user_role_id int auto_increment,
    user_id      bigint not null,
    role_id      int    not null,
    primary key (user_id, role_id),
    constraint user_roles_pk
        unique (user_role_id),
    constraint user_roles_roles_role_id_fk
        foreign key (role_id) references roles (role_id),
    constraint user_roles_users_user_id_fk
        foreign key (user_id) references users (user_id)
)
    engine = InnoDB;

