/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetCustomerClassificationIntervalScan_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustomerClassificationIntervalScan_Complete`(IN ip_CustSport JSON)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	[20200625@Casey.Huynh][135324]
		Task:		Update Last Scanned If completed
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			[20200701@Casey.Huynh][135324]: Chagne Flow and Store more Info
			- 20201214-20201229@Irena.Vo: Ignore select data by ParentID. Remove logic update LastScannedDate [RedmineID: #145951]

		Param's Explanation (filtered by):
            - ip_CategoryIDList: ex: '1,2,3'       
	*/
    DECLARE vrScanTime DATETIME;
    DECLARE vrScanDate DATETIME;    
        
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'CTS_DC_GetCustomerClassificationIntervalScan_Complete' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrLgTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = '';# CONCAT('Input: ',ip_NoOfAssociation,'_', ip_NoOfBatch) ;		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);

	### PERFORMANCE: END
    
	SET vrScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus);
	SET vrScanDate = DATE(vrScanTime);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSport;    
	CREATE TEMPORARY TABLE Temp_CustSport 
    (	  
		  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED        
        , PRIMARY KEY	PK_Temp_CustSport_CTSCustID(CustID, SportGroupID)    
    );     
    
    INSERT INTO Temp_CustSport(CustID, SportGroupID)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
		 )) as tmpTable;
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification_ScanStatus
    SET			LastCustID = (SELECT MAX(CustID) FROM Temp_CustSport)
    WHERE		ScanTime = vrScanTime;
    
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
	SELECT 	Count(1), Min(tas.CustID), Max(tas.CustID)
    INTO	vrLgTotalRecord, vrFromID, vrToID
    FROM	Temp_CustSport AS tas;    
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrLgTotalRecord
            , z.FromID = vrFromID
            , z.ToID		= vrToID
    WHERE	z.ExecKey = vrExecKey AND z.StepID = vrStepID ;    
    
    ### PERFORMANCE: END 
END$$
DELIMITER ;

