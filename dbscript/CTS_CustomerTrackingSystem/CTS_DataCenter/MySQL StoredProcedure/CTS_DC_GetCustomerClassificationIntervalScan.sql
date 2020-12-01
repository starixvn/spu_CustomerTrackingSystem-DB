/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetCustomerClassificationIntervalScan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustomerClassificationIntervalScan`(IN ip_NoOfRecord INT, IN ip_Batch INT, IN ip_ParentCategoryID INT)
	SQL SECURITY INVOKER
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
			[20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow.
            [20200923@Irena.Vo][141755]: Enhance SP
            
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
         CALL CTS_DC_GetCustomerClassificationIntervalScan (100,1,200);
	*/
    DECLARE lv_ScanTime DATETIME;
    DECLARE lv_ScanDate DATETIME;    
    DECLARE lv_LastScanTime DATETIME;
    DECLARE lv_LastScanDate DATETIME;
    DECLARE lv_TotalRecord BIGINT UNSIGNED;
	DECLARE lv_Batch INT UNSIGNED DEFAULT 1;
	  
    ### PERFORMANCE: START
    DECLARE		lv_ExecKey		BIGINT	UNSIGNED;
	DECLARE		lv_SPName		VARCHAR(200)  DEFAULT 'CTS_DC_GetCustomerClassificationIntervalScan' ;
    DECLARE		lv_StepID		INT;
	DECLARE 	lv_Notes	 		VARCHAR(500);
	DECLARE 	lv_StartTime		TIMESTAMP(4);
	DECLARE		lv_EndTime 		TIMESTAMP(4);
	DECLARE		lv_Duration 		BIGINT;	
    DECLARE		lv_LogTotalRecord	INT;
    DECLARE		lv_FromID		BIGINT;
    DECLARE		lv_ToID			BIGINT;

    SET		lv_ExecKey = CRC32((UUID_Short()));    
    SET		lv_Notes = '';# CONCAT('Input: ',ip_NoOfAssociation,'_', ip_NoOfBatch) ;		
    SET 	lv_StepID = 1;
    
    SET 	lv_StartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(lv_ExecKey, lv_StepID, lv_SPName,  lv_Notes, lv_StartTime);
	### PERFORMANCE: END
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ScanList;
	CREATE TEMPORARY TABLE Temp_ScanList(
		  CustID BIGINT UNSIGNED
        , SportGroupID SMALLINT UNSIGNED
        , CategoryID	SMALLINT UNSIGNED    
		, ID			INT SIGNED AUTO_INCREMENT
        ,INDEX	IX_Temp_ScanList_ID(ID)
        ,INDEX	IX_Temp_ScanList_CustID(CustID)
    );
    
	SET lv_ScanTime = CURRENT_TIME();
    SET lv_LastScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus WHERE ParentCategoryID = ip_ParentCategoryID);
    
	SET lv_ScanDate = DATE(lv_ScanTime);
    SET lv_LastScanDate = DATE(lv_LastScanTime);
    
    IF(lv_LastScanDate != lv_ScanDate)
    THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_ScanStatus(ScanTime, LastCustID, ScanStatus, ParentCategoryID)
		VALUES(lv_ScanTime, 0, 0, ip_ParentCategoryID);
	ELSE	
		SET lv_ScanTime = lv_LastScanTime;
    END IF;
    
    SET lv_TotalRecord = ip_Batch * ip_NoOfRecord ;
	
    -- INSERT CATEGORY TO SCAN
	INSERT INTO Temp_ScanList (CustID, SportGroupID, CategoryID)
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
                AND ccl.LastScannedDate <= DATE_SUB(lv_ScanDate, INTERVAL cat.ScanIntervalInSecond SECOND)
	LIMIT		lv_TotalRecord;
   
    -- IGNORE PROBATION LIST
    DELETE temp
    FROM Temp_ScanList AS temp
    INNER JOIN  CTS_DataCenter.ProbationAccountMonitor AS pro on pro.CustID = temp.CustID AND pro.SportGroupID = temp.SportGroupID
	INNER JOIN	CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.CategoryID
    WHERE cc.ParentID = ip_ParentCategoryID;
   
    -- RETURN RESULT
	SELECT 		(((temp.ID-1) DIV ip_NoOfRecord) + 1) AS BatchID
				, temp.CustID 		
				, temp.SportGroupID	
				, temp.CategoryID
	FROM 		Temp_ScanList	AS temp;     
	
	IF NOT EXISTS (SELECT 1 FROM Temp_ScanList LIMIT 1)
    THEN
		UPDATE  CTS_DataCenter.CTSCustomerClassification_ScanStatus
        SET		ScanStatus = 1
        WHERE	ScanTime = lv_ScanTime
			AND ParentCategoryID = ip_ParentCategoryID;
    END IF;
	
	### PERFORMANCE
	SET		lv_EndTime = CURRENT_TIMESTAMP(4);
    
	SELECT 	Count(1), Min(temp.CustID), Max(temp.CustID)
    INTO	lv_LogTotalRecord, lv_FromID, lv_ToID
    FROM	Temp_ScanList AS temp;    
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = lv_EndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, lv_StartTime, lv_EndTime)
            , z.TotalRecord = lv_LogTotalRecord
            , z.FromID = lv_FromID
            , z.ToID		= lv_ToID
    WHERE	z.ExecKey = lv_ExecKey AND z.StepID = lv_StepID ;     
    ### PERFORMANCE: END
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ScanList;
    
END$$

DELIMITER ;