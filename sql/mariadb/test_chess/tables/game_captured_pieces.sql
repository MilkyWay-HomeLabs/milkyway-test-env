create table game_captured_pieces
(
    game_id           uuid                                  not null,
    game_save_id      uuid                                  not null,
    move_number       smallint unsigned                     not null,
    piece_type_id     tinyint unsigned                      not null,
    is_white          tinyint(1)                            not null comment 'TRUE if piece was white',
    captured_by_white tinyint(1)                            not null comment 'TRUE if piece was captured by white',
    board_position    varchar(2)                            not null comment 'Field where picture was taken (ex. e4)',
    timestamp         timestamp default current_timestamp() null,
    primary key (game_id, move_number, piece_type_id),
    constraint game_captured_pieces_game_save_id_fk
        foreign key (game_save_id) references game_save (id)
            on delete cascade,
    constraint game_captured_pieces_ibfk_1
        foreign key (piece_type_id) references enum_piece_type (id)
)
    comment 'Taken figures in game by human player';

create index idx_game_moves
    on game_captured_pieces (game_id, move_number);

create index piece_type_id
    on game_captured_pieces (piece_type_id);

