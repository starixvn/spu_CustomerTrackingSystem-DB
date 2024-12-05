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
	    Created: 20241129@Lando.Vu
	    Task : Transform Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
            - 20241129@Lando.Vu: Integrate Mobile App (Phase 2) [Redmine ID: #213401]

	    Param's Explanation (filtered by):
			CALL DCS_DC_Transform_MBTransaction_GetPackage(100, 2);
	*/
    DECLARE		lv_TotalRecord				INT UNSIGNED DEFAULT 0;
    DECLARE 	lv_FromTransID				BIGINT UNSIGNED DEFAULT 0;
    
    SET @currentBatch = 0;
    SET lv_TotalRecord = ip_NoOfTickets*ip_NoOfBatch;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_SetBatchID;
    
    CREATE TEMPORARY TABLE Temp_MBTransaction(	
		    ID							BIGINT	UNSIGNED PRIMARY KEY
		,   MBRawTransactionID			BIGINT	UNSIGNED
		,   MBDeviceCodeMediaDRMID		BIGINT	UNSIGNED
		,   MBDeviceCodeMachineID		BIGINT	UNSIGNED
		,   MBDeviceCodeTaggingID		BIGINT	UNSIGNED
		,   BatchID						INT
    );
    
	CREATE TEMPORARY TABLE Temp_SetBatchID(
			ID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	BatchID						INT DEFAULT 0

		,	FirstDeviceID				BIGINT UNSIGNED
		,	SecondDeviceID				BIGINT UNSIGNED
		,	ThirdDeviceID				BIGINT UNSIGNED
	);
    
    INSERT INTO Temp_MBTransaction(ID, MBRawTransactionID, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
	SELECT	ID
		,   MBRawTransactionID
		,   IFNULL(MBDeviceCodeMediaDRMID, 0) AS MBDeviceCodeMediaDRMID
		,   IFNULL(MBDeviceCodeMachineID, 0) AS MBDeviceCodeMachineID
		,   IFNULL(MBDeviceCodeTaggingID, 0) AS MBDeviceCodeTaggingID
	FROM DCS_DataCenter.MBTransaction
	WHERE ID >= lv_FromTransID
	ORDER BY ID ASC
	LIMIT lv_TotalRecord;
    
    /********************** Check Same Device ***********************************/
    INSERT INTO Temp_SetBatchID(ID, FirstDeviceID, SecondDeviceID, ThirdDeviceID)
    SELECT 	ID
		,	MBDeviceCodeMediaDRMID AS FirstDeviceID
		,	MBDeviceCodeMachineID AS SecondDeviceID
		,	MBDeviceCodeTaggingID AS ThirdDeviceID
    FROM Temp_MBTransaction;
        
    CALL DCS_DC_Transform_MBTransaction_SetBatchID('Temp_SetBatchID', ip_NoOfBatch);
    
	#RETURN OUTPUT
	SELECT  ID
		,   BatchID
	FROM Temp_SetBatchID;
    
END$$
DELIMITER ;