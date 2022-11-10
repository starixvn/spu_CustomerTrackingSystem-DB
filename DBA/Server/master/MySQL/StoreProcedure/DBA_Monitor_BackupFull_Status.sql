/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_BackupFull_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_BackupFull_Status`()
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20220110@Aries.Nguyen
		Task:		Monitor Daily Report 
		DB:			MonDB
		Original:

		Revisions:
			- 20220110@Aries.Nguyen: Created [Redmine ID: #167040]
            
		Param's Explanation (filtered by): 
        Example:
			- CALL MonDB.DBA_Monitor_BackupFull_Status(); 
	*/
    DECLARE lv_DateBackup 			DATE;
    DECLARE lv_BackupFolder 		VARCHAR(100);
    DECLARE lv_LastBackupFolder 	VARCHAR(100);
	DECLARE lv_DateOfWeek 			INT;
    SET lv_DateOfWeek = DAYOFWEEK(CURDATE());   
    
	IF lv_DateOfWeek > 6 THEN
		SET lv_DateOfWeek = 0;
    END IF;

    
    SET  lv_DateBackup =  DATE_ADD(CURDATE(), INTERVAL (1 + lv_DateOfWeek) * -1 DAY);
    SET lv_BackupFolder = CONCAT('/var/cts/dump/CTS_BK_', DATE_FORMAT(lv_DateBackup, '%Y%m%d')); 
    
    SELECT file_name
    INTO lv_LastBackupFolder
	FROM CTS_Log.dba_BackupTask_Log 
	ORDER BY ID DESC 
	LIMIT 1;
    
    IF lv_LastBackupFolder != lv_BackupFolder THEN
		SELECT CONCAT('Backup: ', 'Fail') AS MessageMetric;
        LEAVE sp;
	END IF;
    
    SELECT CONCAT('Backup: ', 'Success ', lv_LastBackupFolder) AS MessageMetric;
END$$
DELIMITER ;

