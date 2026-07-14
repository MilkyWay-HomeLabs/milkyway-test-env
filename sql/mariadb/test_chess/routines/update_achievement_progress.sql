DELIMITER //
CREATE DEFINER = 'chess'@'%' PROCEDURE update_achievement_progress()
BEGIN
    DECLARE exit_handler BOOLEAN DEFAULT FALSE;
    DECLARE updated_rows INT;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET exit_handler = TRUE;
        ROLLBACK;
        INSERT INTO update_log (update_type, update_time)
        VALUES ('achievement_progress_error', NOW());
    END;

    START TRANSACTION;

    UPDATE game_save gs
        INNER JOIN v_achievement_progress v ON gs.id = v.game_save_id
    SET gs.achievement_progress = v.calculated_progress
    WHERE gs.achievement_progress IS NULL
       OR gs.achievement_progress != v.calculated_progress;

    SET updated_rows = ROW_COUNT();

    IF NOT exit_handler THEN
        INSERT INTO update_log (update_type, update_time)
        VALUES (CONCAT('achievement_progress_success (rows: ', updated_rows, ')'), NOW());
        COMMIT;
    END IF;
END;
//
DELIMITER ;