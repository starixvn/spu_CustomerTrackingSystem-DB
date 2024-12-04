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
    DECLARE 	CONST_SYSTEMSETTINGID_MINTRANSID 			INT 		DEFAULT 1;
    DECLARE 	CONST_SYSTEMSETTINGID_MINCREATEDDATE 		INT 		DEFAULT 2;
	
	DECLARE		lv_TotalRecord				INT UNSIGNED DEFAULT 0;
	DECLARE		lv_RateBatch				DECIMAL(4,2);
    DECLARE 	lv_FromTransID				BIGINT UNSIGNED;
    DECLARE		lv_FromInsertedTime			DATETIME;
    DECLARE		lv_CountAccountID			INT;
    DECLARE		lv_NoOfBatchOfAccountID		INT;
    DECLARE		lv_SkipDeviceMapping		TINYINT(1) UNSIGNED;

    DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_MBAccount;
    
    CREATE TEMPORARY TABLE Temp_MBTransaction(	
		    ID						BIGINT	UNSIGNED PRIMARY KEY
		,   MBRawTransactionID		BIGINT	UNSIGNED
		,   MBAccountID				BIGINT	UNSIGNED
		,   BatchID					INT
    );
    
    CREATE TEMPORARY TABLE Temp_MBAccount(	
		    ID						BIGINT	UNSIGNED PRIMARY KEY
		,   BatchID					INT
    );
    
	SET lv_TotalRecord 	    	= ip_NoOfTickets*ip_NoOfBatch;
    SET lv_FromTransID 	    	= (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_SYSTEMSETTINGID_MINTRANSID);

    INSERT INTO Temp_MBTransaction(ID, MBRawTransactionID, MBAccountID)
	SELECT	ID
		,   MBRawTransactionID
		,   MBAccountID
	FROM DCS_DataCenter.MBTransaction
	WHERE ID >= lv_FromTransID
	ORDER BY ID ASC
	LIMIT lv_TotalRecord;
    
    ALTER TABLE Temp_MBTransaction
    ADD KEY IX_Temp_MBTransaction_MBAccountID (MBAccountID),
    ADD KEY IX_Temp_MBTransaction_MBRawTransactionID (MBRawTransactionID);
    
	SET lv_FromTransID = IFNULL((SELECT MIN(MBRawTransactionID) FROM Temp_MBTransaction), lv_FromTransID); 
    
    INSERT INTO Temp_MBAccount(ID)
	SELECT DISTINCT MBAccountID
	FROM Temp_MBTransaction;
    
    SET lv_CountAccountID = (SELECT COUNT(1) FROM Temp_MBAccount);
    
	SET @RowId = 0;
    IF(lv_CountAccountID IS NOT NULL AND lv_CountAccountID > 0) THEN
		SET lv_NoOfBatchOfAccountID = CEIL(lv_CountAccountID / ip_NoOfBatch);
    
		UPDATE Temp_MBAccount
		SET BatchID = CEIL(@RowId := @RowId + 1 / lv_NoOfBatchOfAccountID)
		ORDER BY ID;
        
        UPDATE Temp_MBTransaction AS tmpT
			INNER JOIN Temp_MBAccount AS tmpA ON tmpA.ID = tmpT.MBAccountID
		SET tmpT.BatchID = tmpA.BatchID;

		IF(lv_FromTransID IS NOT NULL AND lv_FromTransID > 0) THEN
			UPDATE DCS_DataCenter.SystemSetting
			SET VValue = CONCAT('', lv_FromTransID),
				UpdatedTime = CURRENT_TIMESTAMP()
			WHERE ID = CONST_SYSTEMSETTINGID_MINTRANSID;
		END IF;
		
		#RETURN OUTPUT
		SELECT  ID
			,   BatchID
		FROM Temp_MBTransaction;
    END IF;
    
END$$
DELIMITER ;