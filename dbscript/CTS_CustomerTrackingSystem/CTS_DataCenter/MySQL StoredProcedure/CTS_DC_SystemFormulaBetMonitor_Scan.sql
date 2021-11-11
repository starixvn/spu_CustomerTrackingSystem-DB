/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_SystemFormulaBetMonitor_Scan`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SystemFormulaBetMonitor_Scan`()
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Return Cust list to scan
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: Created [Redmine ID: 164148]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_SystemFormulaBetMonitor_Scan();
	*/
    
	DELETE sfb
    FROM CTS_DataCenter.SystemFormulaBetMonitor AS sfb
		INNER JOIN CTS_Archive.CTSCustomerAssociationStatus AS cas ON sfb.CustID = cas.CustID
    WHERE DATEDIFF(CURRENT_DATE(), GREATEST(sfb.CreatedDate, cas.LastTicketDate)) >= 60;
    
    SELECT 	sfb.CustID
		,	cus.UserName
        ,	cus.RoleID
        ,	ctc.CustomerClass
    FROM CTS_DataCenter.SystemFormulaBetMonitor AS sfb
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON sfb.CustID = cus.CustID AND cus.CustSubID = 0
        INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON cus.CustID = ccl.CustID 
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS ctc ON ccl.CategoryID = ctc.CategoryID
	WHERE sfb.CreatedDate < CURRENT_DATE(); 

END$$
DELIMITER ;

