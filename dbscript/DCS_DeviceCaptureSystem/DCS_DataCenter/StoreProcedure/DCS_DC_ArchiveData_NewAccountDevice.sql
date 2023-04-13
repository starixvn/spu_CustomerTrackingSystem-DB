/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_NewAccountDevice`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_NewAccountDevice`()
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	202304130@Jonathan.Doan
		Task:		Archive Sent Transactions
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 202304130@Jonathan.Doan: Created [Redmine ID: #185185]
		Param's Explanation (filtered by):

		Example:
			- CALL DCS_DataCenter.DCS_DC_ArchiveData_NewAccountDevice();
	*/ 
	
    DECLARE lv_CurrentDate			DATETIME DEFAULT NOW();
    DECLARE lv_LastWeekDate			DATETIME DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 1 WEEK);
    DECLARE lv_CurrentPartition		VARCHAR(50) DEFAULT CONCAT('p',10000000+YEARWEEK(lv_LastWeekDate));
    
    DECLARE lv_DeletePartition		LONGTEXT;
    DECLARE lv_AlterPartition		LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Partition;
    CREATE TEMPORARY TABLE Temp_Partition(
			PartitionOrdinalPosition INT PRIMARY KEY
        ,	PartitionName	VARCHAR(100)
        
        ,	INDEX IX_Temp_Partition_PartitionName(PartitionName)
    );
    
    INSERT INTO Temp_Partition(PartitionOrdinalPosition, PartitionName)
    SELECT	p.Partition_Ordinal_Position
		,	p.Partition_Name 
    FROM INFORMATION_SCHEMA.`PARTITIONS` AS p
    WHERE p.TABLE_SCHEMA = 'DCS_DataCenter' 
		AND p.`TABLE_NAME` = 'NewAccountDevice';
        
	SELECT GROUP_CONCAT(tmp.PartitionName SEPARATOR ',')
    INTO lv_DeletePartition
    FROM Temp_Partition AS tmp
    WHERE tmp.PartitionName <= lv_CurrentPartition;
    
	SET @sql = CONCAT('DELETE FROM NewAccountDevice PARTITION (',lv_DeletePartition,');');

	PREPARE stmt1 FROM  @sql;
	EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1;
    
    WITH RECURSIVE week_numbers AS (
		SELECT 10000000+YEARWEEK(lv_CurrentDate) AS week_number, 1 AS rn
		UNION ALL
		SELECT 10000000+YEARWEEK(DATE_ADD(lv_CurrentDate, INTERVAL rn WEEK)) AS week_number, rn + 1
		FROM week_numbers
		WHERE rn < 10
	)
	SELECT GROUP_CONCAT(CONCAT('PARTITION p',week_number,' VALUES LESS THAN (',week_number,')') SEPARATOR ',')
    INTO lv_AlterPartition
	FROM week_numbers;
    
    SET @sqlAlterTable = CONCAT('
		ALTER TABLE DCS_DataCenter.NewAccountDevice
		PARTITION BY RANGE(Status*10000000+YEARWEEK(createdDate))(  
		PARTITION p10000000 VALUES LESS THAN (10000000),     
		',lv_AlterPartition,',
		PARTITION p19999999 VALUES LESS THAN MAXVALUE) 
		;
    ');
    
	PREPARE stmt2 FROM  @sqlAlterTable;
	EXECUTE stmt2; 
	DEALLOCATE PREPARE stmt2;
    
END$$

DELIMITER ;