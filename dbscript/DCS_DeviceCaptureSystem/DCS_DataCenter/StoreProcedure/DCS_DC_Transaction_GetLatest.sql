/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transaction_GetLatest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetLatest`(
		IN ip_SubscriberId	INT
	, 	IN ip_Length		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Adam.Tran
		Task:		Get latest transactions 
		DB:			DCS_DataCenter
        
		Revisions:
			- 20210330@Adam.Tran: Created [Redmine ID: #140348]  
			- 20210412@Aries.Nguyen: Fix issue performance when filter all  [Redmine ID: #153009]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.DCS_DC_Transaction_GetLatest(1, 100);
	*/
	
	SELECT 	cust.UserName
		,	cust.UserName2 AS LoginID
		,	subs.SubscriberName
		,	cust.CTSCustID
		,	trans.TransTime            
		,	trans.FirstDeviceCode	
        ,	trans.IP
		,	CASE 
				WHEN trans.Flagged = 5 THEN 'Robot (Browserless - Empty Token)'
				WHEN trans.Flagged = 6 THEN 'Robot (Browserless - Empty Analysis)'
				WHEN trans.Flagged = 7 THEN 'Robot (Browserless - Disabled JS)'
				WHEN trans.Flagged = 8 THEN 'Robot (Browserless - Invalid Analysis)'
				WHEN trans.Flagged = 9 THEN 'Robot (Browserless - Invalid Token)'
				WHEN trans.Flagged = 10 THEN 'Robot (Browserless - Invalid Device Code)'
				ELSE 'Human'
			END AS Flagged
		,	aResult.Action
		,	aResult.ActionResult
		,	uAgent.OS
		,	uAgent.Browser
		,	url.URLDetails
		,	trans.AccountID
		,	trans.TransID
		FROM DCS_DataCenter.Transaction07 AS trans
			LEFT JOIN CTS_DataCenter.CustDCSAccount AS cAcc ON trans.AccountID = cAcc.AccountID
			LEFT JOIN CTS_DataCenter.CTSCustomer AS cust ON cAcc.CTSCustID = cust.CTSCustID AND cust.SubscriberID = trans.SubscriberID
			LEFT JOIN DCS_DataCenter.UserAgent AS uAgent ON trans.UserAgentKey = uAgent.UserAgentKey
			LEFT JOIN DCS_DataCenter.ActionResult AS aResult ON trans.ActionResultID = aResult.ActionResultID
			LEFT JOIN DCS_DataCenter.URL AS url ON trans.URLID = url.URLID AND trans.SubscriberID = url.SubscriberID
			LEFT JOIN CTS_Admin.Subscriber AS subs ON cust.SubscriberID = subs.SubscriberID			
		WHERE (ip_SubscriberId = -1 OR trans.SubscriberID = ip_SubscriberId) AND  cAcc.AccountID IS NOT NULL AND cust.CTSCustID IS NOT NULL
		ORDER BY trans.TransTime DESC
		LIMIT ip_Length;
	
END$$

DELIMITER ;