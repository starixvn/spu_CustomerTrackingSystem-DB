/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_TransactionEvolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_TransactionEvolution_Insert`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231128@Jonathan.Doan
		Task : Insert into DCS_DataCenter.TransactionEvolution
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231128@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Identity_TransactionEvolution_Insert('Temp_TransactionEvolution');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionEvolution;
        
	CREATE TEMPORARY TABLE Temp_TransactionEvolution(
			RawFingerPrintID			BIGINT UNSIGNED		PRIMARY KEY
        ,	RecoverRawFingerPrintID		BIGINT UNSIGNED		NOT NULL
        ,	DeviceID					BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord					TINYINT		 		DEFAULT 1
    );
    
	SET @sql = CONCAT('INSERT IGNORE INTO Temp_TransactionEvolution(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID) 
						SELECT 	DISTINCT
								RawFingerPrintID
							,	RecoverRawFingerPrintID
							,	DeviceID
                        FROM ', ip_TableName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
	 
    UPDATE Temp_TransactionEvolution AS tmp
		INNER JOIN DCS_DataCenter.TransactionEvolution AS te ON te.RawFingerPrintID = tmp.RawFingerPrintID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.TransactionEvolution(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID, CreatedDate)
	SELECT	RawFingerPrintID
		,	RecoverRawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_TransactionEvolution
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
