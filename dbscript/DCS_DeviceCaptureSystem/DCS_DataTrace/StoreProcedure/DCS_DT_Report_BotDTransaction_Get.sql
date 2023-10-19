/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Report_BotDTransaction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Report_BotDTransaction_Get`(
		IN ip_FromDate DATE
    ,	IN ip_ToDate DATE
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231017@Jonathan.Doan
	Task : Get report BotDTransaction
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231017@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Report_BotDTransaction_Get('2023-10-17', '2023-10-17');
	*/
    
	SELECT 	trans.TransDate
		,	sub.SubscriberName
		,	cts.Site
		,	CASE WHEN cts.IsLicensee = 1 THEN 'Deposit' ELSE 'Credit' END AS IsLicensee
		,	cts.Currency
		,	sl.ItemName AS Flagged
		,	SUM(trans.TotalTrans) AS TotalTrans
	FROM DCS_DataTrace.LoginTransactionSummary AS trans
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
		INNER JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.ItemID = trans.Flagged
	WHERE trans.TransDate BETWEEN ip_FromDate AND ip_ToDate
	GROUP BY trans.TransDate, trans.SubscriberID, trans.AccountID, sl.ItemName
    ORDER BY trans.TransDate ASC;
    
END$$
DELIMITER ;
