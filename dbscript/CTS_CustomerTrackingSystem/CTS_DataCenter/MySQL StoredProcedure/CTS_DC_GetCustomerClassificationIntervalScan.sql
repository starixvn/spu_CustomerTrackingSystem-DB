DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationIntervalScan$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationIntervalScan(IN ip_NoOfRecord INT, IN ip_Batch INT, IN ip_ParentCategoryID INT) 
BEGIN
	/*
		Created:	[20200612@Casey.Huynh][135324]
		Task:		Return the auto tag customer list that reach to scanning schedule (interval refer to CTS_DataCenter.CustomerCategory.IntervalScan
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			[20200701@Casey.Huynh]		[135324]: Chagne Flow and Store more Info
            [20200820@Casey.Huynh]		[139061]: Remove USE INDEX 
            [20200903@Harvey.Nguyen]	[140869]: Add ParentID 
			
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
         CALL CTS_DC_GetCustomerClassificationIntervalScan (100,1,200);
	*/
    DECLARE vrScanTime DATETIME;
    DECLARE vrScanDate DATETIME;    
    DECLARE vrLastScanTime DATETIME;
    DECLARE vrLastScanDate DATETIME;
    DECLARE vrTotalRecord BIGINT UNSIGNED;
	DECLARE vrBatch INT UNSIGNED DEFAULT 1;
	  
    
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'CTS_DC_GetCustomerClassificationIntervalScan' ;
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
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    DROP TEMPORARY TABLE IF EXISTS temp_scanList;
	CREATE TEMPORARY TABLE temp_scanList(
		CustID BIGINT UNSIGNED
        , SportGroupID SMALLINT UNSIGNED
        , CategoryID	SMALLINT UNSIGNED    
		, ID			INT SIGNED AUTO_INCREMENT
        ,INDEX	IX_temp_scanList_ID(ID)
        ,INDEX	IX_temp_scanList_CustID(CustID)
    );
    
	SET vrScanTime = CURRENT_TIME();
    SET vrLastScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus WHERE ParentCategoryID = ip_ParentCategoryID);
    
	SET vrScanDate = DATE(vrScanTime);
    SET vrLastScanDate = DATE(vrLastScanTime);
    
    IF(vrLastScanDate != vrScanDate)
    THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_ScanStatus(ScanTime, LastCustID, ScanStatus, ParentCategoryID)
		VALUES(vrScanTime, 0, 0, ip_ParentCategoryID);
	ELSE	
		SET vrScanTime = vrLastScanTime;
    END IF;
    
    SET vrTotalRecord = ip_Batch * ip_NoOfRecord ;
	    
	INSERT INTO temp_scanList (CustID, SportGroupID, CategoryID)
	SELECT 		ccl.CustID 			AS CustID
				, ccl.SportGroupID	AS SportGroupID
                , ccl.CategoryID	AS CategoryID
    FROM		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN	CTS_DataCenter.CustomerCategory AS cat
				ON ccl.CategoryID = cat.CategoryID
	WHERE		cat.IsActive = 1
				AND cat.IsUsedManually = 0
                AND cat.ScanIntervalInSecond > 0
                AND cat.ParentID = ip_ParentCategoryID
                AND ccl.LastScannedDate <= DATE_SUB(vrScanDate, INTERVAL cat.ScanIntervalInSecond SECOND)
	LIMIT		vrTotalRecord;
    
	SELECT 		(((tmpList.ID-1) DIV ip_NoOfRecord) + 1) AS BatchID
				, tmpList.CustID 		
				, tmpList.SportGroupID	
				, tmpList.CategoryID
	FROM 		temp_scanList	AS tmpList;     
	
	IF NOT EXISTS (SELECT 1 FROM temp_scanList LIMIT 1)
    THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_ScanStatus
        SET		ScanStatus = 1
        WHERE	ScanTime = vrScanTime
			AND ParentCategoryID = ip_ParentCategoryID;
    END IF;
	
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
	SELECT 	Count(1), Min(tas.CustID), Max(tas.CustID)
    INTO	vrLgTotalRecord, vrFromID, vrToID
    FROM	temp_scanList AS tas;    
    
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

