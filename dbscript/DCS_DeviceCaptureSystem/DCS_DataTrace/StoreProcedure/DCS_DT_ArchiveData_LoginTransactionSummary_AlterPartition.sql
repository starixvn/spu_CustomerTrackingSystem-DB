/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_ArchiveData_LoginTransactionSummary_AlterPartition`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_ArchiveData_LoginTransactionSummary_AlterPartition`(
    IN ip_RetentionPartitions INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231020@Jonathan.Doan
	Task : Delete data from LoginTransactionSummary
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231020@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_ArchiveData_LoginTransactionSummary_AlterPartition(2);
	*/
	
    DECLARE lv_CurrentDate			DATETIME DEFAULT NOW();
    DECLARE lv_LastWeekDate			DATETIME DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL ip_RetentionPartitions + 1 WEEK);
    DECLARE lv_LastPartition		VARCHAR(50) DEFAULT CONCAT('pw',YEARWEEK(lv_LastWeekDate));
    
    DECLARE lv_DropPartition		LONGTEXT;
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
    WHERE p.TABLE_SCHEMA = 'DCS_DataTrace' 
		AND p.`TABLE_NAME` = 'LoginTransactionSummary';
        
	SELECT GROUP_CONCAT(tmp.PartitionName SEPARATOR ',')
    INTO lv_DropPartition
    FROM Temp_Partition AS tmp
    WHERE tmp.PartitionName <= lv_LastPartition;
    
    IF lv_DropPartition IS NOT NULL THEN        
		SET @sql = CONCAT('ALTER TABLE DCS_DataTrace.LoginTransactionSummary DROP PARTITION ',lv_DropPartition,';');
		PREPARE stmt FROM  @sql;
		EXECUTE stmt; 
		DEALLOCATE PREPARE stmt;
    END IF;
    
    WITH RECURSIVE week_numbers AS (
		SELECT YEARWEEK(DATE_ADD(lv_CurrentDate, INTERVAL 1 WEEK)) AS week_number, CONCAT('pw',YEARWEEK(lv_CurrentDate)) AS partition_name, 1 AS rn
		UNION ALL
		SELECT YEARWEEK(DATE_ADD(lv_CurrentDate, INTERVAL rn + 1 WEEK)) AS week_number, CONCAT('pw',YEARWEEK(DATE_ADD(lv_CurrentDate, INTERVAL rn WEEK))) AS partition_name, rn + 1
		FROM week_numbers
		WHERE rn < ip_RetentionPartitions
	)
	SELECT GROUP_CONCAT(CONCAT('PARTITION ',partition_name,' VALUES LESS THAN (',week_number,')') SEPARATOR ',')
    INTO lv_AlterPartition
	FROM week_numbers AS wno
		LEFT JOIN Temp_Partition AS tmp ON tmp.PartitionName = wno.partition_name
	WHERE tmp.PartitionOrdinalPosition IS NULL;
    
    IF lv_AlterPartition IS NOT NULL THEN
		SET @sql = CONCAT('
			ALTER TABLE DCS_DataTrace.LoginTransactionSummary
			REORGANIZE PARTITION pw299999 INTO (    
			',lv_AlterPartition,',
			PARTITION pw299999 VALUES LESS THAN MAXVALUE) 
			;
		');
		PREPARE stmt FROM  @sql;
		EXECUTE stmt; 
		DEALLOCATE PREPARE stmt;
    END IF;
    
END$$
DELIMITER ;