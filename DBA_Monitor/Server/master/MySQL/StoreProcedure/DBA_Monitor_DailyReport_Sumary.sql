/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_DailyReport_Sumary`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_DailyReport_Sumary`()
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
			- CALL MonDB.DBA_Monitor_DailyReport_Sumary(); 
	*/
    DECLARE lv_ClassLogPartitionName_CheckDrop VARCHAR(20);
    SET lv_ClassLogPartitionName_CheckDrop = CONCAT('pm',EXTRACT(YEAR_MONTH FROM DATE_SUB(NOW(), INTERVAL 2 MONTH)));
    IF EXISTS (SELECT 1 FROM information_schema.partitions WHERE TABLE_NAME = 'CTSCustomerClassification_Log' AND PARTITION_NAME  = lv_ClassLogPartitionName_CheckDrop) THEN
		SELECT "Should be drop partition CTSCustomerClassification_Log" AS AlertMessage;
    END IF;
    
END$$
DELIMITER ;
