/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_GetInfoByCustIDList`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_GetInfoByCustIDList`(IN ip_CTSCustIDList TEXT)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210115@Casey.Huynh
		Task:		Insert Customer Complte [Redmine ID: 148849]. Re-Transfrom DCS Account and update LastInsertedCustID System Parameter
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
			ip_CTSCustIDList: String (custid01,custid02, custid03)
		Example:
			- CALL CTS_DataCenter.CTS_DC_CTSCustomer_GetInfoByCustIDList ('123,124,125')

	*/  
		CALL CTS_DC_Sys_SplitStringToTempItemTable(ip_CustIDList,',','BIGINT');
        
        SELECT 		CTSCustID
				,	CustID
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
        INNER JOIN	TempItemTable AS tmpCus ON cus.CustID = tmpCus.CustID
		
    
END$$
DELIMITER ;