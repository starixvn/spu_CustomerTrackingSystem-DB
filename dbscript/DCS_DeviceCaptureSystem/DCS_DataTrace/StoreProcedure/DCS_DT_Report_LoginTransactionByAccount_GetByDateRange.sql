/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Report_LoginTransactionByAccount_GetByDateRange`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Report_LoginTransactionByAccount_GetByDateRange`(
		IN ip_FromDate 	DATE
    ,	IN ip_ToDate 	DATE
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20240315@Jonathan.Doan
	Task : Get report LoginTransactionSummaryByAccount
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20240315@Jonathan.Doan: Created [Redmine ID: 195332]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataTrace.DCS_DT_Report_LoginTransactionByAccount_GetByDateRange('2024-03-15', '2024-03-15');
	*/
    
	-- DROP TEMPORARY TABLE IF EXISTS Temp_CountRawTransaction07;
--     
-- 	CREATE TEMPORARY TABLE Temp_CountRawTransaction07(
-- 			ID					INT UNSIGNED NOT NULL PRIMARY KEY
-- 		, 	TransDate			DATE NOT NULL
-- 		, 	SubscriberID		INT UNSIGNED
-- 		, 	AccountID			BIGINT UNSIGNED
-- 		, 	CountUserAgent		INT UNSIGNED DEFAULT 0
-- 		, 	CountDevice			INT UNSIGNED DEFAULT 0
-- 	);
--     
--     INSERT INTO Temp_CountRawTransaction07(TransDate, SubscriberID, AccountID, CountUserAgent, CountDevice)
--     SELECT 	TransDate
-- 		,	SubscriberID
--         ,	AccountID
--         ,	COUNT(DISTINCT CASE WHEN RawUserAgentID = 0 THEN NULL ELSE RawUserAgentID END) AS CountUserAgent
--         ,	COUNT(DISTINCT CASE WHEN DeviceID = 0 THEN NULL ELSE DeviceID END) AS CountDevice
--     FROM DCS_DataTrace.RawTransaction07 AS trans
--     WHERE TransDate BETWEEN ip_FromDate AND ip_ToDate
--     GROUP BY TransDate, SubscriberID, AccountID;
--     
--     ALTER TABLE Temp_CountRawTransaction07
--     ADD KEY IX_Temp_CountRawTransaction07_Group(TransDate, SubscriberID, AccountID);
    
    select 	trans.TransDate
		,	trans.SubscriberID
		,	sub.SubscriberName
		,	trans.AccountID
		,	acc.LoginName
		,	cus.CustID
		,	cus.Site
		,	CASE WHEN cus.IsLicensee = 1 THEN 'Deposit' ELSE 'Credit' END as _type
		,	case sub.SubscriberSourceID when 0 THEN 'Others' WHEN 1 THEN 'Direct API' WHEN 1 THEN 'OddsFeed' ELSE 'Unknow' END AS LicenseeType 
		,	SUM(trans.TotalTrans) AS TotalTrans
		,	SUM(trans.TotalInvalidBrowers) AS TotalInvalidBrowers
		,	SUM(trans.TotalBotTrans) AS TotalBotTrans
		,	SUM(trans.TotalNoDeviceTrans) AS TotalNoDeviceTrans
	from DCS_DataTrace.LoginTransactionSummaryByAccount AS trans
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		INNER JOIN DCS_DataCenter.Account AS acc ON acc.AccountID = trans.AccountID
		INNER JOIN CTS_DataCenter.CustDCSAccount AS cda ON cda.AccountID = trans.AccountID
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = cda.CTSCustID
	WHERE trans.TransDate BETWEEN ip_FromDate AND ip_ToDate
	GROUP BY trans.TransDate, trans.SubscriberID, trans.AccountID;
END$$
DELIMITER ;
