/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_Insert_PreProcess`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Insert_PreProcess`()
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Param's Expanation:
			- 
		
		Example:
			- CALL CTS_DC_CustClassification_BySport_Insert_PreProcess();
		
		Revisions: 
			- 20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
*/
	DECLARE CONST_PARENTID_NORMAL		      	INT;
	DECLARE CONST_CATEID_PROBATION		      	INT;
	DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 	INT DEFAULT 5;
	DECLARE CONST_LIST_BYSPORT				 	INT DEFAULT 23;
	
	DECLARE lv_CurrentDate						DATE DEFAULT CURRENT_DATE();
	DECLARE lv_ToProbationLastDay 				DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 2 DAY);
	DECLARE lv_ProbationCatePriority			SMALLINT;

	SET CONST_PARENTID_NORMAL	 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
	SET CONST_CATEID_PROBATION	 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_PROBATION');

	/* TEMPORARY TABLE */
	DROP TEMPORARY TABLE IF EXISTS Temp_ProbationCustomers;    
	CREATE TEMPORARY TABLE Temp_ProbationCustomers(	  	
			CustID								BIGINT UNSIGNED
		,	SportID								SMALLINT UNSIGNED
        , 	ProbationDate						DATE     
        ,	LastProbationDay					DATE
		,	IsPassProbationRule					TINYINT(1) DEFAULT 1
        ,	PRIMARY KEY (CustID, SportID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustIgnoranceAction;    
	CREATE TEMPORARY TABLE Temp_CustIgnoranceAction(	  	
			CustID								BIGINT UNSIGNED
		,	SportID								SMALLINT UNSIGNED
        , 	ActionType							SMALLINT 
		,	IsReturnData						TINYINT(1)		
        ,	PRIMARY KEY (CustID, SportID)
	);

	/* EXCLUDE INTERNAL CUSTOMERS */
	CALL CTS_DataCenter.CTS_DC_ExcludeCustByCondition('Temp_NewClassification');
	
	SELECT cat.CategoryPriority
	INTO lv_ProbationCatePriority
	FROM CTS_DataCenter.CustomerCategory AS cat
	WHERE cat.CategoryID = CONST_CATEID_PROBATION;
	
	INSERT IGNORE INTO Temp_ProbationCustomers(CustID, SportID, ProbationDate, LastProbationDay)
    SELECT DISTINCT cls.CustID, cls.SportID
		, 	DATE(cls.CreatedDate) AS ProbationDate
		, 	DATE_SUB(lv_CurrentDate, INTERVAL CAST(s.ItemValue AS UNSIGNED) DAY) AS LastProbationDay
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cls ON temp.CustID = cls.CustID AND temp.SportID = cls.SportID
        INNER JOIN CTS_DataCenter.StaticList AS s ON s.ListID = CONST_LIST_BYSPORT AND s.ItemID = temp.SportID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cls.CategoryID = cate.CategoryID
	WHERE cate.CategoryID = CONST_CATEID_PROBATION;
	
	UPDATE Temp_ProbationCustomers AS temp
	SET temp.IsPassProbationRule = 0
	WHERE temp.ProbationDate >= lv_ToProbationLastDay;
	
	UPDATE Temp_ProbationCustomers AS temp
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON temp.DWCategoryID = cate.CategoryID
	SET temp.IsPassProbationRule = 0
	WHERE cate.ParentID = CONST_PARENTID_NORMAL 
		AND	cate.CategoryPriority <= lv_ProbationCatePriority
		AND temp.ProbationDate > temp.LastProbationDay;
	
	INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, SportID, ActionType, IsReturnData)
    SELECT DISTINCT	temp.CustID, temp.SportID, CONST_ACTIONTYPE_IGNOREPROBATION, 0 AS IsReturnData
	FROM Temp_NewClassification AS temp 
		INNER JOIN Temp_ProbationCustomers AS pro ON temp.CustID = pro.CustID AND temp.SportID = pro.SportID
    WHERE temp.IsPassProbationRule = 0;
	
	UPDATE Temp_NewClassification AS temp
		INNER JOIN Temp_ProbationCustomers AS pro ON pro.CustID = temp.CustID AND pro.SportID = temp.SportID
	SET 	temp.IsDataChanged = 0
    WHERE 	temp.DWCategoryID = CONST_CATEID_PROBATION 
		AND pro.ProbationDate < pro.LastProbationDay;
		
	UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_CustIgnoranceAction AS ig ON temp.CustID = ig.CustID AND temp.SportID = ig.SportID
    SET 	temp.ActionType = ig.ActionType
		, 	temp.IsDataChanged = 0
		, 	temp.IsReturnData = ig.IsReturnData;

END$$
DELIMITER ;