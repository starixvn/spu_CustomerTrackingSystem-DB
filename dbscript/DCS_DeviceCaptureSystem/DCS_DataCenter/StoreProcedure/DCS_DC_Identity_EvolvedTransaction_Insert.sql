/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_EvolvedTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_EvolvedTransaction_Insert`(
		IN ip_EvolvedTransactionJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231128@Jonathan.Doan
		Task : Insert into DCS_DataCenter.EvolvedTransaction
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231128@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Identity_EvolvedTransaction_Insert('[{"RawFingerPrintID":1,"RecoverRawFingerPrintID":2,"DeviceID":2}]');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_EvolvedTransactionInsert;
        
	CREATE TEMPORARY TABLE Temp_EvolvedTransactionInsert(
			RawFingerPrintID			BIGINT UNSIGNED		PRIMARY KEY
        ,	RecoverRawFingerPrintID		BIGINT UNSIGNED		NOT NULL
        ,	DeviceID					BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord					TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_EvolvedTransactionInsert(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID)
	SELECT	tmp.RawFingerPrintID
		,	MIN(tmp.RecoverRawFingerPrintID) AS RecoverRawFingerPrintID
		,	MIN(tmp.DeviceID) AS DeviceID
    FROM JSON_TABLE(
			ip_EvolvedTransactionJson,
			 "$[*]" COLUMNS(
							RawFingerPrintID			BIGINT UNSIGNED	PATH "$.RawFingerPrintID"
						,	RecoverRawFingerPrintID		BIGINT UNSIGNED PATH "$.RecoverRawFingerPrintID"
						,	DeviceID					BIGINT UNSIGNED PATH "$.DeviceID"
					)
		) AS tmp
	WHERE tmp.RawFingerPrintID IS NOT NULL
		AND tmp.RecoverRawFingerPrintID IS NOT NULL
		AND tmp.DeviceID IS NOT NULL
	GROUP BY tmp.RawFingerPrintID;
	 
    UPDATE Temp_EvolvedTransactionInsert AS tmp
		INNER JOIN DCS_DataCenter.EvolvedTransaction AS te ON te.RawFingerPrintID = tmp.RawFingerPrintID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.EvolvedTransaction(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID, CreatedDate)
	SELECT	RawFingerPrintID
		,	RecoverRawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_EvolvedTransactionInsert
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
