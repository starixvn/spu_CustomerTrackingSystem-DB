CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetLatest`(IN ip_SubscriberId int, IN ip_Length int)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Adam.Tran
		Task:		Get latest transactions 
		DB:			DCS_DataCenter
        
		Revisions:
			- 20210330@Adam.Tran: Created [Redmine ID: #140348]            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.DCS_DC_Transaction_GetLatest(1, 100);
	*/
	
	DROP TEMPORARY TABLE IF EXISTS Temp_History_Transaction;
	CREATE TEMPORARY TABLE Temp_History_Transaction
	(
        TransTime	 		DATETIME, 		
		FirstDeviceCode		BIGINT(20),				
		IP					VARCHAR(50),
		Flagged				VARCHAR(100),
		Action				VARCHAR(100),
		ActionResult		VARCHAR(100),
		OS					VARCHAR(100),
		Browser				VARCHAR(100),
		URLDetails			VARCHAR(100),
		AccountID			BIGINT(20)
	);
	
	INSERT INTO Temp_History_Transaction
		SELECT 	trans.TransTime,                
				trans.FirstDeviceCode,				
                trans.IP,
				CASE 
					WHEN trans.Flagged = 5 THEN 'Robot (Browserless - Empty Token)'
					WHEN trans.Flagged = 6 THEN 'Robot (Browserless - Empty Analysis)'
					WHEN trans.Flagged = 7 THEN 'Robot (Browserless - Disabled JS)'
					WHEN trans.Flagged = 8 THEN 'Robot (Browserless - Invalid Analysis)'
					WHEN trans.Flagged = 9 THEN 'Robot (Browserless - Invalid Token)'
					WHEN trans.Flagged = 10 THEN 'Robot (Browserless - Invalid Device Code)'
					ELSE 'Human'
				END AS Flagged,
				aResult.Action,
				aResult.ActionResult,
				uAgent.OS,
				uAgent.Browser,
				url.URLDetails,
				0
		FROM DCS_DataCenter.Transaction07 AS trans
		LEFT JOIN DCS_DataCenter.UserAgent AS uAgent
				ON trans.UserAgentKey = uAgent.UserAgentKey
		LEFT JOIN DCS_DataCenter.ActionResult AS aResult
				ON trans.ActionResultID = aResult.ActionResultID
		LEFT JOIN DCS_DataCenter.URL AS url
				ON trans.URLID = url.URLID AND trans.SubscriberID = url.SubscriberID
		WHERE ip_SubscriberId != -1 AND trans.SubscriberID = ip_SubscriberId
		ORDER BY trans.TransTime ASC
		LIMIT ip_Length;	
	
	SELECT 	cust.UserName,
			cust.UserName2 AS LoginID,
			cust.CTSCustID,			
			tempTrans.TransTime,
			tempTrans.FirstDeviceCode AS Device,
			tempTrans.IP,
			tempTrans.Flagged AS RobotTracking,
			tempTrans.Action,
			tempTrans.ActionResult,
			tempTrans.OS AS DeviceType,
			tempTrans.Browser,
			tempTrans.URLDetails AS Domain
	FROM Temp_History_Transaction AS tempTrans
	INNER JOIN CTS_DataCenter.CustDCSAccount AS cAcc ON tempTrans.AccountID = cAcc.AccountID
	INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cAcc.CTSCustID = cust.CTSCustID;
	
END