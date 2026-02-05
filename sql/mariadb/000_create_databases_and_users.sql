-- creating databases
CREATE DATABASE IF NOT EXISTS `test_andromeda` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `test_nebula`    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `test_chess`     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `test_robak`     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `test_racer`     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `test_element`   CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- users and passwords
CREATE
USER IF NOT EXISTS `wolf`@`%`      IDENTIFIED BY 'wolf-PASSWORD';
CREATE
USER IF NOT EXISTS `andromeda`@`%` IDENTIFIED BY 'andromeda-PASSWORD';
CREATE
USER IF NOT EXISTS `nebula`@`%`    IDENTIFIED BY 'nebula-PASSWORD';
CREATE
USER IF NOT EXISTS `chess`@`%`     IDENTIFIED BY 'chess-PASSWORD';
CREATE
USER IF NOT EXISTS `robak`@`%`     IDENTIFIED BY 'robak-PASSWORD';
CREATE
USER IF NOT EXISTS `racer`@`%`     IDENTIFIED BY 'racer-PASSWORD';
CREATE
USER IF NOT EXISTS `element`@`%`   IDENTIFIED BY 'element-PASSWORD';

-- granting privileges
GRANT ALL PRIVILEGES ON `test_andromeda`.* TO `wolf`@`%`;
GRANT ALL PRIVILEGES ON `test_nebula`.*    TO `wolf`@`%`;
GRANT ALL PRIVILEGES ON `test_chess`.*     TO `wolf`@`%`;
GRANT ALL PRIVILEGES ON `test_robak`.*     TO `wolf`@`%`;
GRANT ALL PRIVILEGES ON `test_racer`.*     TO `wolf`@`%`;
GRANT ALL PRIVILEGES ON `test_element`.*   TO `wolf`@`%`;

GRANT ALL PRIVILEGES ON `test_andromeda`.* TO `andromeda`@`%`;
GRANT ALL PRIVILEGES ON `test_nebula`.*    TO `nebula`@`%`;
GRANT ALL PRIVILEGES ON `test_chess`.*     TO `chess`@`%`;
GRANT ALL PRIVILEGES ON `test_robak`.*     TO `robak`@`%`;
GRANT ALL PRIVILEGES ON `test_racer`.*     TO `racer`@`%`;
GRANT ALL PRIVILEGES ON `test_element`.*   TO `element`@`%`;

FLUSH PRIVILEGES;
