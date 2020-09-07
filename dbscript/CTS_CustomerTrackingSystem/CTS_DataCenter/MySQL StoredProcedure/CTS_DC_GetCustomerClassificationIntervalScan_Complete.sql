DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationIntervalScan_Complete$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationIntervalScan_Complete(IN ip_CustSport JSON, IN ip_ParentCategoryID INT)
BEGIN
	/*
		Created:	[20200625@Casey.Huynh][135324]
		Task:		Update Last Scanned If completed
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			[20200701@Casey.Huynh]135324]: Chagne Flow and Store more Info
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
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
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET vrScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus WHERE ParentCategoryID = ip_ParentCategoryID);
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
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cl
    INNER JOIN 	Temp_CustSport AS tmpCs
				ON cl.CustID = tmpCs.CustID
				AND	cl.SportGroupID = tmpCs.SportGroupID
	INNER JOIN	CustomerCategory cusCate ON cl.CategoryID = cusCate.CategoryID
    SET			cl.LastScannedDate = GREATEST(vrScanDate, cl.LastScannedDate)
    WHERE 		cusCate.ParentID = ip_ParentCategoryID;
    
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

