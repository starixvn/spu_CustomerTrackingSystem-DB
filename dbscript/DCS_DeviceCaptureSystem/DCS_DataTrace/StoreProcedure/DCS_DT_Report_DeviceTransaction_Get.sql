/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Report_DeviceTransaction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Report_DeviceTransaction_Get`(
		IN ip_FromDate DATE
    ,	IN ip_ToDate DATE
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231017@Jonathan.Doan
	Task : Get report DeviceTransaction
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231017@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Report_DeviceTransaction_Get('2023-10-01', '2023-10-10');
	*/
    
	SELECT 	trans.TransDate
		,	trans.SubscriberID
		,	sub.SubscriberName
		,	COUNT(trans.DeviceID) AS TotalDevice
	FROM DCS_DataTrace.LoginTransactionSummary AS trans FORCE INDEX (IX_LoginTransactionSummary_DeviceID)
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
	WHERE trans.TransDate BETWEEN ip_FromDate AND ip_ToDate
	GROUP BY trans.TransDate, trans.SubscriberID;
    
END$$
DELIMITER ;
