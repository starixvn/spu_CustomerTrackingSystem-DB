/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Get4API`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Get4API`(
        IN ip_CustIDs			VARCHAR(2000)
    ,   IN ip_ParentCateIDs		VARCHAR(500)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200914@Harvey.Nguyen
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter.
		Original: 

		Revisions:
            - 20200910@Harvey.Nguyen: init sp [Redmine ID: #140971]
            - 20200929@Lex.Khuat: Support return problem account categories by [Redmine ID: #141962]
            - 20201130@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. Remove logic detail category. [Redmine ID: #145954]
            - 20201216@Harvey.Nguyen: grouping category [Redmine ID: #147299]
            - 20210622@Aries.Nguyen: Update coding convention  [Redmine ID: #157203]

		Param's Explanation:

	*/ 
	DECLARE lv_remark VARCHAR(50);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE Temp_CustID (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ParentID;
    CREATE TEMPORARY TABLE Temp_ParentID (
			ParentID 		SMALLINT UNSIGNED PRIMARY KEY
    );
    
    IF IFNULL(ip_CustIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
    END IF;
    
    IF IFNULL(ip_ParentCateIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO Temp_ParentID (ParentID) VALUES ('", REPLACE(ip_ParentCateIDs, ",", "'),('"),"');");
		PREPARE stmt2 FROM @sql;
		EXECUTE stmt2;
	END IF;

    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
		CustID				BIGINT UNSIGNED
	,	CategoryID			SMALLINT UNSIGNED
    , 	LastModifiedDate	DATETIME
    );
    
    SET lv_remark = 'Auto tag customer classification';
    
    INSERT INTO Temp_LatestRecordOfCategory(CustID, CategoryID, LastModifiedDate)
    SELECT cla.CustID
        , 	cla.CategoryID AS 'CategoryID'
        ,   MAX(cla.LastModifiedDate) AS 'LastModifiedDate'
    FROM		CTS_DataCenter.CTSCustomerClassification AS cla
		INNER JOIN Temp_CustID AS cust ON cla.CustID = cust.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON cla.CategoryID = a.CategoryID
    WHERE (IFNULL(ip_ParentCateIDs, '') = ''
			OR a.ParentID IN (SELECT ParentID FROM Temp_ParentID))
	GROUP BY cla.CustID, CategoryID;

    SELECT 	c.CustID AS CustID
		,	b.CategoryName AS ParentCategoryName
		,	a.CategoryName
    FROM Temp_LatestRecordOfCategory AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID;  
	
	# Begin: Cleanup
	DROP TEMPORARY TABLE Temp_LatestRecordOfCategory;
	# End: Cleanup
END$$

DELIMITER ;