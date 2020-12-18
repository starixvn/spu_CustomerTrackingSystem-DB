/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_Category_Get4CustomerClass`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Category_Get4CustomerClass`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201216@Long.Luu	
		Task :		Get CTSCustomer Categories which have Customer Class
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201216@Long.Luu [Redmine ID: #132623]: Created 
            
		Param's Explanation:
	*/ 
    
	SELECT DISTINCT c.CategoryName, c.CategoryNameCN, cc.CustomerClass
	FROM CTS_DataCenter.CustomerCategory AS c
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS cc ON c.CategoryID = cc.CategoryID
	WHERE c.CategoryNameCN IS NOT NULL AND  c.CategoryNameCN <> ""
	ORDER BY cc.CustomerClass ASC;
    
END$$

DELIMITER ;