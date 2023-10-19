/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Report_LoginTransaction_GetDetailByDate`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Report_LoginTransaction_GetDetailByDate`(
		IN ip_TransDate DATE
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231017@Jonathan.Doan
	Task : Get report detail LoginTransaction by date
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231017@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Report_LoginTransaction_GetDetailByDate('2023-10-01');
	*/
    
	SELECT 	trans.TransDate
		,	trans.SubscriberID
		,	sub.SubscriberName
		,	trans.AccountID
		,	cts.CustID
		,	cts.Site
		,	cts.Currency
		,	cc.CustomerClass
		,	cc.CustomerClassName
		,	trans.TotalTrans
	FROM DCS_DataTrace.LoginTransactionSummary AS trans FORCE INDEX (UX_LoginTransactionSummary_Group)
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ctscc ON ctscc.CustID = cts.CustID AND cts.CustSubID = 0 -- Main Account
		INNER JOIN CTS_DataCenter.CustomerCategory cc on cc.CategoryID = ctscc.CategoryID
	WHERE trans.TransDate = ip_TransDate;
END$$
DELIMITER ;
