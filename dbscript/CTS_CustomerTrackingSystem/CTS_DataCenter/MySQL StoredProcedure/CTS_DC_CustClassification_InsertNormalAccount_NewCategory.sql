/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InsertNormalAccount_NewCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InsertNormalAccount_NewCategory`(
		IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20230921@Casey.Huynh
		Task:		Create New Category for New Member
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20230921@Casey.Huynh: Created [Redmine ID: #193050]
                
		Param's Explanation (filtered by):
        
        Example:
				- CALL CTS_DataCenter.CTS_DC_CustClassification_InsertNormalAccount_NewCategory('13552401,13552402,13552403');
*/ 
	DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
    DECLARE CONST_CATEGORY_NEWMEMBER	INT DEFAULT 201;
    DECLARE CONST_CREATEDBY				INT DEFAULT 10278938;
    
	DECLARE lv_CurrentDateTime 			DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_Customerclass 			SMALLINT UNSIGNED;
    #=====================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			CustID			INT PRIMARY KEY
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerHistory;
    CREATE TEMPORARY TABLE Temp_CustomerHistory(
			CustID			INT PRIMARY KEY
	);
    
    #=====================================================   
	SELECT cc.CustomerClass 
	INTO lv_Customerclass
	FROM CTS_DataCenter.CustomerCategory AS cc
	WHERE cc.CategoryId = 201
	LIMIT 1;
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
	
    /* 1: INSERT CTSCustomerClassification */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT	tmp.CustID					AS CustID
		,	CONST_GROUP_NORMAL			AS SportGroupID
		,	CONST_CATEGORY_NEWMEMBER	AS CategoryID
		,	lv_CurrentDateTime			AS CreatedDate
		,	CONST_CREATEDBY				AS CreatedBy
		,	lv_CurrentDateTime			AS LastModifiedDate
		,	CONST_CREATEDBY				AS LastModifiedBy
		,	DATE(lv_CurrentDateTime)	AS LastScannedDate
	FROM Temp_Customer AS tmp; 
    
    /* 2: INSERT CTSCustomerClassification_History*/    
    INSERT INTO Temp_CustomerHistory(CustID)
    SELECT tmp.CustID
    FROM Temp_Customer AS tmp
		LEFT JOIN CTSCustomerClassification_History AS cls ON tmp.CustID = cls.CustID
	WHERE cls.CustID IS NULL;
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, SportGroupID, CategoryID, TurnoverRM, WinlossRM, BetCount, ActiveDays, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, ActionType, IsAuto, LastModifiedDate, LastModifiedBy, InsertDate, TaggingType, TWGroupBettingRate, TWTicketRejectRate, TWBetCount, TWDesktopUsageRate)
	SELECT	tmp.CustID					AS CustID
		,	CONST_GROUP_NORMAL			AS SportGroupID
		,	CONST_CATEGORY_NEWMEMBER	AS CategoryID
		,	0	AS TurnoverRM
		,	0	AS WinlossRM
		,	0	AS BetCount
		,	0	AS ActiveDays
		,	lv_Customerclass			AS TargetCC
		,	1	AS SourceTypeID
		,	CONST_CATEGORY_NEWMEMBER	AS FromCategoryID
		,	CONST_CATEGORY_NEWMEMBER	AS ToCategoryID
		,	1	AS IsDataChanged
		,	0	AS ActionType
		,	1	AS IsAuto
		,	lv_CurrentDateTime			AS LastModifiedDate
		,	CONST_CREATEDBY				AS LastModifiedBy
		,	lv_CurrentDateTime			AS InsertDate
		,	0	AS TaggingType
		,	0	AS TWGroupBettingRate
		,	0	AS TWTicketRejectRate
		,	0	AS TWDesktopUsageRate
		,	0	AS TWBetCount
	FROM 	Temp_CustomerHistory AS tmp;

    /* 3: WRITE CTSCustomerClassification_Log(TRACE DATA) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, SportGroupID, CategoryID, TurnoverRM, WinlossRM, BetCount, ActiveDays, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, ActionType, IsAuto, LastModifiedDate, LastModifiedBy, InsertDate, TaggingType, TWGroupBettingRate, TWTicketRejectRate, TWBetCount, TWDesktopUsageRate)
	SELECT	tmp.CustID					AS CustID
		,	CONST_GROUP_NORMAL			AS SportGroupID
		,	CONST_CATEGORY_NEWMEMBER	AS CategoryID
		,	0	AS TurnoverRM
		,	0	AS WinlossRM
		,	0	AS BetCount
		,	0	AS ActiveDays
		,	lv_Customerclass			AS TargetCC
		,	1	AS SourceTypeID
		,	CONST_CATEGORY_NEWMEMBER	AS FromCategoryID
		,	CONST_CATEGORY_NEWMEMBER	AS ToCategoryID
		,	1	AS IsDataChanged
		,	0	AS ActionType
		,	1	AS IsAuto
		,	lv_CurrentDateTime			AS LastModifiedDate
		,	CONST_CREATEDBY				AS LastModifiedBy
		,	lv_CurrentDateTime			AS InsertDate
		,	0	AS TaggingType
		,	0	AS TWGroupBettingRate
		,	0	AS TWTicketRejectRate
		,	0	AS TWBetCount
		,	0	AS TWDesktopUsageRate
	FROM 	Temp_Customer AS tmp;
    
END$$
DELIMITER ;