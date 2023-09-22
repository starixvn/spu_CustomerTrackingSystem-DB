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
		Task:		Au
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20230921@Casey.Huynh: Created [Redmine ID: #137550]
                
		Param's Explanation (filtered by):
        
        Example:
				- CALL CTS_DataCenter.CTS_DC_CustClassification_InsertNormalAccount_NewCategory('13552401,13552402,13552403');
*/ 
	DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
    DECLARE CONST_CATEGORY_NEWMEMBER	INT DEFAULT 201;
    DECLARE CONST_CREATEDBY				INT DEFAULT 10278938;
    
	DECLARE lv_CurrentDateTime 			DATETIME DEFAULT CURRENT_TIME();
    
    #=====================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
		CustID INT PRIMARY KEY
	);
    #=====================================================    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    

    /* 1: INSERT CTS CLASSIFICATION */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID,SportGroupID,CategoryID,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate)
	SELECT DISTINCT temp.CustID
		, 	CONST_GROUP_NORMAL
		, 	CONST_CATEGORY_NEWMEMBER
		, 	lv_CurrentDateTime
		, 	CONST_CREATEDBY
		, 	lv_CurrentDateTime
		, 	CONST_CREATEDBY
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Temp_Customer AS temp; 
	
	SELECT cc.CustomerClass 
	INTO lv_Customerclass
	FROM CTS_DataCenter.CustomerCategory AS cc
	WHERE cc.CategoryId = 201
	LIMIT 1;
    
    /* 15: WRITE HISTORY LOG (VIEW ON WEB) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
    , ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, TaggingType, TargetDangerLevel1, PerformanceTime)
	SELECT DISTINCT	temp.CustID
				, 	CONST_CATEGORY_NEWMEMBER
				, 	CONST_GROUP_NORMAL
				, 	lv_CurrentDateTime
				, 	CONST_CREATEDBY
				, 	0 AS TurnoverRM
				, 	0 AS WinlossRM
				, 	0 AS BetCount
				, 	0 AS ActiveDays
                ,	0 AS TWBetCount
                , 	0 AS TWGroupBettingRate
                , 	0 AS TWTicketRejectRate
                , 	0 AS TWDesktopUsageRate
				, 	0 AS ActionType
				, 	1 AS IsAuto
				, 	DATE(lv_CurrentDateTime) AS InsertDate
				,	lv_Customerclass AS TargetCC 
				,   0 AS SourceTypeID
				, 	NULL AS FromCategoryID 
				, 	CONST_CATEGORY_NEWMEMBER AS ToCategoryID
				,   1 AS IsDataChanged
				,	NULL AS TaggingType
				,	NULL AS TargetDangerLevel1
                ,	NULL AS PerformanceTime
	FROM 	Temp_Customer AS temp;	

    /* 16: WRITE HISTORY LOG (TRACE DATA) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
    , ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, TaggingType, TargetDangerLevel1, PerformanceTime)
	SELECT DISTINCT	temp.CustID
				, 	temp.NewCateID
				, 	CONST_GROUP_NORMAL
				, 	lv_CurrentDateTime
				, 	CONST_CREATEDBY
				, 	0 AS TurnoverRM
				, 	0 AS WinlossRM
				, 	0 AS BetCount
				, 	0 AS ActiveDays
                ,	0 AS TWBetCount
                , 	0 AS TWGroupBettingRate
                , 	0 AS WTicketRejectRate
                , 	0 AS TWDesktopUsageRate
				, 	0 AS ActionType
				, 	1 AS IsAuto
				, 	DATE(lv_CurrentDateTime) AS InsertDate
				,	lv_Customerclass AS TargetCC 
				,   0 AS SourceTypeID
				, 	NULL OldCateID 
				, 	NULL DWCateID
				,   1 AS IsDataChanged
				,	0 AS TaggingType
				,	0 AS TargetDangerLevel1
                ,	0 AS PerformanceTime
	FROM 	Temp_Customer AS temp;
    
END$$
DELIMITER ;