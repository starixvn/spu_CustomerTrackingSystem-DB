DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCTSCustomerClassification` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCTSCustomerClassification`(
	IN ip_CTSCustID 	BIGINT UNSIGNED
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT 	a.CategoryID
		,	a.CategoryName
        ,	b.CategoryID AS ParentCategoryID
		,	b.CategoryName AS ParentCategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID ORDER BY s.SportGroupID ASC SEPARATOR ','),255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ','),255) AS SportGroupNameList
        ,	c.Remark
        ,	CASE
				WHEN c.LastModifiedBy = 0 THEN "System"
				ELSE u.UserName
			END AS LastModifiedBy
        ,	MAX(c.LastModifiedDate) AS LastModifiedDate
    FROM CTS_DataCenter.CTSCustomerClassification AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
		INNER JOIN CTS_DataCenter.SportGroup AS s ON c.SportGroupID = s.SportGroupID
        INNER JOIN CTS_Admin.CTSUser AS u ON c.LastModifiedBy = 0 OR c.LastModifiedBy = u.UserID
    WHERE c.CTSCustID = ip_CTSCustID
    GROUP BY a.CategoryID
		,	a.CategoryName
        ,	b.CategoryID
		,	b.CategoryName
        ,	c.Remark
        ,	c.LastModifiedBy
        , 	u.Username
    ORDER BY LastModifiedDate DESC;
    
END$$
DELIMITER ;
