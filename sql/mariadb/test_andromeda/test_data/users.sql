-- Password for everyone: password ($2a$10$vI8A7vR6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R)
INSERT INTO users (user_id, username, password, email, verified, token_version)
VALUES (1, 'admin', '$2a$10$vI8A7vR6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R', 'admin@example.com', 1, 1),
       (2, 'user1', '$2a$10$vI8A7vR6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R', 'user1@example.com', 1, 1),
       (3, 'newuser', '$2a$10$vI8A7vR6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R6.R.R', 'new@example.com', 0, 1);
