/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Transform_RawTrans_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Transform_RawTrans_Insert`(
		IN ip_RawTransJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20190610@Casey.Huynh
		Task : Insert to Raw Table
		DB: FPS_RawTrans
		Original:

		Revisions:
			- 20201006@CaseyHuynh: Move New Server, Move table RawTransaction from DB "DCS_RawTransaction" to "DCS_Extra" [Redmine ID: #143011]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
            - 20211129@Casey.Huynh: Remove FingerprintMoreInfo Column [Redmine ID: #165167]
			- 20230327@Terry.Nguyen: Add InsertTime [Redmine ID: #185185]
			- 20230426@Jonathan.Doan: Add BotD [Redmine ID: #186644]
            - 2023292023@Casey.Huynh: CTMAX, Velki [RedmineID: #190118]
			- 20230809@Terry.Nguyen: Add IP Info [RedmineID: #192402]
            - 20230811@Terry.Nguyen: Update IP Info [RedmineID: #192402]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Transform_RawTrans_Insert ('[
					{"LoginName":"mytam","SubscriberName":"MAXBET789Y","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:00.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
				,	{"LoginName":"hanhi","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:01.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
				,	{"LoginName":"buianhtuan","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:02.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
				,	{"LoginName":"hanhi","SubscriberName":"Velki","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:03.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
				,	{"LoginName":"buianhtuan","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:04.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
				,	{"LoginName":"lannha","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:05.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
				,	{"LoginName":"phanmanhquynh","SubscriberName":"CTMAX","TransStatus":"0","Action":"login","ActionResult":"login -> successfully","DeviceCode":"a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode":"f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","InvalidDevice":null,"IP":"103.199.41.17","IPId":1741105425,"PluginID":null,"TransTime":"2023-06-29 00:00:06.0201","URL":"http://l9j7ma.cx5888.com/FpsHandler","UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","FlaggedCode":"unknown", "BotDetection":""}
				,	{"LoginName":"phamhoainam","SubscriberName":"Velki","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:07.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
				,	{"LoginName":"phamhoainam","SubscriberName":"MAXBET789Y","TransStatus":"0", "Action":"login","ActionResult":"login -> successfully","DeviceCode":"6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode":"ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","InvalidDevice":null,"IP":"14.167.17.120","IPId":245830008,"PluginID":null,"TransTime":"2023-06-29 00:00:07.0201","URL":"http://m122.viva88.net:806/FpsHandler","UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","FlaggedCode":"headless_chrome", "BotDetection":"detectAppVersion,detectUserAgent"}
			]');

	*/
	
    DECLARE lv_FlaggedHuman	INT UNSIGNED DEFAULT 1;
    DECLARE lv_InsertionTime TIMESTAMP(4) DEFAULT CURRENT_TIMESTAMP(4);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions(
			ID							INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	LoginName					VARCHAR(100) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NOT NULL	
		,	SubscriberName				VARCHAR(50) 						NOT NULL
		,	TransTime					TIMESTAMP(4)	 					NOT NULL
		,	DeviceCode					VARCHAR(32) 						NULL		COMMENT 'Device Inject Code: 32 characters is auto generated'
		,	FingerprintCode				VARCHAR(620)						NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
		,	UserAgent					VARCHAR(1000)						NULL
		,	IP							VARCHAR(50) 						NULL
        ,	IPID						DECIMAL(50,0)						NULL
		,	PluginID					BIGINT 								NULL	
		,	URL							VARCHAR(500) 						NULL
        ,	`Action`					VARCHAR(100) 						NULL
		,	ActionResult				VARCHAR(100) 						NULL
		,	InvalidDevice				VARCHAR(1000)						CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		,	TransStatus					BIT(16)								NULL
        ,	FlaggedCode					VARCHAR(100)						NULL
        ,	BotDetection				LONGTEXT							NULL
        ,	BotDetectionValue			BIT(32)								NULL		DEFAULT 0
        ,	BotComponentID				BIGINT UNSIGNED						NULL
        ,	BotComponent				LONGTEXT							NULL
        ,	BotComponentCode			VARCHAR(100)						NULL
		,	Country						VARCHAR(128)						NULL
		,	CountryCode					VARCHAR(45)							NULL		
		,	Region						VARCHAR(128)						NULL		
		,	City						VARCHAR(128)						NULL		
		,	ISP							VARCHAR(128)						NULL
		,	IPInfoID					INT	UNSIGNED						NULL
        ,	IPInfoCode					BIGINT								NULL
        
		,	INDEX IX_Temp_Transactions_BotComponentCode(BotComponentCode)
    );     
        
	DROP TEMPORARY TABLE IF EXISTS Temp_BotDetection;
	CREATE TEMPORARY TABLE Temp_BotDetection(
			ID							INT UNSIGNED PRIMARY KEY
        ,	BotDetectionValue			BIT(32)		NULL		DEFAULT 0		
    );     
		
	INSERT INTO Temp_Transactions(LoginName, SubscriberName, TransTime, DeviceCode, FingerprintCode, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FlaggedCode, BotDetection, BotComponent, BotComponentCode, Country, CountryCode, Region, City, ISP, IPInfoCode)
	SELECT	rt.LoginName
		,	rt.SubscriberName
		,	rt.TransTime
		,	(CASE WHEN rt.DeviceCode IS NULL THEN NULL ELSE rt.DeviceCode END) AS DeviceCode
		,	(CASE WHEN rt.FingerprintCode IS NULL OR rt.DeviceCode IS NULL	THEN NULL ELSE rt.FingerprintCode END) AS FingerprintCode
		,	LEFT((CASE WHEN rt.UserAgent IS NULL THEN NULL ELSE rt.UserAgent END),1000) AS UserAgent
		,	(CASE WHEN rt.IP IS NULL THEN NULL ELSE rt.IP END) AS IP
		,	(CASE WHEN rt.IPID = 0 THEN NULL ELSE rt.IPID END) AS IPID
		,	(CASE WHEN rt.PluginID = 0 THEN NULL ELSE rt.PluginID END) AS PluginID            
		,	(CASE WHEN rt.URL IS NULL THEN NULL ELSE rt.URL END) AS URL
		,	(CASE WHEN rt.Action IS NULL THEN NULL ELSE rt.Action END) AS Action
		,	(CASE WHEN rt.ActionResult IS NULL THEN NULL ELSE rt.ActionResult END) AS ActionResult
		,	LEFT((CASE WHEN rt.InvalidDevice IS NULL THEN NULL ELSE rt.InvalidDevice END),1000) AS InvalidDevice
		,	rt.TransStatus
		,	rt.FlaggedCode
		,	rt.BotDetection
		,	rt.BotComponent		
		,	MD5(rt.BotComponent) AS BotComponentCode
		,	Country
		,	CountryCode
		,	Region
		,	City
		,	ISP
        ,	IPInfoCode
	FROM	JSON_TABLE(
			ip_RawTransJson,
			 "$[*]" COLUMNS(
								LoginName				VARCHAR(100)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.LoginName"       
							,	SubscriberName			VARCHAR(50) 	PATH "$.SubscriberName"   
							,	TransTime				TIMESTAMP(4) 	PATH "$.TransTime"
							,	DeviceCode				VARCHAR(32)		PATH "$.DeviceCode"
							,	FingerprintCode			VARCHAR(620)	PATH "$.FingerprintCode"
							,	UserAgent				TEXT 			PATH "$.UserAgent"
							,	IP						VARCHAR(50) 	PATH "$.IP"
                            ,	IPID					DECIMAL(50,0)	PATH "$.IPId"
							,	PluginID				BIGINT 			PATH "$.PluginID"
							,	URL						VARCHAR(500) 	PATH "$.URL"
                            ,	Action					VARCHAR(100)	PATH "$.Action"
							,	ActionResult			VARCHAR(100) 	PATH "$.ActionResult"
                            ,	InvalidDevice			TEXT			CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.InvalidDevice"
                            ,	TransStatus				BIT(16)			PATH "$.TransStatus"
                            ,	FlaggedCode				VARCHAR(100)	PATH "$.FlaggedCode"
                            ,	BotDetection			LONGTEXT		PATH "$.BotDetection"
                            ,	BotComponent			LONGTEXT		PATH "$.BotComponent"
							,	Country					VARCHAR(128)	PATH "$.Country"
							,	CountryCode				VARCHAR(45)		PATH "$.CountryCode"
							,	Region					VARCHAR(128)	PATH "$.Region"
							,	City					VARCHAR(128)	PATH "$.City"
							,	ISP						VARCHAR(128)	PATH "$.ISP"
                            ,	IPInfoCode				BIGINT			PATH "$.IPInfoCode"
				)
		   ) AS  rt; 
           
	INSERT INTO Temp_BotDetection(ID, BotDetectionValue)
    SELECT 	tmp.ID
		, 	SUM(bd.Value) as Value
	FROM Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.BotDetection bd ON FIND_IN_SET(bd.Name, tmp.BotDetection)
	GROUP BY tmp.ID;
    
	UPDATE Temp_Transactions AS tmp
		INNER JOIN Temp_BotDetection tmpBD ON tmpBD.ID = tmp.ID
	SET tmp.BotDetectionValue = tmpBD.BotDetectionValue;
    
    INSERT IGNORE INTO DCS_Extra.BotComponent(Code, Component, IsHuman, CreatedDate, ModifiedDate)
    WITH cte_BotComponent AS (
		SELECT 	DISTINCT 
				BotComponentCode AS Code
			,	BotComponent AS Component
			,	FlaggedCode
		FROM Temp_Transactions AS tmp
    )
    SELECT 	cte.Code
		,	cte.Component
		,	CASE WHEN cte.FlaggedCode = 'Human' THEN 1 ELSE 0 END AS IsHuman
		,	lv_InsertionTime AS CreatedDate
		,	DATE(lv_InsertionTime) AS ModifiedDate
    FROM cte_BotComponent AS cte
    WHERE NOT EXISTS (SELECT 1 FROM DCS_Extra.BotComponent bc WHERE bc.Code = cte.Code);
    
    UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.BotComponent AS bds ON bds.Code = tmp.BotComponentCode
	SET tmp.BotComponentID = bds.ID;
	
    
    #==========================
	
	INSERT IGNORE INTO DCS_Extra.IPInfo(IPInfoCode, Country, CountryCode, City, Region, ISP)
	WITH tmp_IPInfo AS (
		SELECT DISTINCT
				IPInfoCode
			,	Country
            ,	CountryCode
            ,	City
            ,	Region
            ,	ISP
		FROM Temp_Transactions AS tmp
	)
	SELECT 		tmpIP.IPInfoCode
			,	tmpIP.Country
            ,	tmpIP.CountryCode
            ,	tmpIP.City
            ,	tmpIP.Region
            ,	tmpIP.ISP
    FROM tmp_IPInfo AS tmpIP
    WHERE NOT EXISTS (SELECT 1 FROM DCS_Extra.IPInfo ipI WHERE ipI.IPInfoCode = tmpIP.IPInfoCode); 
	
	UPDATE Temp_Transactions AS tmp
		INNER JOIN DCS_Extra.IPInfo AS ipI ON ipI.IPInfoCode = tmp.IPInfoCode
	SET tmp.IPInfoID = ipI.IPInfoID;   
    
	INSERT INTO DCS_Extra.RawTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, UserAgent, IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, InsertTime, BotDetectionValue, BotComponentID, IPInfoID)
	SELECT	rt.LoginName
		,	rt.SubscriberName
		,	rt.TransTime
		,	DATE(rt.TransTime) AS CreatedDate
		,	rt.DeviceCode
		,	rt.FingerprintCode
		,	rt.UserAgent
		,	rt.IP
        ,	rt.IPID
        ,	sl.ItemID AS Flagged
		,	rt.PluginID
		,	rt.URL
        ,	rt.Action
		,	rt.ActionResult
        ,	rt.InvalidDevice
        ,	rt.TransStatus
		,	lv_InsertionTime as InsertTime
		,	rt.BotDetectionValue
		,	rt.BotComponentID
		,	rt.IPInfoID
	FROM Temp_Transactions AS rt
		LEFT JOIN DCS_Extra.StaticList AS sl 	ON sl.ListCode = 'Flagged'
													AND sl.ItemCode = rt.FlaggedCode;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
END$$

DELIMITER ;
