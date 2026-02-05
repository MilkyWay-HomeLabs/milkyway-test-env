-- Unlock some galleries for users
INSERT INTO user_galleries (user_id, gallery_id, is_unlocked, unlocked_at, best_time_ms)
VALUES
    (
        (SELECT id FROM users WHERE username = 'wolf'),
        (SELECT id FROM galleries WHERE title = 'Gallery 1'), -- Assuming this title exists in galleries.sql
        true,
        NOW(),
        45000
    ),
    (
        (SELECT id FROM users WHERE username = 'wolf'),
        (SELECT id FROM galleries WHERE title = 'Gallery 11'),
        true,
        NOW() - INTERVAL '1 day',
        120000
    ),
    (
        (SELECT id FROM users WHERE username = 'hacman_player'),
        (SELECT id FROM galleries WHERE title = 'Gallery 1'),
        true,
        NOW(),
        NULL
    )
    ON CONFLICT (user_id, gallery_id) DO NOTHING;