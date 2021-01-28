/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_GetNULLUserName2`;
DELIMITER $$
CREATE PROCEDURE `CTS_DC_CTSCustomer_GetNULLUserName2`(
		IN ip_PreCTSCustID INT
    ,	IN ip_Size INT)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200118@CaseyHuynh
		Task:		Get List Of CTSCustomer with UserName is NULL 
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200118@CaseyHuynh:	Get customer for update SubscriberID - [Redmine: #148849]
        
		Param's Explanation (filtered by):         
        
        CALL CTS_DC_CTSCustomer_GetNULLUserName2 (500,0,1)
	*/	  
	
	SELECT 		cus.CTSCustID
			,	cus.CustID
			,	cus.CustSubID
	FROM 		CTS_DataCenter.CTSCustomer AS cus
	WHERE 		cus.UserName2 IS NULL
				AND cus.CTSCustID > ip_PreCTSCustID
    ORDER BY	cus.CTSCustID 
    LIMIT 		ip_Size;   
    
END$$
DELIMITER ;
