/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InactiveNewMemberScan_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE  `CTS_DataCenter`.`CTS_DC_CustClassification_InactiveNewMemberScan_Get`()
    SQL SECURITY INVOKER
sp:BEGIN
/*
		Created:	20220316@Irena.Vo
		Task:		Get Inactive New Member for Scanning [Redmine ID: #169960]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220316@Irena.Vo: Created [Redmine ID: #169960]
			- 20220328@Irena.Vo: Fix bug return LastCreatedDate is NULL OR LastCTSCustID is NULL  [Redmine ID: #170610]
		Param's Explanation (filtered by):
		Example: 
			- CALL CTS_DataCenter.CTS_DC_CustClassification_InactiveNewMemberScan_Get();
	*/    
	DECLARE lv_BatchSize 				INT;
	DECLARE lv_LastCreatedDate 			DATETIME;
    DECLARE lv_LastCTSCustID			BIGINT UNSIGNED;
    DECLARE lv_Last30Days 				DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InactiveNewMember;
    CREATE TEMPORARY TABLE 	Temp_InactiveNewMember (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistingNewMember;
    CREATE TEMPORARY TABLE 	Temp_ExistingNewMember (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
        ,	CreatedDate 	DATETIME
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NotExistingCategory;
    CREATE TEMPORARY TABLE 	Temp_NotExistingCategory (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
        ,	CTSCustID 		BIGINT UNSIGNED
	);
    
    /* 1. Get Setting Parameters for Scanning */
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 79;
    
    SELECT ParameterValue 
    INTO lv_LastCreatedDate 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 80;
    
	SELECT ParameterValue 
    INTO lv_LastCTSCustID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 81;
	
	/* 2. Get New Member List have not bet tickets within 30 days */
    INSERT IGNORE INTO Temp_ExistingNewMember (CustID, CreatedDate)
	SELECT cate.CustID,cate.CreatedDate
	FROM CTS_DataCenter.CTSCustomerClassification AS cate
		STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS ld ON ld.CTSCustID = cate.CTSCustID 
	WHERE cate.SportGroupID = 200 AND cate.CategoryID IN (201, 231, 232, 233)
		AND cate.CreatedDate > lv_LastCreatedDate
		AND cate.CreatedDate <= lv_Last30Days
		AND ld.LastTicketDate <= lv_Last30Days
	ORDER BY cate.CreatedDate ASC
	LIMIT lv_BatchSize;
    
    IF EXISTS (SELECT 1 FROM Temp_ExistingNewMember) THEN
		SELECT MAX(CreatedDate) INTO lv_LastCreatedDate FROM Temp_ExistingNewMember;
        
        INSERT IGNORE INTO Temp_ExistingNewMember (CustID, CreatedDate)
		SELECT cate.CustID, cate.CreatedDate
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
			STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS ld ON ld.CTSCustID = cate.CTSCustID 
		WHERE cate.SportGroupID = 200 AND cate.CategoryID IN (201, 231, 232, 233)
			AND cate.CreatedDate = lv_LastCreatedDate
			AND cate.CreatedDate <= lv_Last30Days
			AND ld.LastTicketDate <= lv_Last30Days;
		
		INSERT IGNORE INTO Temp_InactiveNewMember (CustID)
		SELECT CustID
		FROM Temp_ExistingNewMember;
    END IF;
    
    /* 3. Get Customer List are not Category and have not bet tickets within 30 last days */
	INSERT IGNORE INTO Temp_NotExistingCategory (CustID, CTSCustID)
	SELECT cus.CustID, cus.CTSCustID
	FROM CTS_DataCenter.CTSCustomer AS cus
		STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS ld ON ld.CTSCustID = cus.CTSCustID 
	WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassification AS cate WHERE cate.CTSCustID = cus.CTSCustID)
		AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.StaticList AS st WHERE st.ItemID = cus.SiteID AND st.ListID = 11)
		AND cus.CTSCustID > lv_LastCTSCustID
        AND cus.Recommend NOT IN (52466,5707545)
		AND cus.UserName NOT LIKE '%CashOut'
        AND cus.CustSubID = 0
		AND cus.RoleID = 1
		AND cus.CreatedDate <= lv_Last30Days
		AND ld.LastTicketDate <= lv_Last30Days
	ORDER BY cus.CTSCustID ASC
	LIMIT lv_BatchSize;
	
    IF EXISTS (SELECT 1 FROM Temp_NotExistingCategory) THEN
		SELECT MAX(CTSCustID) INTO lv_LastCTSCustID FROM Temp_NotExistingCategory;
        
		INSERT IGNORE INTO Temp_InactiveNewMember (CustID)
		SELECT CustID
		FROM Temp_NotExistingCategory;
    END IF;
    
    /* 4. Get Scanning List */
    IF NOT EXISTS (SELECT 1 FROM Temp_InactiveNewMember) THEN
        LEAVE sp;
    ELSE
		SELECT DISTINCT CustID 
		FROM Temp_InactiveNewMember;
        
		SELECT lv_LastCreatedDate AS LastCreatedDate;
        
        SELECT lv_LastCTSCustID AS LastCTSCustID;
	END IF;
END$$
DELIMITER ;