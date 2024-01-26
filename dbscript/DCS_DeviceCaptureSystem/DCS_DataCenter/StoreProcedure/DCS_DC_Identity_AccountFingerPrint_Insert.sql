/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_AccountFingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_AccountFingerPrint_Insert`(
	IN ip_AccountFingerPrintJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231127@Jonathan.Doan
	    Task : Insert into AccountFingerPrint
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231127@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_AccountFingerPrint_Insert('[{"AccountID":1,"RawFingerPrintID":2},{"AccountID":3,"RawFingerPrintID":4}]');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountFingerprintInsert;
    
	CREATE TEMPORARY TABLE Temp_AccountFingerprintInsert(
			ID									INT UNSIGNED AUTO_INCREMENT		PRIMARY KEY 
        ,	AccountID							BIGINT UNSIGNED 				
        ,	RawFingerPrintID					BIGINT UNSIGNED
		,	IsNewAccountFingerprint				TINYINT DEFAULT 1
    );
    
    INSERT IGNORE INTO Temp_AccountFingerprintInsert(AccountID, RawFingerPrintID)
	SELECT 	DISTINCT
			tmp.AccountID
		,	tmp.RawFingerPrintID
    FROM JSON_TABLE(
			ip_AccountFingerPrintJson,
			 "$[*]" COLUMNS(
							AccountID			BIGINT UNSIGNED	PATH "$.AccountID"
						,	RawFingerPrintID	BIGINT UNSIGNED PATH "$.RawFingerPrintID"
					)
		) AS tmp
	WHERE tmp.AccountID IS NOT NULL
		AND tmp.RawFingerPrintID IS NOT NULL;

    /* === Add index === */
	ALTER TABLE Temp_AccountFingerprintInsert
	ADD INDEX IX_Temp_AccountFingerprintInsert_AccountID_RawFingerPrintID (AccountID, RawFingerPrintID);
    
    UPDATE Temp_AccountFingerprintInsert AS tmp
		INNER JOIN DCS_DataCenter.AccountFingerprint AS af ON af.AccountID = tmp.AccountID AND af.RawFingerPrintID = tmp.RawFingerPrintID
	SET IsNewAccountFingerprint = 0;
    
	INSERT IGNORE INTO DCS_DataCenter.AccountFingerprint(AccountID, RawFingerPrintID, CreatedDate)
    SELECT	AccountID
        ,	RawFingerPrintID
        ,	lv_CreatedDate
    FROM Temp_AccountFingerprintInsert
	WHERE IsNewAccountFingerprint = 1;
    
END$$

DELIMITER ;
