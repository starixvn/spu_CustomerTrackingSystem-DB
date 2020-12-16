/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Get4API`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Get4API`(IN ip_CustIDs			VARCHAR(2000), IN ip_ParentCateIDs		VARCHAR(500))
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

		Param's Explanation:
	*/ 
	DECLARE v_remark VARCHAR(50);
    
    DROP TEMPORARY TABLE IF EXISTS TempCustIDs;
    CREATE TEMPORARY TABLE TempCustIDs (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS TempParentIDs;
    CREATE TEMPORARY TABLE TempParentIDs (
			ParentID 		SMALLINT UNSIGNED PRIMARY KEY
    );
    
    IF IFNULL(ip_CustIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO TempCustIDs (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
    END IF;
    
    IF IFNULL(ip_ParentCateIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO TempParentIDs (ParentID) VALUES ('", REPLACE(ip_ParentCateIDs, ",", "'),('"),"');");
		PREPARE stmt2 FROM @sql;
		EXECUTE stmt2;
	END IF;

    DROP TEMPORARY TABLE IF EXISTS tempLatestRecordOfCategory;
    CREATE TEMPORARY TABLE tempLatestRecordOfCategory (
		CustID				BIGINT UNSIGNED
	,	CategoryID			SMALLINT UNSIGNED
    , 	LastModifiedDate	DATETIME
    );
    
    SET v_remark = 'Auto tag customer classification';
    
    INSERT INTO tempLatestRecordOfCategory(CustID, CategoryID, LastModifiedDate)
    SELECT 		cla.CustID
                ,(CASE WHEN cla.CategoryID = 151 THEN 51
                                    WHEN cla.CategoryID IN (72, 152) THEN 52
									WHEN cla.CategoryID IN (73, 153) THEN 53
                                    WHEN cla.CategoryID IN (74, 154) THEN 54 
                                    WHEN cla.CategoryID IN (75, 155) THEN 55
                                    WHEN cla.CategoryID IN (76, 156) THEN 56
									WHEN cla.CategoryID IN (77, 157) THEN 57
									WHEN cla.CategoryID IN (78, 158) THEN 58
									WHEN cla.CategoryID IN (79, 159) THEN 59
									WHEN cla.CategoryID = 80 THEN 60
                                    ELSE cla.CategoryID
								END) AS 'CategoryID'
                , MAX(cla.LastModifiedDate) AS 'LastModifiedDate'
    FROM		CTS_DataCenter.CTSCustomerClassification AS cla
		INNER JOIN TempCustIDs AS cust ON cla.CustID = cust.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON cla.CategoryID = a.CategoryID
    WHERE (IFNULL(ip_ParentCateIDs, '') = ''
			OR a.ParentID IN (SELECT ParentID FROM TempParentIDs))
	GROUP BY cla.CustID, CategoryID;

    SELECT 	c.CustID AS CustID
		,	b.CategoryName AS ParentCategoryName
		,	a.CategoryName
    FROM tempLatestRecordOfCategory AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID;  
	
	# Begin: Cleanup
	DROP TEMPORARY TABLE tempLatestRecordOfCategory;
	# End: Cleanup
END$$

DELIMITER ;