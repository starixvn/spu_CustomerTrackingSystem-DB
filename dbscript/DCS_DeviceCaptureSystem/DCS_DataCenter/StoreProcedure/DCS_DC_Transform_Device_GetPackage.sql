/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Device_GetPackage`;

DELIMITER $$
CREATE DEFINER=`dcsService`@`%` PROCEDURE `DCS_DC_Transform_Device_GetPackage`(
        IN ip_NoOfTickets INT
    ,   IN ip_NoOfBatch INT
)
     SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20200908@Bobby.Nguyen
	    Task : Get List TransID to process Device Transform
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
            - 20201012@Casey.Huynh: Add Trace Performance log
            - 20210510@Aries.Nguyen: Remove insert log dba_SP_PerformanceStats [Redmine ID: #154792]
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]  

	    Param's Explanation (filtered by):
			CALL DCS_DC_Transform_Device_GetPackage(2, 10);
	*/
    DECLARE 	CONST_DEVICE_TRANSFORM_MINTRANSID 		INT 		DEFAULT 1;
    DECLARE 	CONST_DEVICE_TRANSFORM_MINCREATEDDATE 	INT 		DEFAULT 2;
	
	DECLARE		lv_TotalRecord		INT UNSIGNED DEFAULT 0;
	DECLARE		lv_RateBatch		DECIMAL(4,2);
    DECLARE 	lv_FromTransID		BIGINT UNSIGNED;
    DECLARE		lv_FromCreatedDate	DATE;

    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans(	
		    TransID		BIGINT	UNSIGNED PRIMARY KEY
		,   BatchID		INT
        ,   CreatedDate	DATE
    ) ENGINE=MEMORY; 
    
	SET lv_TotalRecord 	    = ip_NoOfTickets*ip_NoOfBatch;
    SET lv_FromTransID 	    = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_DEVICE_TRANSFORM_MINTRANSID);

	SET @RowId = 0;
    INSERT INTO Temp_Trans (TransID, CreatedDate, BatchID)
    SELECT  TransID
        ,   CreatedDate
        ,   BatchID
    FROM (
		SELECT	@RowId := @RowId + 1
		    ,   ts.TransID
            ,   ts.CreatedDate
		    ,   CEIL(@RowId/ip_NoOfTickets) AS BatchID
		FROM DCS_DataCenter.Transaction AS ts
		WHERE ts.TransId >= lv_FromTransID
        ORDER BY ts.AccountID
		LIMIT lv_TotalRecord
    ) AS t;
	
    SET lv_FromTransID = IFNULL((SELECT MIN(TransID) FROM Temp_Trans), lv_FromTransID); 
    SET lv_FromCreatedDate = IFNULL((SELECT MIN(CreatedDate) FROM Temp_Trans), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL -2 WEEK));

    IF(lv_FromTransID IS NOT NULL AND lv_FromTransID > 0) THEN
		UPDATE DCS_DataCenter.SystemSetting
		SET 	VValue = CONCAT('', lv_FromTransID)
			,	UpdatedTime = CURRENT_TIMESTAMP()
		WHERE ID = CONST_DEVICE_TRANSFORM_MINTRANSID;
    END IF;

    IF(lv_FromCreatedDate IS NOT NULL) THEN
		UPDATE DCS_DataCenter.SystemSetting
		SET 	VValue = CONCAT('', lv_FromCreatedDate)
			,	UpdatedTime = CURRENT_TIMESTAMP()
		WHERE ID = CONST_DEVICE_TRANSFORM_MINCREATEDDATE;
    END IF;
    
    #RETURN OUTPUT
    SELECT  TransID
        ,   BatchID
    FROM Temp_Trans;
    
END$$
DELIMITER ;
