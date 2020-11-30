/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_Report_GetAssociatedAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Report_GetAssociatedAccount`(IN ip_CTSCustIDList VARCHAR(4000))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201028@Lex.Khuat
		Task :		Implement general category list for associated account report
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201028@Lex.Khuat: Created [Redmine ID: #131499]
            - 20201102@Irena.Vo: Update logic for New Member [Redmine ID: #131499]
            - 20201201@Aries.Nguyen:Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. Remove logic detail category . [Redmine ID: #145954]
            
		Param's Explanation:
            - ip_CTSCustIDList: list of ctscustid to get

		Example: 
            -CALL CTS_DataCenter.CTS_DC_AssociatedAccountReport_Get('1,2,3,4,5,6,7,8,9,10');
            
	*/ 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustIDList;
    CREATE TEMPORARY TABLE Temp_CTSCustIDList (
		CTSCustID		BIGINT UNSIGNED PRIMARY KEY
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_GeneralCategory;
    CREATE TEMPORARY TABLE Temp_GeneralCategory ( 
        CTSCustID           BIGINT   UNSIGNED
     ,	CategoryID			SMALLINT UNSIGNED
     ,  INDEX IX_Temp_GeneralCategory_CTSCustID_CategoryID(CTSCustID,CategoryID)
     );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
        CTSCustID           BIGINT   UNSIGNED
    ,	CategoryID			SMALLINT UNSIGNED
	,   DisplayCategoryID   SMALLINT UNSIGNED 
    ,   LastModifiedDate    DATETIME
    ,   INDEX IX_Temp_LatestRecordOfCategory_CTSCustID_DisplayCategoryID(CTSCustID,DisplayCategoryID)
    );
     
    -- Get Customer List
    IF IFNULL(ip_CTSCustIDList, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO Temp_CTSCustIDList (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
    END IF;
    
    -- Get Lastest category list
    INSERT INTO Temp_LatestRecordOfCategory (CTSCustID, CategoryID, LastModifiedDate)
	SELECT DISTINCT  cate.CTSCustID, cate.CategoryID, cate.LastModifiedDate
	FROM	CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN 	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
    INNER JOIN Temp_CTSCustIDList AS cust ON cust.CTSCustID = cate.CTSCustID
    WHERE	cc.ParentID IN (50, 200); -- OR cate.CategoryID = 2
    
     -- Get General Category
    INSERT INTO Temp_GeneralCategory
    SELECT DISTINCT temp.CTSCustID, temp.CategoryID 
    FROM Temp_LatestRecordOfCategory AS temp 
    WHERE temp.CategoryID  > 200;
    
    -- Detele Detail New Member
    /*DELETE temp
    FROM Temp_LatestRecordOfCategory AS temp
    INNER JOIN Temp_GeneralCategory AS ger ON ger.CTSCustID = temp.CTSCustID
    WHERE   temp.CategoryID = 2;*/
        
    -- Update Display Category ID
    UPDATE  Temp_LatestRecordOfCategory
    SET   DisplayCategoryID = (CASE WHEN CategoryID = 151 THEN 51
                                    WHEN CategoryID IN (72, 152) THEN 52
									WHEN CategoryID IN (73, 153) THEN 53
                                    WHEN CategoryID IN (74, 154) THEN 54 
                                    WHEN CategoryID IN (75, 155) THEN 55
                                    WHEN CategoryID IN (76, 156) THEN 56
									WHEN CategoryID IN (77, 157) THEN 57
									WHEN CategoryID IN (78, 158) THEN 58
									WHEN CategoryID IN (79, 159) THEN 59
									WHEN CategoryID = 80 THEN 60
                                    -- WHEN CategoryID = 2 THEN 201
                                    ELSE CategoryID
								END);

    -- Show results
	WITH CTE_LastestGeneralCategory AS (
		SELECT CTSCustID AS CTSCustId, DisplayCategoryID AS DisplayCategoryId, MAX(LastModifiedDate) AS LastModifiedDate FROM Temp_LatestRecordOfCategory GROUP BY CTSCustID, DisplayCategoryID
	)
	SELECT CTSCustId
		  ,   LEFT(GROUP_CONCAT(DISTINCT cc.CategoryName ORDER BY cc.CategoryID ASC SEPARATOR ', '), 255) AS CategoryList
	FROM CTE_LastestGeneralCategory
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = DisplayCategoryId
	GROUP BY CTSCustId;
        
	# Begin: Cleanup
    DROP TEMPORARY TABLE IF EXISTS Temp_GeneralCategory;
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory; 
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustIDList;
	# End: Cleanup
    
END$$

DELIMITER ;