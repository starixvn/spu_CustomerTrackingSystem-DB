/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCustomerClassificationIntervalScan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCustomerClassificationIntervalScan`(
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
		Param's Explanation (filtered by):      
			- CALL CTS_DC_GetCustomerClassificationIntervalScan (100,1,200);
	*/
	DECLARE lv_ScanTime 		DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_ScanDate 		DATETIME;    
	DECLARE lv_LastScanTime 	DATETIME;
	DECLARE lv_LastScanDate 	DATETIME;
	DECLARE lv_TotalRecord 		BIGINT UNSIGNED;
	DECLARE	lv_LogTotalRecord 	INT;
	DECLARE	lv_FromID			BIGINT;
	DECLARE	lv_ToID				BIGINT;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_ScanList;
	CREATE TEMPORARY TABLE Temp_ScanList(
			CustID 				BIGINT UNSIGNED
		, 	SportGroupID 		SMALLINT UNSIGNED
		, 	CategoryID			SMALLINT UNSIGNED    
		, 	ID					INT SIGNED AUTO_INCREMENT
		,	INDEX				IX_Temp_ScanList_ID(ID)
		,	INDEX				IX_Temp_ScanList_CustID(CustID)
	);
	
	SET lv_LastScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus);
	SET lv_ScanDate = DATE(lv_ScanTime);
	SET lv_LastScanDate = DATE(lv_LastScanTime);
	
	IF(lv_LastScanDate <> lv_ScanDate)
	THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_ScanStatus(ScanTime, LastCustID, ScanStatus, ParentCategoryID)
		VALUES(lv_ScanTime, 0, 0, 200);
	ELSE	
		SET lv_ScanTime = lv_LastScanTime;
	END IF;
	
	SET lv_TotalRecord = ip_Batch * ip_NoOfRecord;
	
	/*INSERT CATEGORY TO SCAN*/
	INSERT INTO Temp_ScanList (CustID, SportGroupID, CategoryID)
	SELECT ccl.CustID AS CustID, ccl.SportGroupID AS SportGroupID, ccl.CategoryID AS CategoryID
	FROM CTS_DataCenter.CTSCustomerClassification AS ccl
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON ccl.CategoryID = cat.CategoryID
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = ccl.CTSCustID
		LEFT JOIN CTS_DataCenter.ProbationAccountMonitor AS pro on pro.CustID = ccl.CustID AND pro.SportGroupID = 200
	WHERE 	pin.CTSCustID IS NULL 
			AND pro.SportGroupID IS NULL
			AND cat.IsActive = 1
			AND cat.IsUsedManually = 0
			AND cat.ScanIntervalInSecond > 0
			AND ccl.SportGroupID = 200
			AND ccl.LastScannedDate <= DATE_SUB(lv_ScanDate, INTERVAL cat.ScanIntervalInSecond SECOND)
	LIMIT lv_TotalRecord;
	  
	SELECT (((temp.ID-1) DIV ip_NoOfRecord) + 1) AS BatchID
			, 	temp.CustID 		
			, 	temp.SportGroupID	
			, 	temp.CategoryID
	FROM Temp_ScanList AS temp;     
	
	IF NOT EXISTS (SELECT 1 FROM Temp_ScanList LIMIT 1)
	THEN
		UPDATE  CTS_DataCenter.CTSCustomerClassification_ScanStatus
		SET		ScanStatus = 1
		WHERE	ScanTime = lv_ScanTime;
	END IF;

	SELECT 	COUNT(1), MIN(CustID), MAX(CustID)
	INTO	lv_LogTotalRecord, lv_FromID, lv_ToID
	FROM	Temp_ScanList;    
END$$
DELIMITER ;