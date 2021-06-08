/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetCustomerClassificationIntervalScan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustomerClassificationIntervalScan`(
		IN ip_NoOfRecord 		INT
	,   IN ip_Batch 			INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20200612@Casey.Huynh]
		Task: Return the auto tag customer list that reach to scanning schedule (interval refer to CTS_DataCenter.CustomerCategory.IntervalScan
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20200701@Casey.Huynh: Chagne Flow and Store more Info [Redmine ID: #135324]
            - 20200820@Casey.Huynh: Remove USE INDEX  [Redmine ID: #139061]
            - 20200903@Harvey.Nguyen: Add ParentID  [Redmine ID: #140869]
			- 20200921@Irena.Vo: Enhance SP & insert Probation Management flow. [Redmine ID: #141755]
            - 20200923@Irena.Vo: Enhance SP [Redmine ID: #141755]
			- 20201221@Irena.Vo: Enhance logic ignore Pin category & Probation List. Remove input ip_ParentID & Update logic SP [RedmineID: #145951]
            - 20210510@Aries.Nguyen: Remove insert log dba_SP_PerformanceStats [Redmine ID: #154792]
            - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
			- 20210712@Irena.Vo: Fix bug get duplicated daily data [Redmine ID: 158262]
		Param's Explanation (filtered by):      
			- CALL CTS_DC_GetCustomerClassificationIntervalScan (100,1);
	*/
	DECLARE lv_ScanTime 			DATETIME DEFAULT CURRENT_TIMESTAMP();
	DECLARE lv_LastScanTime 		DATETIME;
    DECLARE lv_LastCustID 			BIGINT;
	DECLARE lv_TotalRecord 			BIGINT UNSIGNED;

	DROP TEMPORARY TABLE IF EXISTS Temp_ScanList;
	CREATE TEMPORARY TABLE Temp_ScanList(
			ID					INT AUTO_INCREMENT PRIMARY KEY
		,	CustID 				BIGINT UNSIGNED
		, 	CategoryID			SMALLINT UNSIGNED   
		,	INDEX				IX_Temp_ScanList_CustID(CustID)
	);


	DROP TEMPORARY TABLE IF EXISTS Temp_CategoryScanDate;
	CREATE TEMPORARY TABLE Temp_CategoryScanDate(
			CategoryID				INT
		,	SportGroupID			INT
        ,	ScanDate				DATETIME
        ,	CategoryGroup			INT
		,	PRIMARY KEY 		PK(CategoryID,SportGroupID)
	);
	
	SELECT MAX(ScanTime) 
    INTO lv_LastScanTime 
    FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus;
    
    SELECT MAX(LastCustID) 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus 
    WHERE ScanTime = lv_LastScanTime;
    
	IF(DATE(lv_LastScanTime) < DATE(lv_ScanTime))
	THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_ScanStatus(ScanTime, LastCustID, ScanStatus, ParentCategoryID)
		VALUES(lv_ScanTime, 0, 0, 200);
        SET lv_LastCustID = 0;
	ELSE	
		SET lv_ScanTime = lv_LastScanTime;
	END IF;
    
    INSERT INTO Temp_CategoryScanDate(CategoryID,SportGroupID, ScanDate, CategoryGroup)
	SELECT 	CategoryID
		, 	ParentID
        , 	DATE_SUB(DATE(lv_ScanTime), INTERVAL ScanIntervalInSecond - 86400 SECOND)
        ,	CategoryGroup
	FROM CTS_DataCenter.CustomerCategory AS cat
	WHERE ParentID = 200 
		AND IsActive = 1
		AND IsUsedManually = 0 
		AND ScanIntervalInSecond > 0; 
        
    SET lv_TotalRecord = ip_Batch * ip_NoOfRecord;
    
	/*INSERT CATEGORY TO SCAN*/
	INSERT INTO Temp_ScanList (CustID, CategoryID)
	SELECT  ccl.CustID AS CustID
		, 	temp.CategoryGroup AS CategoryID
	FROM CTS_DataCenter.CTSCustomerClassification AS ccl USE INDEX (PRIMARY)
		INNER JOIN Temp_CategoryScanDate AS temp ON ccl.CategoryID = temp.CategoryID  AND ccl.LastScannedDate <= temp.ScanDate
	WHERE ccl.CustID > lv_LastCustID  
		AND  ccl.SportGroupID = 200
		AND NOT EXISTS (SELECT 1 
						 FROM  CTS_DataCenter.PinCustomerCategory AS pin 
						 WHERE pin.CTSCustID = ccl.CTSCustID)
		AND NOT EXISTS (SELECT 1 
						 FROM  CTS_DataCenter.ProbationAccountMonitor AS pro 
						 WHERE pro.CustID = ccl.CustID 
							AND pro.SportGroupID = 200)
	ORDER BY ccl.CustID ASC
	LIMIT lv_TotalRecord; 
    
	SELECT (((temp.ID-1) DIV ip_NoOfRecord) + 1) AS BatchID
			, 	temp.CustID 		
			, 	200 AS SportGroupID	
			, 	temp.CategoryGroup AS CategoryID
	FROM Temp_ScanList AS temp;   
    
	IF NOT EXISTS (SELECT 1 FROM Temp_ScanList LIMIT 1)
	THEN
		UPDATE  CTS_DataCenter.CTSCustomerClassification_ScanStatus
		SET		ScanStatus = 1
		WHERE	ScanTime = lv_ScanTime;
	END IF;
END$$
DELIMITER ;