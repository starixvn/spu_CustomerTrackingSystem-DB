/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_AccountFingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_AccountFingerPrint_Insert`(
	IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231127@Jonathan.Doan
	    Task : Insert AccountFingerPrint
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231127@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_AccountFingerPrint_Insert('Temp_Table');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountFingerprint;
    
	CREATE TEMPORARY TABLE Temp_AccountFingerprint(
			ID							INT UNSIGNED AUTO_INCREMENT		PRIMARY KEY 
        ,	AccountID					BIGINT UNSIGNED 				
        ,	RawFingerPrintID			BIGINT UNSIGNED
		,	IsNewAccountFingerprint		TINYINT DEFAULT 1
    );
    
	SET @sql = CONCAT('INSERT INTO Temp_AccountFingerprint(AccountID, RawFingerPrintID) 
						SELECT 	DISTINCT
								AccountID
							,	RawFingerPrintID 
                        FROM ', ip_TableName,'
                        WHERE AccountID IS NOT NULL
							AND RawFingerPrintID IS NOT NULL');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    UPDATE Temp_AccountFingerprint AS tmp
		INNER JOIN DCS_DataCenter.AccountFingerprint AS af ON af.AccountID = tmp.AccountID AND af.RawFingerPrintID = tmp.RawFingerPrintID
	SET IsNewAccountFingerprint = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.AccountFingerprint(AccountID, RawFingerPrintID, CreatedDate)
    SELECT	DISTINCT
			AccountID
        ,	RawFingerPrintID
        ,	lv_CreatedDate
    FROM Temp_AccountFingerprint
	WHERE IsNewAccountFingerprint = 1;
    
END$$

DELIMITER ;
