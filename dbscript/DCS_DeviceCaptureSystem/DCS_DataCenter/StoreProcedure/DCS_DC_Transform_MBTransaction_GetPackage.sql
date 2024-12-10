/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBTransaction_GetPackage`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBTransaction_GetPackage`(
        IN ip_LimitTotalRecord 	INT
    ,   IN ip_NoOfBatch 		INT
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
			CALL DCS_DC_Transform_MBTransaction_GetPackage(3, 3);
	*/
    DECLARE	lv_TotalRecord INT UNSIGNED DEFAULT 0;
    DECLARE lv_FromTransID BIGINT UNSIGNED DEFAULT 0;
    
    SET @currentBatch = 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_CheckSameDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_SetBatchID;
    
	CREATE TEMPORARY TABLE Temp_MBTransaction(
			ID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBRawTransactionID			BIGINT UNSIGNED
		,	SameDeviceID				BIGINT UNSIGNED DEFAULT 0
		,	RecoverType					SMALLINT UNSIGNED DEFAULT 0

		,	MBDeviceCodeMediaDRMID		BIGINT UNSIGNED
		,	MBDeviceCodeMachineID		BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID		BIGINT UNSIGNED
		,   BatchID						INT
	);
    
	CREATE TEMPORARY TABLE Temp_CheckSameDevice(
			ID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceID				BIGINT UNSIGNED DEFAULT 0
		,	RecoverType					SMALLINT UNSIGNED DEFAULT 0

		,	FirstDeviceID				BIGINT UNSIGNED
		,	SecondDeviceID				BIGINT UNSIGNED
		,	ThirdDeviceID				BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_SetBatchID(
			SameDeviceID				BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	BatchID						INT DEFAULT 0
	);
    
    /********************** Check Same Device ***********************************/
    INSERT INTO Temp_MBTransaction(ID, MBRawTransactionID, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
    SELECT 	ID
		,   MBRawTransactionID
		,   IFNULL(MBDeviceCodeMediaDRMID, 0) AS MBDeviceCodeMediaDRMID
		,   IFNULL(MBDeviceCodeMachineID, 0) AS MBDeviceCodeMachineID
		,   IFNULL(MBDeviceCodeTaggingID, 0) AS MBDeviceCodeTaggingID
	FROM DCS_DataCenter.MBTransaction
	WHERE ID >= lv_FromTransID
	ORDER BY ID ASC
	LIMIT ip_LimitTotalRecord;
    
    INSERT INTO Temp_CheckSameDevice(ID, FirstDeviceID, SecondDeviceID, ThirdDeviceID)
    SELECT 	MBRawTransactionID AS ID
		,   MBDeviceCodeMediaDRMID AS FirstDeviceID
		,   MBDeviceCodeMachineID AS SecondDeviceID
		,   MBDeviceCodeTaggingID AS ThirdDeviceID
	FROM Temp_MBTransaction;
    
    CALL DCS_DataCenter.DCS_DC_Transform_MBDeviceMapping_UpdateTheSameDevice('Temp_CheckSameDevice');
    
    /********************** Set BatchID ***********************************/
    INSERT INTO Temp_SetBatchID(SameDeviceID)
    SELECT DISTINCT SameDeviceID
    FROM Temp_CheckSameDevice;
    
    SELECT COUNT(SameDeviceID)
    INTO @CountFirstDevice
    FROM Temp_SetBatchID;
    
    SET @RowId = 0;
    SET @NoOfBatch = CEIL(@CountFirstDevice / ip_NoOfBatch);
    
    UPDATE Temp_SetBatchID
	SET BatchID = CEIL(@RowId := @RowId + 1 / @NoOfBatch)
    ORDER BY (SameDeviceID = 0) ASC, SameDeviceID ASC;
    
    UPDATE Temp_MBTransaction AS tmp
		INNER JOIN Temp_CheckSameDevice AS tmpSD ON tmpSD.ID = tmp.MBRawTransactionID
		INNER JOIN Temp_SetBatchID AS tmpB ON tmpB.SameDeviceID = tmpSD.SameDeviceID
	SET tmp.BatchID = tmpB.BatchID,
		tmp.SameDeviceID = tmpSD.SameDeviceID,
		tmp.RecoverType = tmpSD.RecoverType;
    
    /********************** RETURN OUTPUT ***********************************/
    SELECT	tmp.ID AS TransID
		,	tmp.MBRawTransactionID
        ,	tmp.MBDeviceCodeMediaDRMID
        ,	tmp.MBDeviceCodeMachineID
        ,	tmp.MBDeviceCodeTaggingID
		,	tmpSD.SameDeviceID
        ,	tmpSD.RecoverType
        ,	tmpB.BatchID
	FROM Temp_MBTransaction AS tmp
		INNER JOIN Temp_CheckSameDevice AS tmpSD ON tmpSD.ID = tmp.MBRawTransactionID
		INNER JOIN Temp_SetBatchID AS tmpB ON tmpB.SameDeviceID = tmpSD.SameDeviceID;
    
END$$
DELIMITER ;