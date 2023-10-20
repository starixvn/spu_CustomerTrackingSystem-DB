/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Report_DailyLoginTransactionSummary_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Report_DailyLoginTransactionSummary_Insert`(
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
        CALL DCS_DataTrace.DCS_DT_Report_DailyLoginTransactionSummary_Insert('2023-10-17', '2023-10-17');
	*/
    
-- 	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTrans;
--     
-- 	CREATE TEMPORARY TABLE Temp_LoginTrans(
-- 			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
-- 		, 	TransDate					DATETIME NOT NULL
-- 		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
-- 		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
-- 		, 	TotalTrans					INT UNSIGNED DEFAULT NULL
-- 		-- ,	KEY `IX_Temp_LoginTrans_TransDate` (`TransDate`)
-- 		-- ,	KEY `IX_Temp_LoginTrans_SubscriberID` (`SubscriberID`)
-- -- 		,	KEY `IX_Temp_LoginTrans_AccountID` (`AccountID`)
-- 	);
--     
--     INSERT INTO Temp_LoginTrans(TransDate, SubscriberID, AccountID, TotalTrans)
-- 	SELECT 	trans.TransDate
-- 		,	trans.SubscriberID
-- 		,	trans.AccountID
-- 		,	SUM(trans.TotalTrans) AS TotalTrans
-- 	FROM DCS_DataTrace.LoginTransactionSummary AS trans
-- 	WHERE trans.TransDate BETWEEN ip_FromDate AND ip_ToDate
-- 	GROUP BY trans.TransDate, trans.SubscriberID, trans.AccountID;
--     
-- 	SELECT 	trans.TransDate
-- 		,	sub.SubscriberName
-- 		,	cts.Site
-- 		,	CASE WHEN cts.IsLicensee = 1 THEN 'Deposit' ELSE 'Credit' END AS IsLicensee
-- 		,	cts.Currency
-- 		,	trans.TotalTrans
-- 	FROM Temp_LoginTrans AS trans
-- 		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
-- 		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
-- 		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID;
    
    
	SELECT 	trans.TransDate
		,	sub.SubscriberName
		,	cts.Site
		,	CASE WHEN cts.IsLicensee = 1 THEN 'Deposit' ELSE 'Credit' END AS IsLicensee
		,	cts.Currency
		,	SUM(trans.TotalTrans) AS TotalTrans
	FROM DCS_DataTrace.LoginTransactionSummary AS trans
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		INNER JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cts ON cts.CTSCustID = dcs.CTSCustID
	WHERE trans.TransDate BETWEEN ip_FromDate AND ip_ToDate
	GROUP BY trans.TransDate, trans.SubscriberID, trans.AccountID
    ORDER BY trans.TransDate ASC;
END$$
DELIMITER ;
