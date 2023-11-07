/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Profile_GetLoginStats`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Profile_GetLoginStats`(
		IN ip_CTSCustID BIGINT UNSIGNED
	,	IN ip_FromDate	DATE
    ,	IN ip_ToDate	DATE
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211214@Aries.Nguyen	
		Task :		Enrich the information on customer profile
		DB:			CTS_DataCenter
		
		Revisions:
			- 20211214@Aries.Nguyen: Created [Redmine ID: #165105]
			- 20231025@Jonas.Huynh: Get Invalid Browser Info and Bot Transaction [Redmine ID: #195095]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Profile_GetLoginStats(200);
	*/
	DECLARE lv_CountDesktopDevice_TillYesterday 		INT;
    DECLARE lv_CountMobileDevice_TillYesterday 			INT;
    DECLARE lv_CountDesktopDevice_YesterdayTillNow 		INT;
    DECLARE lv_CountMobileDevice_YesterdayTillNow 		INT;
    DECLARE lv_Count_Login					INT;
    DECLARE lv_Count_Login_OnTheFly			INT;
    DECLARE lv_Count_IP						INT;
    DECLARE lv_Count_Device					INT;
    DECLARE lv_Count_Bot_Trans				INT;
    DECLARE lv_Count_InvalidBrowser_Trans	INT;
    
    DECLARE lv_IsExcludeSubscriber			BIT DEFAULT(0); 	
    DECLARE lv_SubSourceID_DirectAPI		TINYINT DEFAULT(1);
	DECLARE lv_SubSourceID_OddsFeed			TINYINT DEFAULT(2);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountID;
	CREATE TEMPORARY TABLE Temp_AccountID(
			AccountID	BIGINT UNSIGNED PRIMARY KEY
	);	
	
    SELECT 1
    INTO lv_IsExcludeSubscriber
    FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = cus.SubscriberID
	WHERE cus.CTSCustID = ip_CTSCustID 
		AND sub.SubscriberSourceID IN (lv_SubSourceID_DirectAPI, lv_SubSourceID_OddsFeed);
    
    IF (lv_IsExcludeSubscriber = 0)
    THEN
	    INSERT IGNORE INTO Temp_AccountID(AccountID)
		SELECT AccountID 
		FROM CTS_DataCenter.CustDCSAccount
		WHERE  CTSCustID  = ip_CTSCustID; 
    
		SELECT  SUM(sm.DeviceDesktop)
			,   SUM(sm.DeviceMobile)
			,   SUM(sm.TotalLogin)
		INTO 	lv_CountDesktopDevice_TillYesterday
			,	lv_CountMobileDevice_TillYesterday
			,	lv_Count_Login
		FROM DCS_DataCenter.SumAccountLogin AS sm
		WHERE sm.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND sm.TransDate BETWEEN ip_FromDate AND ip_ToDate; 
		
		SELECT  COUNT(1)
		INTO 	lv_Count_IP
		FROM DCS_DataCenter.AccountIP AS ip
		WHERE ip.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND ip.LastTransDate BETWEEN ip_FromDate AND ip_ToDate; 
		
		SELECT  COUNT(1)
		INTO 	lv_Count_Device
		FROM DCS_DataCenter.AccountDevice AS dv
		WHERE dv.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND dv.LastTransDate BETWEEN ip_FromDate AND ip_ToDate; 
		
		SELECT  SUM(CASE WHEN st.GroupID = 2 THEN lg.TotalTrans ELSE 0 END) AS Invalid
			,	SUM(CASE WHEN st.GroupID = 3 THEN lg.TotalTrans ELSE 0 END) AS Bot
		INTO 	lv_Count_InvalidBrowser_Trans
			,	lv_Count_Bot_Trans
		FROM DCS_DataTrace.LoginTransactionSummary AS lg
			INNER JOIN DCS_DataCenter.StaticList AS st ON st.ItemID = lg.Flagged AND st.ListID = 1
		WHERE lg.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND lg.TransDate BETWEEN ip_FromDate AND ip_ToDate; 
            
		/* Correct Mobile/Desktop Trans */
        DROP TEMPORARY TABLE IF EXISTS Temp_AccountLastSummedDate;
		CREATE TEMPORARY TABLE Temp_AccountLastSummedDate(
				AccountID		BIGINT UNSIGNED PRIMARY KEY
			,	LastSummedDate	DATE
		) ENGINE=InnoDB;
        
        DROP TEMPORARY TABLE IF EXISTS Temp_AccountTransUserAgent;
		CREATE TEMPORARY TABLE Temp_AccountTransUserAgent(
				TransID			BIGINT UNSIGNED PRIMARY KEY
			,	UserAgentKey	VARCHAR(32)
		) ENGINE=InnoDB;
		
        INSERT INTO Temp_AccountLastSummedDate(AccountID, LastSummedDate)
       	SELECT AccountID, ip_FromDate
		FROM Temp_AccountID;
        
        WITH CTE_LastLoginTrans AS (
			  SELECT sm.AccountID, MAX(sm.TransDate) AS LastSummedDate
			  FROM DCS_DataCenter.SumAccountLogin AS sm
			  WHERE sm.AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			  GROUP BY sm.AccountID
		 )
         UPDATE Temp_AccountLastSummedDate AS tmp
			INNER JOIN CTE_LastLoginTrans AS cte ON cte.AccountID = tmp.AccountID
		 SET tmp.LastSummedDate = DATE_ADD(cte.LastSummedDate, INTERVAL 1 DAY);
        
        INSERT IGNORE INTO Temp_AccountTransUserAgent(TransID, UserAgentKey)
		SELECT  t.TransID
			,	t.UserAgentKey
		FROM DCS_DataCenter.Transaction07 AS t
			INNER JOIN Temp_AccountLastSummedDate AS a ON t.AccountID = a.AccountID AND t.CreatedDate >= a.LastSummedDate;
		
        SELECT COUNT(1) + lv_Count_Login
        INTO lv_Count_Login_OnTheFly
        FROM Temp_AccountTransUserAgent;
        
		SELECT 	SUM(CASE WHEN dv.GroupName = 'Mobile' THEN 1 ELSE 0 END) AS DeviceMobile
			,	SUM(CASE WHEN dv.GroupName = 'Desktop' THEN 1 ELSE 0 END) AS DeviceDesktop
		INTO 	lv_CountMobileDevice_YesterdayTillNow
			,	lv_CountDesktopDevice_YesterdayTillNow
        FROM Temp_AccountTransUserAgent AS t
			LEFT JOIN DCS_DataCenter.UserAgent  AS ua ON ua.UserAgentKey  = t.UserAgentKey
			LEFT JOIN DCS_DataCenter.DeviceType AS dv ON dv.DeviceTypeID = ua.DeviceTypeID;
        /* END Correct Mobile/Desktop Trans */
        
        /* Correct Total Trans */
        SELECT  SUM(TotalTrans)
		INTO 	lv_Count_Login
		FROM DCS_DataTrace.LoginTransactionSummary
		WHERE AccountID IN (SELECT tmp.AccountID FROM Temp_AccountID AS tmp )
			AND TransDate BETWEEN ip_FromDate AND ip_ToDate;
        /* END Correct Total Trans */
            
		SELECT 	lv_Count_Bot_Trans 											AS BotTrans
			,	ROUND((lv_Count_Bot_Trans/lv_Count_Login)*100,2)			AS BotTransPercentage
			,	lv_Count_InvalidBrowser_Trans 								AS InvalidBrowser
			,	ROUND((lv_Count_InvalidBrowser_Trans/lv_Count_Login)*100,2)	AS InvalidBrowserPercentage
			,	(lv_CountDesktopDevice_TillYesterday 
					+ CASE WHEN lv_CountDesktopDevice_YesterdayTillNow IS NULL 
						THEN 0 ELSE lv_CountDesktopDevice_YesterdayTillNow END) AS DesktopUsage
			,	(lv_CountMobileDevice_TillYesterday 
					+ CASE WHEN lv_CountMobileDevice_YesterdayTillNow IS NULL 
						THEN 0 ELSE lv_CountMobileDevice_YesterdayTillNow END)	AS MobileUsage
			,	lv_Count_IP 												AS IP
			,	lv_Count_Device 											AS Device
			,	lv_Count_Login_OnTheFly 									AS Login;
	END IF;
END$$

DELIMITER ;