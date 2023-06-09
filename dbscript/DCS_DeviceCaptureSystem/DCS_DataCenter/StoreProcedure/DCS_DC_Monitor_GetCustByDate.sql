/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Monitor_GetCustByDate`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Monitor_GetCustByDate`(
		IN ip_TransDate 		DATE
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
        
        Example: CALL DCS_DC_Monitor_GetCustByDate('2023-06-06');
    */    
    
    DECLARE lv_LastMillisecondOfDate DATETIME(4);
    
    SET lv_LastMillisecondOfDate = CONCAT(DATE_FORMAT(ip_TransDate, '%Y-%m-%d'), ' 23:59:59.9999');
    
    SELECT DISTINCT cus.CustID
	FROM DCS_DataCenter.Transaction07 AS trans
		INNER JOIN CTS_DataCenter.CustDCSAccount AS cda ON cda.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = cda.CTSCustID AND cus.RoleID = 1
	WHERE trans.TransTime BETWEEN ip_TransDate AND lv_LastMillisecondOfDate;
    
END$$
DELIMITER ;
