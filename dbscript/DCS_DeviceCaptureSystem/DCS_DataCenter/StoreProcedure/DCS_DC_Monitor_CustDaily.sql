/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Monitor_CustDaily`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Monitor_CustDaily`(
		IN ip_Date 			DATE
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20230606@Jonathan.Doan
	    Task : Monitor Transform Transaction Level Customer
	    DB: DCS_DataCenter
	    Original:

	    Revisions:		    
			-	20230606@Jonathan.Doan: Created [Redmine ID: 189323]
            
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_Monitor_CustDaily('2023-06-06');
    */    
    
    SELECT DISTINCT cus.CTSCustID
	FROM DCS_DataCenter.Transaction07 AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS cus ON cus.AccountID = trans.AccountID
	WHERE trans.TransTime BETWEEN ip_Date AND '2023-04-01 23:59:59.9999';
    
END$$
DELIMITER ;
