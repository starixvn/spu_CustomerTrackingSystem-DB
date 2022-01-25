/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_ArchiveTransaction_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_ArchiveTransaction_Status`()
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
			- CALL MonDB.DBA_Monitor_ArchiveTransaction_Status(); 
	*/
    DECLARE lv_PartitionName VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_tolower_ci;

    SET lv_PartitionName = CONCAT('pw',YEARWEEK(DATE_SUB(NOW(), INTERVAL 2 WEEK)));
	
    IF NOT EXISTS (SELECT 1 FROM information_schema.partitions WHERE TABLE_NAME = 'Transaction180' AND PARTITION_NAME = lv_PartitionName AND TABLE_ROWS > 0) THEN
		SELECT CONCAT('ArchiveTransaction: ', 'Fail - PartitionName ', lv_PartitionName) AS MessageMetric;
        LEAVE sp;
    END IF;

    SELECT CONCAT('ArchiveTransaction: ', 'Success - PartitionName ', lv_PartitionName) AS MessageMetric;
END$$
DELIMITER ;
