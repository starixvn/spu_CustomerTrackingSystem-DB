/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
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
            - 20230403@Jonas.Huynh [Redmine ID: #186271]: Support LAP  (ClassName) 
            - 20230517@Jonas.Huynh [Redmine ID: #188388]: Support TW BI (SabaRiskLevel) 
		Param's Explanation:
	*/ 
    
	SELECT DISTINCT c.CategoryName
				, 	c.CategoryNameCN
				, 	c.CustomerClass
                , 	c.CustomerClassName		
                , 	c.CustomerClassNameCN
                , 	c.SabaIntelligent_RiskLevel		AS SabaRiskLevel
                ,	c.SabaIntelligent_RiskLevel_TCN	AS SabaRiskLevelTCN
                ,	c.SabaIntelligent_RiskLevel_SCN	AS SabaRiskLevelSCN
	FROM CTS_DataCenter.CustomerCategory AS c
	WHERE c.IsActive = 1
		AND c.CategoryNameCN IS NOT NULL 
        AND c.CategoryNameCN <> "" 
        AND CustomerClass IS NOT NULL
	ORDER BY c.CustomerClass ASC;
    
END$$

DELIMITER ;