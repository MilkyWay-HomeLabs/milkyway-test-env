-- Insert sample users
INSERT INTO users (username, email, external_auth_id)
VALUES
    ('wolf', 'wolf@milkyway.test', 'auth0|wolf_123'),
    ('hacman_player', 'player@hacman.test', 'auth0|player_456'),
    ('test_user', 'test@example.com', 'local|test_789')
    ON CONFLICT (username) DO NOTHING;