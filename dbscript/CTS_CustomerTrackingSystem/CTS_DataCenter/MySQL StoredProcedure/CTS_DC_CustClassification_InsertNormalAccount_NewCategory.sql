/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InsertNormalAccount_NewCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InsertNormalAccount_NewCategory`(
		IN ip_TableName VARCHAR(200)
	,	IN ip_IsNewCustomer	BOOLEAN
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
                - 20231024@Jonas.Huynh: HF wrong reactivated category [Redmine ID: #193050]
                - 20240502@Jonas.Huynh: Handle duplicate categories [Redmine ID: #203323]
                
		Param's Explanation (filtered by):
        
        Example:
				- CALL CTS_DataCenter.CTS_DC_CustClassification_InsertNormalAccount_NewCategory('Temp_CustNewCategory', true);
*/ 
	DECLARE	CONST_GROUP_NORMAL 				INT DEFAULT 200;
    DECLARE CONST_CATEGORY_NEWMEMBER		INT DEFAULT 201;
    DECLARE CONST_CATEGORY_NORMALINACTIVE	INT DEFAULT 1001;
    DECLARE CONST_CATEGORY_SMARTINACTIVE	INT DEFAULT 1002;
    DECLARE CONST_CREATEDBY					INT DEFAULT 10278938;
    
	DECLARE lv_CurrentDateTime 			DATETIME DEFAULT CURRENT_TIME();

    #=====================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE Temp_Customer(
			CustID			INT PRIMARY KEY
		,	IsInternal		BOOLEAN
        ,	SiteID			INT
        ,	CategoryID		SMALLINT DEFAULT NULL
        ,	CustomerClass	SMALLINT
        ,	INDEX			IX_Temp_Customer_CategoryID(CategoryID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerHistory;
    CREATE TEMPORARY TABLE Temp_CustomerHistory(
			CustID			INT PRIMARY KEY
		,	CustomerClass	SMALLINT NOT NULL
        ,   CategoryID		SMALLINT NOT NULL
	);
    
    #=====================================================   

	SET @sql =CONCAT("	INSERT IGNORE INTO Temp_Customer (CustID, IsInternal, SiteID) 
						SELECT	ipTbl.CustID
							,	ipTbl.IsInternal
                            ,	ipTbl.SiteID
						FROM ",ip_TableName," AS ipTbl"
						);
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 

    CALL CTS_DataCenter.CTS_DC_ExcludeCustomer(2,'Temp_Customer');
    
     /* 0: INSERT CTSCustomerClassification */
     IF ip_IsNewCustomer = TRUE	THEN
		UPDATE Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = CONST_CATEGORY_NEWMEMBER
        SET 	temp.CategoryID = CONST_CATEGORY_NEWMEMBER
			,	temp.CustomerClass = cc.CustomerClass;
     ELSE
		DELETE tmp
		FROM Temp_Customer AS tmp
		WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassification AS clss WHERE clss.CustID = tmp.CustID);
		
		UPDATE Temp_Customer AS temp
			,	LATERAL
				(
					SELECT DISTINCT arc.CustID, arc.CategoryID, arc.ID
					FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc
					WHERE arc.CustID = temp.CustID
						AND arc.CustSubID = 0
						AND arc.IsReactivated = TRUE
					ORDER BY arc.ID DESC
					LIMIT 1
				) AS arc
		SET temp.CategoryID = CASE
								WHEN arc.CategoryID = CONST_CATEGORY_NORMALINACTIVE THEN CONST_CATEGORY_NORMALINACTIVE
								WHEN arc.CategoryID = CONST_CATEGORY_SMARTINACTIVE THEN CONST_CATEGORY_SMARTINACTIVE
								ELSE NULL
							  END;
                              
		UPDATE Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.CategoryID
        SET temp.CustomerClass = cc.CustomerClass; 
        
	 END IF;
     
     DELETE tmp
     FROM Temp_Customer AS tmp
     WHERE tmp.CategoryID IS NULL;

    /* 1: INSERT CTSCustomerClassification */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT	tmp.CustID					AS CustID
		,	CONST_GROUP_NORMAL			AS SportGroupID
		,	tmp.CategoryID				AS CategoryID
		,	lv_CurrentDateTime			AS CreatedDate
		,	CONST_CREATEDBY				AS CreatedBy
		,	lv_CurrentDateTime			AS LastModifiedDate
		,	CONST_CREATEDBY				AS LastModifiedBy
		,	DATE(lv_CurrentDateTime)	AS LastScannedDate
	FROM Temp_Customer AS tmp;
    
    /* 2: INSERT CTSCustomerClassification_History*/    
    INSERT INTO Temp_CustomerHistory(CustID, CustomerClass, CategoryID)
    SELECT tmp.CustID, tmp.CustomerClass, tmp.CategoryID
    FROM Temp_Customer AS tmp
		LEFT JOIN CTSCustomerClassification_History AS cls ON tmp.CustID = cls.CustID
	WHERE cls.CustID IS NULL;
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, SportGroupID, CategoryID, TurnoverRM, WinlossRM, BetCount, ActiveDays, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, ActionType, IsAuto, LastModifiedDate, LastModifiedBy, InsertDate, TaggingType, TWGroupBettingRate, TWTicketRejectRate, TWBetCount, TWDesktopUsageRate)
	SELECT	tmp.CustID					AS CustID
		,	CONST_GROUP_NORMAL			AS SportGroupID
		,	tmp.CategoryID				AS CategoryID
		,	0	AS TurnoverRM
		,	0	AS WinlossRM
		,	0	AS BetCount
		,	0	AS ActiveDays
		,	tmp.CustomerClass			AS TargetCC
		,	1	AS SourceTypeID
		,	tmp.CategoryID				AS FromCategoryID
		,	tmp.CategoryID				AS ToCategoryID
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
		,	tmp.CategoryID				AS CategoryID
		,	0	AS TurnoverRM
		,	0	AS WinlossRM
		,	0	AS BetCount
		,	0	AS ActiveDays
		,	tmp.CustomerClass			AS TargetCC
		,	1	AS SourceTypeID
		,	tmp.CategoryID				AS FromCategoryID
		,	tmp.CategoryID				AS ToCategoryID
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