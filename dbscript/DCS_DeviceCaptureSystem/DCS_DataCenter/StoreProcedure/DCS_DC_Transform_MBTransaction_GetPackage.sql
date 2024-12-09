/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBTransaction_GetPackage`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBTransaction_GetPackage`(
        IN ip_NoOfTickets 	INT
    ,   IN ip_NoOfBatch 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20241205@Jonathan.Doan
	    Task : Transform Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
            - 20241205@Jonathan.Doan: Integrate Mobile App (Phase 2) [Redmine ID: #213401]

	    Param's Explanation (filtered by):
			CALL DCS_DC_Transform_MBTransaction_GetPackage(100, 3);
	*/
    DECLARE		lv_TotalRecord				INT UNSIGNED DEFAULT 0;
    DECLARE 	lv_FromTransID				BIGINT UNSIGNED DEFAULT 0;
    
    SET @currentBatch = 0;
    SET lv_TotalRecord = ip_NoOfTickets*ip_NoOfBatch;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CheckSameDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_SetBatchID;
    
	CREATE TEMPORARY TABLE Temp_CheckSameDevice(
			ID								BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceWithRawTransID		BIGINT UNSIGNED DEFAULT 0
		,	RecoverType						SMALLINT UNSIGNED DEFAULT 0

		,	FirstDeviceID					BIGINT UNSIGNED
		,	SecondDeviceID					BIGINT UNSIGNED
		,	ThirdDeviceID					BIGINT UNSIGNED
		,   BatchID							INT
	);
    
	CREATE TEMPORARY TABLE Temp_SetBatchID(
			ID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	BatchID						INT DEFAULT 0
	);
    
    /********************** Check Same Device ***********************************/
    INSERT INTO Temp_CheckSameDevice(ID, FirstDeviceID, SecondDeviceID, ThirdDeviceID)
    SELECT 	ID
		,   IFNULL(MBDeviceCodeMediaDRMID, 0) AS FirstDeviceID
		,   IFNULL(MBDeviceCodeMachineID, 0) AS SecondDeviceID
		,   IFNULL(MBDeviceCodeTaggingID, 0) AS ThirdDeviceID
	FROM DCS_DataCenter.MBTransaction
	WHERE ID >= lv_FromTransID
	ORDER BY ID ASC
	LIMIT lv_TotalRecord;
    
    CALL DCS_DataCenter.DCS_DC_Transform_MBDeviceMapping_UpdateTheSameDevice('Temp_CheckSameDevice');
    
    /********************** Set BatchID ***********************************/
    INSERT INTO Temp_SetBatchID(ID)
    SELECT DISTINCT SameDeviceWithRawTransID
    FROM Temp_CheckSameDevice;
    
    SELECT COUNT(ID)
    INTO @CountFirstDevice
    FROM Temp_SetBatchID;
    
    SET @RowId = 0;
    SET @NoOfBatch = CEIL(@CountFirstDevice / ip_NoOfBatch);
    
    UPDATE Temp_SetBatchID
	SET BatchID = CEIL(@RowId := @RowId + 1 / @NoOfBatch)
    ORDER BY (ID = 0) ASC, ID ASC;
    
    UPDATE Temp_CheckSameDevice AS tmpSD
		INNER JOIN Temp_SetBatchID AS tmpB ON tmpB.ID = tmpSD.SameDeviceWithRawTransID
	SET tmpSD.BatchID = tmpB.BatchID;
    
    /********************** RETURN OUTPUT ***********************************/
    SELECT	ID
		,	MBRawTransactionID
		,	SameDeviceWithRawTransID
        ,	RecoverType
        ,	FirstDeviceID
        ,	SecondDeviceID
        ,	ThirdDeviceID
        ,	BatchID
	FROM Temp_CheckSameDevice;
    
END$$
DELIMITER ;