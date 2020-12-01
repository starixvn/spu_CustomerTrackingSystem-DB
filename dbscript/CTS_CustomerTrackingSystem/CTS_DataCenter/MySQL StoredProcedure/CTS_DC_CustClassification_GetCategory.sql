/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetCategory`(
	IN ip_CTSCustID 	BIGINT UNSIGNED
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get Customer Category by CTSCustId
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
			- 20201201@Aries.Nguyen: 
            
		Param's Explanation:
	*/ 

    SELECT DISTINCT a.CategoryID, a.CategoryName, a.ParentID, a.DisplayOrder
    FROM CTS_DataCenter.CustomerCategory AS a
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS b ON a.CategoryID = b.CategoryID AND b.CTSCustID = ip_CTSCustID
    WHERE a.IsUsedManually = 1
		AND b.CategoryID IS NULL
		AND a.IsActive = 1
		AND a.CategoryID < 50
    ORDER BY a.DisplayOrder ASC; 
   
END$$

DELIMITER ;
