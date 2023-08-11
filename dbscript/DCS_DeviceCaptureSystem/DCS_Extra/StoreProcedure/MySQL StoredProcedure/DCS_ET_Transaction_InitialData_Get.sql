/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transaction_InitialData_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transaction_InitialData_Get`(
		ip_BatchSize INT
	,	ip_LastTransID_ParameterID INT
	,	ip_LastPartitionName_ParameterID INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230809@Casey.Huynh
		Task :		Get Transaction IPID
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230809@Casey.Huynh: Created [Redmine ID: 192402]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Transaction_InitialData_Get(10, 1001, 1002);
    
    */
    DECLARE lv_LastTransID 			BIGINT UNSIGNED;
    DECLARE lv_LastPartitionName 	VARCHAR(50);
	DECLARE lv_NextPartition		VARCHAR(50);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Partition;
    CREATE TEMPORARY TABLE Temp_Partition(
			PartitionOrdinalPosition INT PRIMARY KEY
        ,	PartitionName	VARCHAR(100)
        
        ,	INDEX IX_Temp_Partition_PartitionName(PartitionName)
    );
    
	SELECT st.VValue
    INTO lv_LastTransID
    FROM DCS_Extra.SystemSetting AS st
    WHERE st.ID = ip_LastTransID_ParameterID;
    
    SELECT st.VValue
    INTO lv_LastPartitionName
    FROM DCS_Extra.SystemSetting AS st
    WHERE st.ID = ip_LastPartitionName_ParameterID;
	
    IF lv_LastPartitionName IS NOT NULL AND lv_LastTransID > 0 THEN
		SET @sql = 	CONCAT("SELECT TransID 
							INTO @result
							FROM DCS_Extra.Transaction07 PARTITION(",lv_LastPartitionName,")
							WHERE TransID < ",lv_LastTransID,"
								AND IPInfoID IS NULL
								AND IPID > 0
							LIMIT 1");
        PREPARE stmt1 FROM  @sql;
		EXECUTE stmt1;
        
		IF IFNULL(@result,0) > 0 THEN
			SET @sql = 	CONCAT("SELECT 	TransID
									,	IPID
									,	'",lv_LastPartitionName,"' AS PartitionName
								FROM DCS_Extra.Transaction07 PARTITION(",lv_LastPartitionName,")
								WHERE TransID < ",lv_LastTransID,"
									AND IPInfoID IS NULL
									AND IPID > 0
								ORDER BY TransID DESC
								LIMIT ",ip_BatchSize);
			PREPARE stmt1 FROM  @sql;
			EXECUTE stmt1; 
        ELSE
			INSERT INTO Temp_Partition(PartitionOrdinalPosition, PartitionName)
			SELECT	p.Partition_Ordinal_Position
				,	p.Partition_Name 
			FROM INFORMATION_SCHEMA.`PARTITIONS` AS p
			WHERE p.TABLE_SCHEMA = 'DCS_Extra' 
				AND p.`TABLE_NAME` = 'Transaction07';
        
			SELECT	tmp.PartitionName
			INTO lv_NextPartition
			FROM Temp_Partition AS tmp
			WHERE tmp.PartitionName < lv_LastPartitionName
			ORDER BY PartitionOrdinalPosition DESC
			LIMIT 1;
            
			SET @sql = 	CONCAT("SELECT 	TransID
									,	IPID
									,	'",lv_NextPartition,"' AS PartitionName
								FROM DCS_Extra.Transaction07 PARTITION(",lv_NextPartition,")
								WHERE TransID < ",lv_LastTransID,"
									AND IPInfoID IS NULL
									AND IPID > 0
								ORDER BY TransID DESC
								LIMIT ",ip_BatchSize);
        
			DEALLOCATE PREPARE stmt1;
			PREPARE stmt1 FROM @sql;
			EXECUTE stmt1;
		END IF;

		DEALLOCATE PREPARE stmt1;
    END IF;	
END$$

DELIMITER ;
