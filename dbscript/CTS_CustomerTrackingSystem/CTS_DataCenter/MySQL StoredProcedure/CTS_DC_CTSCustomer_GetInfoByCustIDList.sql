/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_GetInfoByCustIDList`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_GetInfoByCustIDList`(
	IN ip_CustIDList TEXT
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210115@Casey.Huynh
		Task:		CTSCustomer Flow [Redmine ID: 148849]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210115@Casey.Huynh: Created [Redmine ID: 148849]
            
		Param's Explanation (filtered by):
			ip_CustIDList: String (custid01,custid02, custid03)
		Example:
			- CALL CTS_DataCenter.CTS_DC_CTSCustomer_GetInfoByCustIDList ('123,124,125')

	*/  
		CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_CustIDList,',','BIGINT');
        
        SELECT 		CustID
                ,	Currency
                ,	CurrencyID
                ,	SRecommend
                ,	MRecommend
                ,	Recommend
                ,	CustStatusID
                ,	Danger1
                ,	Danger2
                ,	Danger3
        FROM		CTS_DataCenter.CTSCustomer AS cus
        INNER JOIN	TempItemTable AS tmpCus ON cus.CustID = tmpCus.Item
        WHERE		CustSubID = 0;		
    
END$$
DELIMITER ;