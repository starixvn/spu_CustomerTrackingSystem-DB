/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Get`(
		IN ip_CTSCustID 	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20220908@Casey.Huynh
		Task:		Get Cust Classification Details by sport
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20220908@Casey.Huynh: Created [Redmine ID: #176992]
                - 20240321@Thomas.Nguyen: Add logic for Special CC BySport [Redmine ID: #201360]

		Param's Explanation (filtered by):
        
        Example:
				CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_Get(@CTSCustID:=572272);
*/ 

    SELECT	sb.SportID
		,	'-' AS CategoryName
        ,	sb.CustomerClass
	FROM CTS_DataCenter.SpecialCustomerClass_BySport AS sb 
	WHERE sb.CTSCustID = ip_CTSCustID
	UNION ALL
    SELECT	cls.SportID
		,	cat.CategoryName
        ,	cat.CustomerClass
    FROM	CTS_DataCenter.CTSCustomerClassification_BySport AS cls
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID
    WHERE	cls.CTSCustID = ip_CTSCustID 
		AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.SpecialCustomerClass_BySport AS sb WHERE sb.CTSCustID = cls.CTSCustID AND sb.SportID = cls.SportID);
    
END$$
DELIMITER ;