/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Identity_TransactionEvolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Identity_TransactionEvolution_Insert`(
		IN ip_TransactionEvolutionJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231206@Jonathan.Doan
		Task : Insert into DCS_Extra.TransactionEvolution
		DB: DCS_Extra
		Original:

		Revisions:
			- 20231206@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Identity_TransactionEvolution_Insert('[{"RawFingerPrintID":1,"RecoverRawFingerPrintID":2,"DeviceID":2}]');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionEvolutionInsert;
        
	CREATE TEMPORARY TABLE Temp_TransactionEvolutionInsert(
			RawFingerPrintID			BIGINT UNSIGNED		PRIMARY KEY
        ,	RecoverRawFingerPrintID		BIGINT UNSIGNED		NOT NULL
        ,	DeviceID					BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord					TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_TransactionEvolutionInsert(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID)
	SELECT	tmp.RawFingerPrintID
		,	MIN(tmp.RecoverRawFingerPrintID) AS RecoverRawFingerPrintID
		,	MIN(tmp.DeviceID) AS DeviceID
    FROM JSON_TABLE(
			ip_TransactionEvolutionJson,
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
	 
    UPDATE Temp_TransactionEvolutionInsert AS tmp
		INNER JOIN DCS_Extra.TransactionEvolution AS te ON te.RawFingerPrintID = tmp.RawFingerPrintID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_Extra.TransactionEvolution(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID, CreatedDate)
	SELECT	RawFingerPrintID
		,	RecoverRawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_TransactionEvolutionInsert
    WHERE IsNewRecord = 1;
    
END$$

DELIMITER ;
