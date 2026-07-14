-- sql
DELIMITER //
CREATE DEFINER = 'chess'@'%' EVENT achievement_progress_update_event
ON SCHEDULE EVERY 1 HOUR
STARTS '2025-07-20 09:27:42'
ENABLE
DO
BEGIN
    CALL update_achievement_progress();
END;
//
DELIMITER ;