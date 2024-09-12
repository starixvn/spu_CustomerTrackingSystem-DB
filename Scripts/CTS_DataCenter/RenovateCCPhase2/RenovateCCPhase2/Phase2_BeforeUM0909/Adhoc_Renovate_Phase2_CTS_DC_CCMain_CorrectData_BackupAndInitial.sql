/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CCMain_CorrectData_BackupAndInitial`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CCMain_CorrectData_BackupAndInitial`(
		IN		ip_Batchsize			INT
	,	IN		ip_MinCustID			BIGINT
	,	OUT		op_NextCustID			BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240905@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_CorrectData_BackupAndInitial(10000,61522086,@op_NextCustID);
			
		Revisions: 
			- 20240905@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DECLARE lv_MaxCustID					BIGINT DEFAULT 0;
	DECLARE lv_NextCustID					BIGINT DEFAULT 0;

	DECLARE	CONST_SPORTGROUP_NORMAL			INT DEFAULT 200;
	DECLARE CONST_CATEGORYGROUP_PROBATION	INT DEFAULT 206;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer_GENERAL;
	CREATE TEMPORARY TABLE Temp_Customer_GENERAL (
			ID					BIGINT UNSIGNED AUTO_INCREMENT
		,	CustID				BIGINT UNSIGNED
		,	RoleID				TINYINT
		,	SportGroupID_curr	INT
		,	CategoryID_curr		INT
		,	ParentID			INT
		,	CategoryID			INT
		,	CreatedDate			DATETIME
		,	LastScannedDate		DATETIME
		,	PRIMARY KEY (ID)
	);
	
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer_BYSPORT;
	CREATE TEMPORARY TABLE Temp_Customer_BYSPORT (
			ID					BIGINT UNSIGNED AUTO_INCREMENT
		,	CustID				BIGINT UNSIGNED
		,	SportID				INT
		,	CategoryID_curr		INT
		,	ParentID			INT
		,	CategoryID			INT
		,	CreatedDate			DATETIME
		,	LastScannedDate		DATETIME
		,	PRIMARY KEY (ID)
	);
	
	WITH CTE AS
	(
		SELECT cc.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS cc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
		WHERE cc.CustID >= ip_MinCustID
		LIMIT ip_Batchsize
	)
	SELECT MAX(CustID)
	INTO lv_MaxCustID
	FROM CTE;
	
	/*Get Info*/
	INSERT INTO Temp_Customer_GENERAL (CustID,RoleID,SportGroupID_curr,CategoryID_curr,ParentID,CategoryID,CreatedDate,LastScannedDate)
	SELECT cc.CustID,cust.RoleID,cc.SportGroupID AS SportGroupID_curr,cc.CategoryID AS CategoryID_curr,curcate.ParentID,curcate.CategoryID,pro.CreatedDate,pro.LastScannedDate
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory_new AS curcate ON curcate.OldCategoryID = cc.CategoryID 
		INNER JOIN CTS_DataCenter.ProbationAccountMonitor AS pro ON pro.CustID = cc.CustID AND pro.SportGroupID = CONST_SPORTGROUP_NORMAL
	WHERE cc.CustID >= ip_MinCustID AND cc.CustID <= lv_MaxCustID
		AND cc.SportGroupID = CONST_SPORTGROUP_NORMAL
		AND curcate.Ext_CategoryGroupID = CONST_CATEGORYGROUP_PROBATION
		AND (cc.ParentID_new IS NULL 
			OR (cc.SportGroupID <> cc.SportGroupID_bk) -- issue: update 10 million to estimate
			OR (cc.CategoryID = cc.CategoryID_bk AND (cc.LastScannedDate <> pro.LastScannedDate	
														OR cc.CreatedDate_new <> pro.CreatedDate 
														OR cc.LastScannedDate_new <> pro.LastScannedDate))
			OR (cc.CategoryID <> cc.CategoryID_bk))
	UNION
	SELECT 	cc.CustID,cust.RoleID,cc.SportGroupID AS SportGroupID_curr,cc.CategoryID AS CategoryID_curr,curcate.ParentID,curcate.CategoryID,cc.CreatedDate,cc.LastScannedDate
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory_new AS curcate ON curcate.OldCategoryID = cc.CategoryID 
	WHERE cc.CustID >= ip_MinCustID AND cc.CustID <= lv_MaxCustID
		AND curcate.Ext_CategoryGroupID <> CONST_CATEGORYGROUP_PROBATION
		AND (cc.ParentID_new IS NULL 
			OR (cc.SportGroupID <> cc.SportGroupID_bk) -- issue: update 10 million to estimate
			OR (cc.CategoryID <> cc.CategoryID_bk)) -- issue: update 10 million to estimate
	;
	
	INSERT INTO Temp_Customer_BYSPORT (CustID,SportID,CategoryID_curr,ParentID,CategoryID,CreatedDate,LastScannedDate)
	SELECT cc.CustID,cc.SportID,cc.CategoryID AS CategoryID_curr,curcate.ParentID,curcate.CategoryID,pro.CreatedDate,pro.LastScannedDate
	FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory_new AS curcate ON curcate.OldCategoryID = cc.CategoryID 
		INNER JOIN CTS_DataCenter.ProbationAccountMonitor_BySport AS pro ON pro.CustID = cc.CustID AND pro.SportID = cc.SportID
	WHERE cc.CustID >= ip_MinCustID AND cc.CustID <= lv_MaxCustID
		AND cc.CategoryID = CONST_CATEGORYGROUP_PROBATION
		AND (cc.ParentID IS NULL 
			OR (cc.CategoryID = cc.CategoryID_bk AND (cc.LastScannedDate <> pro.LastScannedDate	
														OR cc.CreatedDate_new <> pro.CreatedDate 
														OR cc.LastScannedDate_new <> pro.LastScannedDate))
			OR (cc.CategoryID <> cc.CategoryID_bk))
	UNION
	SELECT 	cc.CustID,cc.SportID,cc.CategoryID AS CategoryID_curr,curcate.ParentID,curcate.CategoryID,cc.CreatedDate,cc.LastScannedDate
	FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory_new AS curcate ON curcate.OldCategoryID = cc.CategoryID 
	WHERE cc.CustID >= ip_MinCustID AND cc.CustID <= lv_MaxCustID
		AND cc.CategoryID <> CONST_CATEGORYGROUP_PROBATION
		AND (cc.ParentID IS NULL 
			OR (cc.CategoryID <> cc.CategoryID_bk)) 
	;
	
	/*Update Data*/
	UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN Temp_Customer_GENERAL AS temp ON cc.CustID = temp.CustID 
													AND cc.SportGroupID = temp.SportGroupID_curr
													AND cc.CategoryID = temp.CategoryID_curr
											
	SET 	cc.RoleID		 		= temp.RoleID
		,	cc.ParentID_new 		= temp.ParentID
		,	cc.CategoryID_new 		= temp.CategoryID
		,	cc.CreatedDate_new 		= temp.CreatedDate
		,	cc.LastScannedDate_new 	= temp.LastScannedDate
		,	cc.SportGroupID_bk 		= cc.SportGroupID
		,	cc.CategoryID_bk 		= cc.CategoryID
		,	cc.CreatedDate_bk 		= cc.CreatedDate
		,	cc.LastScannedDate_bk 	= cc.LastScannedDate;
		
	UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cc
		INNER JOIN Temp_Customer_BYSPORT AS temp ON cc.CustID = temp.CustID 
													AND cc.SportID = temp.SportID
													AND cc.CategoryID = temp.CategoryID_curr
	SET 	cc.ParentID		 		= temp.ParentID
		,	cc.CategoryID_new 		= temp.CategoryID
		,	cc.CreatedDate_new		= temp.CreatedDate
		,	cc.LastScannedDate_new 	= temp.LastScannedDate
		,	cc.CategoryID_bk 		= cc.CategoryID
		,	cc.CreatedDate_bk 		= cc.CreatedDate
		,	cc.LastScannedDate_bk 	= cc.LastScannedDate;
		
	SELECT cc.CustID
	INTO lv_NextCustID
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
	WHERE cc.CustID > lv_MaxCustID
	ORDER BY cc.CustID
	LIMIT 1; 
		
	SET op_NextCustID = lv_NextCustID;
		
	IF op_NextCustID IS NULL THEN
		SET op_NextCustID = ip_MinCustID;
	END IF;

END$$
DELIMITER ;