/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Report_MissingTransaction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Report_MissingTransaction_Get`(
		IN ip_FromDate DATE
    ,	IN ip_ToDate DATE
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231017@Jonathan.Doan
	Task : Get report LoginTransaction
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231017@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Report_MissingTransaction_Get('2023-10-01', '2023-10-05');
	*/
    
    SELECT 	lts.TransDate
		,	lts.SubscriberID
		,	sub.SubscriberName
		,	lts.TotalTrans
		,	COUNT(CASE WHEN mt.SubscriberID IS NULL THEN mt.CustID END) CountCustWithoutTrans
		,	COUNT(CASE WHEN mt.SubscriberID IS NOT NULL THEN mt.CustID END) CountCustMissingTrans
	FROM DCS_DataTrace.DailyLoginTransactionSummary AS lts FORCE INDEX (UX_DailyLoginTransactionSummary_Group)
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = lts.SubscriberID
		LEFT JOIN DCS_DataTrace.MissingTransaction AS mt ON lts.TransDate = mt.TransDate AND lts.SubscriberID = mt.SubscriberID
	WHERE mt.TransDate BETWEEN ip_FromDate AND ip_ToDate
		AND mt.MissingType = 1
	GROUP BY mt.TransDate, mt.SubscriberID;
    
END$$
DELIMITER ;
