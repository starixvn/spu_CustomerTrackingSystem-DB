/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_GetNullUserName2`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_GetNullUserName2`(
		IN ip_PreCTSCustID	INT
    ,	IN ip_Size			INT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200118@CaseyHuynh
		Task:		Get List Of CTSCustomer with UserName is NULL 
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200118@CaseyHuynh:	Get customer for update SubscriberID - [Redmine: #148849]
            - 20210205@CaseyHuynh:	Update Get for CusSubID only - [Redmine: #148849]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
			- 20211013@Aries.Nguyen: Change index hint [Redmine ID: #157203]
        
		Param's Explanation (filtered by):   
        
        Example: 
			- CALL CTS_DC_CTSCustomer_GetNULLUserName2 (500,0)
	*/	  
	IF (ip_PreCTSCustID = 0)
    THEN
		SET	ip_PreCTSCustID = 35314000; # ON PRO The First CustSubID > 0 and UserName2 IS NULL 
    END IF;

	SELECT	cus.CTSCustID
		,	cus.CustID
		,	cus.CustSubID
	FROM CTS_DataCenter.CTSCustomer AS cus USE INDEX(IX_CTSCustomer_UserName2_CTSCustID_CustSubID)
	WHERE   cus.UserName2 IS NULL
		AND cus.CTSCustID > ip_PreCTSCustID
		AND cus.CustSubID > 0
    ORDER BY cus.CTSCustID 
    LIMIT ip_Size;   
    
END$$
DELIMITER ;
