/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScan_GetInactiveNewMember`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_DailyScan_GetInactiveNewMember`(
		OUT op_LastCategoryID 	INT 
	,	OUT op_LastCustID 		BIGINT UNSIGNED 
)
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
            - 20220331@Aries.Nguyen: Fix performance issue  [Redmine ID: #170769]            
			- 20230207@Long.Luu: Get exact lastticketdate [Redmine ID: #183281]
			- 20231030@Victoria.Le: Add New CategoryID - New Group Betting  [Redmine ID: #195060]
            
		Param's Explanation (filtered by):
		Example: 
			- CALL CTS_DC_CustClassification_DailyScan_GetInactiveNewMember (@op_LastCategoryID, @op_LastCustID);
	*/    
	DECLARE lv_LastCategoryID 		INT;
	DECLARE lv_LastCustID 			BIGINT UNSIGNED;
    DECLARE lv_BatchSize 			BIGINT;

    DECLARE lv_NextCategoryID 		INT;
    DECLARE lv_NextCustID 			BIGINT UNSIGNED;
	DECLARE lv_ScanDateValid 		DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
	CREATE TEMPORARY TABLE Temp_Category(
			CategoryID				INT PRIMARY KEY 	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InactiveNewMember;
    CREATE TEMPORARY TABLE 	Temp_InactiveNewMember (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
    INSERT INTO Temp_Category(CategoryID) VALUES (201), (231), (232), (233), (239); 
  
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 79;
    
    SELECT ParameterValue 
    INTO lv_LastCategoryID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 80;
    
    SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 81;
    
    IF lv_LastCategoryID IS NULL OR  lv_LastCategoryID = 0 THEN
		SELECT CategoryID 
		INTO lv_LastCategoryID 
		FROM Temp_Category
		ORDER BY CategoryID ASC
        LIMIT 1;
	END  IF;
 
    SET @sql = 	CONCAT("
		INSERT IGNORE INTO Temp_InactiveNewMember (CustID)
		SELECT 	clss.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss USE INDEX(IX_CTSCustomerClassification_CategoryID_CustID)
		WHERE clss.CustID > ", lv_LastCustID," ","
			AND clss.CategoryID = ",lv_LastCategoryID," ","
			AND clss.CreatedDate <= '",lv_ScanDateValid,"' ","
			AND NOT EXISTS (SELECT 1 
							FROM  CTS_Archive.CTSCustomerAssociationStatus AS ticket 
							WHERE ticket.CTSCustID = clss.CTSCustID
								AND IFNULL(ticket.LastTicketDate, ticket.Created) > '",lv_ScanDateValid,"')
		ORDER BY clss.CategoryID ASC
			,	 clss.CustID ASC
		LIMIT ",lv_BatchSize,";");
	
    
    PREPARE stmt1 FROM  @sql;
    EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1;
  
    IF NOT EXISTS (SELECT 1 FROM Temp_InactiveNewMember) THEN
		SELECT 	cate.CategoryID
        INTO 	lv_NextCategoryID
		FROM Temp_Category  AS cate
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON cate.CategoryID = clss.CategoryID 
		WHERE cate.CategoryID > lv_LastCategoryID
			AND clss.CreatedDate <= lv_ScanDateValid
            AND NOT EXISTS (SELECT 1 
							FROM  CTS_Archive.CTSCustomerAssociationStatus AS ticket 
							WHERE ticket.CTSCustID = clss.CTSCustID
								AND IFNULL(ticket.LastTicketDate, ticket.Created) > lv_ScanDateValid)
		ORDER BY cate.CategoryID ASC
		LIMIT 1; 
    END IF;
    
    IF lv_NextCategoryID IS NOT NULL THEN
		SET @sql =  CONCAT("
		INSERT IGNORE INTO Temp_InactiveNewMember (CustID)
		SELECT 	clss.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss USE INDEX(IX_CTSCustomerClassification_CategoryID_CustID)
		WHERE clss.CustID > 0
			AND clss.CategoryID = ", lv_NextCategoryID," ","
			AND clss.CreatedDate <= '", lv_ScanDateValid,"' ","
			AND NOT EXISTS (SELECT 1 
							FROM  CTS_Archive.CTSCustomerAssociationStatus AS ticket 
							WHERE ticket.CTSCustID = clss.CTSCustID
								AND IFNULL(ticket.LastTicketDate, ticket.Created) > '",lv_ScanDateValid,"')
		ORDER BY clss.CategoryID ASC
			,	 clss.CustID ASC
		LIMIT ", lv_BatchSize,";");
    
		PREPARE stmt1 FROM  @sql;
		EXECUTE stmt1; 
		DEALLOCATE PREPARE stmt1;
        
	ELSE
		SET lv_NextCategoryID = lv_LastCategoryID;
	END IF;
    
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_InactiveNewMember;
    
    IF lv_NextCustID IS NOT NULL THEN
        SET op_LastCategoryID = lv_NextCategoryID;
		SET op_LastCustID = lv_NextCustID;
	ELSE 
		SELECT CategoryID
        INTO lv_NextCategoryID
		FROM Temp_Category
		ORDER BY CategoryID ASC 
		LIMIT 1;
	
        SET op_LastCategoryID = lv_NextCategoryID;
        SET op_LastCustID = 0;
    END IF;
    
    SELECT 	CustID
    FROM Temp_InactiveNewMember;
END$$
DELIMITER ;