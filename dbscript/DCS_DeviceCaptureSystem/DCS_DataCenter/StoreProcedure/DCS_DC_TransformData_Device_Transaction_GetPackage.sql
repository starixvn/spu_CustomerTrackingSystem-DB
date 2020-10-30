DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_Device_Transaction_GetPackage$$

CREATE DEFINER=`dcsService`@`%` PROCEDURE `DCS_DC_TransformData_Device_Transaction_GetPackage`(IN ip_NoOfTickets INT, IN ip_NoOfBatch INT)
BEGIN
	/*
	Created: 202009008@Bobby.Nguyen
	Task : Get List TransID to process Device Transform
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
	
	DECLARE		totalRecord		INT UNSIGNED DEFAULT 0;
	DECLARE		rateBatch		DECIMAL(4,2);
    DECLARE 	fromTransID		BIGINT;
    DECLARE		fromCreatedDate	DATE;
    DECLARE		vGroupLookup	varchar(128);
    DECLARE		vKeyLookup		varchar(128);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
    CREATE TEMPORARY TABLE Temp_Trans 
    (	
		TransID			BIGINT	UNSIGNED PRIMARY KEY
		, BatchID		INT
        , CreatedDate	DATE
    ) engine=MEMORY; 
    
	SET rateBatch 		= 1;#MonDB.DCS_f_GetRateBatch();	
    SET ip_NoOfTickets 	= ceil(ip_NoOfTickets*rateBatch);
	SET totalRecord 	= ip_NoOfTickets*ip_NoOfBatch;
    SET vGroupLookup 	= 'DCS_Device_Transform';
    SET vKeyLookup 		= 'MinTransId';
    SET fromTransID 	= IFNULL((SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE VGroup=vGroupLookup AND VName=vKeyLookup), 0);
    
	SET @RowId = 0;
    INSERT INTO Temp_Trans (TransID, CreatedDate, BatchID)
    SELECT TransID, CreatedDate, BatchID
    FROM (
		SELECT	@RowId := @RowId + 1
				, ts.TransID
                , ts.CreatedDate
				, ceil(@RowId/ip_NoOfTickets) AS BatchID
		FROM 	DCS_DataCenter.Transaction AS ts
		WHERE	ts.TransId >= fromTransID
		LIMIT totalRecord
    ) AS t;
	
    #UPDATE back fromTransID
    SET fromTransID = IFNULL((SELECT MIN(TransID) FROM Temp_Trans), fromTransID);
    SET fromCreatedDate = IFNULL((SELECT MIN(CreatedDate) FROM Temp_Trans), date_add(current_timestamp(), interval -2 week));
    INSERT INTO DCS_DataCenter.SystemSetting (VGroup, VName, VValue, UpdatedTime)
    SELECT VGroup, VName, VValue, UpdatedTime
    FROM (
    SELECT vGroupLookup AS VGroup
		, vKeyLookup AS VName
		, CONCAT('', fromTransID) AS VValue
        , current_timestamp() AS UpdatedTime
	UNION ALL 
    SELECT vGroupLookup
		, 'MinCreatedDate'
		, CONCAT('', fromCreatedDate)
        , current_timestamp() AS UpdatedTime
	) as t
	ON DUPLICATE KEY UPDATE 
		VValue = t.VValue
		,UpdatedTime = t.UpdatedTime
    ;
    
    #RETURN OUTPUT
    SELECT TransID, BatchID
    FROM Temp_Trans;
END$$
DELIMITER ;
