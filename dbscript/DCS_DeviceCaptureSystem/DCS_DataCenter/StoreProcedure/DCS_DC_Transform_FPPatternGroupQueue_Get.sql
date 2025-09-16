/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FPPatternGroupQueue_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_FPPatternGroupQueue_Get` (
        IN ip_IsProcessed   TINYINT
    ,   IN ip_NoOfTickets   INT
    ,   IN ip_NoOfBatch     INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20250822@Casey.Huynh
		Task : Insert to Raw Details Table 
		DB: FPS_RawTrans
		Original:

		Revisions:
            - 20250826@Casey.Huynh: Created, AI Power Device Fingerprint AND Remove FPJs [Redmine ID: #236716]

		Param's Explanation (filtered by):
        
		Example:
			CALL DCS_DC_Transform_RawPattern_Insert('[{"FPGroupCode":"A1B2C3D4E5F6G7H8I9J0KLMNOPQRSTU","FPGroupDetails":"hard_details1","CreatedDate":"2025-09-04"}]');
	*/
    
    DECLARE 	CONST_SYSTEMSETTINGID_MINRAWTRANSID	INT DEFAULT 314127;

	DECLARE		lv_TotalRecord	INT UNSIGNED DEFAULT 0;
    DECLARE 	lv_FromTransID	BIGINT UNSIGNED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction; 
    
    CREATE TEMPORARY TABLE Temp_Transaction(		
		    MinTransID			BIGINT UNSIGNED
        ,   MaxTransID			BIGINT UNSIGNED
    ); 
	
    SET lv_TotalRecord 	= ip_NoOfTickets*ip_NoOfBatch;
    SET lv_FromTransID 	= IFNULL((SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_SYSTEMSETTINGID_MINRAWTRANSID), 0);

    SET lv_TotalRecord = ip_NoOfTickets * ip_NoOfBatch;
	set @RowId = 0;
    
    INSERT INTO Temp_Transaction (MinTransID, MaxTransID)
    SELECT  MIN(TransID) AS MinTransID
        ,   MAX(TransID) AS MaxTransID
	FROM (
		SELECT	@RowId := @RowId+1
			,   rt.TransID	
			,   CEIL(@RowId/ip_NoOfTickets) as batchID
		FROM 	DCS_DataCenter.RawTransaction AS rt
		WHERE	rt.TransID >= lv_FromTransID
		    AND rt.IsProcessed = ip_IsProcessed
		LIMIT	 lv_TotalRecord
	) AS t
	GROUP BY batchID;
    

    /*****UPDATE MaxTransID in SystemSetting****************************************************/
    SET lv_FromTransID = (SELECT MIN(MinTransID) FROM Temp_Transaction);
    
    IF lv_FromTransID IS NOT NULL AND lv_FromTransID > 0 THEN
		UPDATE DCS_DataCenter.SystemSetting AS sys
		SET sys.VValue 	= CONCAT('', lv_FromTransID),
		    sys.UpdatedTime = CURRENT_TIMESTAMP()
		WHERE ID = CONST_SYSTEMSETTINGID_MINRAWTRANSID;
    END IF;
    
    /*****RETURN OUTPUT****************************************************/
    SELECT	tmpTT.MinTransID
	    ,   tmpTT.MaxTransID
	FROM Temp_Transaction AS tmpTT;

END$$
DELIMITER ;
