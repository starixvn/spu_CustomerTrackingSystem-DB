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
		Param's Explanation (filtered by):
		Example: 
			- CALL CTS_DataCenter.CTS_DC_CustClassification_InactiveNewMemberScan_Get();
	*/    
	DECLARE lv_BatchSize 				INT;
	DECLARE lv_LastCustID 				BIGINT UNSIGNED;
	DECLARE lv_LastScannedTime 			DATETIME;
	
    DECLARE lv_CONST_CATEGORY_NEWMEMBER SMALLINT DEFAULT 201;
    
    DECLARE lv_CurrentDateTime 			DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_Last30Days 				DATETIME DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InactiveNewMember;
    CREATE TEMPORARY TABLE 	Temp_InactiveNewMember (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_OldNewMember;
    CREATE TEMPORARY TABLE 	Temp_OldNewMember (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
    /* 1. Get Setting Parameters for Scanning */
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 79;
    
    SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 80;
    
    SELECT ParameterValue 
    INTO lv_LastScannedTime 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 81;
	
    IF (lv_LastScannedTime < lv_CurrentDateTime) THEN
		/* 2. Get Old New Member in CTS (Created at 30 days before) */
		INSERT IGNORE INTO Temp_OldNewMember (CustID)
		SELECT cate.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID AND cc.CategoryGroup = lv_CONST_CATEGORY_NEWMEMBER
		WHERE cate.CustID > lv_LastCustID AND cate.CreatedDate <= lv_Last30Days
		ORDER BY cate.CustID ASC
		LIMIT lv_BatchSize;
		
		/* 3. Get Inactive New Member (No bet ticket for 30 last days) */
		INSERT IGNORE INTO Temp_InactiveNewMember (CustID)
		SELECT oc.CustID
		FROM Temp_OldNewMember AS oc
			INNER JOIN CTS_Archive.CTSCustomerAssociationStatus AS ld ON ld.CustID = oc.CustID
		WHERE ld.LastTicketDate <= lv_Last30Days
		ORDER BY oc.CustID ASC;
	END IF;
    
    /* 4. Get Result for Scanning */
    IF NOT EXISTS (SELECT 1 FROM Temp_InactiveNewMember) THEN
        LEAVE sp;
    ELSE
		SELECT DISTINCT CustID 
		FROM Temp_InactiveNewMember;
        
        SELECT MAX(CustID) AS LastCustID
        FROM Temp_InactiveNewMember;
        
        SELECT lv_CurrentDateTime AS LastScannedTime;
	END IF;
END$$
DELIMITER ;