/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawTrans_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawTrans_Insert`(
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
			- 20201006@CaseyHuynh: Move New Server, Move table RawTransaction from DB "DCS_RawTransaction" to "DCS_DataCenter" [Redmine ID: #143011]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
            - 20211129@Casey.Huynh: Remove FingerprintMoreInfo Column [Redmine ID: #165167]
			- 20230327@Terry.Nguyen: Add InsertTime [Redmine ID: #185185]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_RawTrans_Insert ('
            [{"Action" : "login","ActionResult" : "login -> successfully","DeviceCode" : "6f6bea6ce7074622bc18a921f8be1e60","FingerprintCode" : "ade5b939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","Flagged" : 2,"InvalidDevice" : null,"IP" : "14.167.17.120","IPId" : 245830008,"LoginName" : "U702202002","PluginID" : null,"SubscriberName" : "MAXBET789Y","TransStatus" : "0","TransTime" : "2021-11-21 00:00:00.0201","URL" : "http://m122.viva88.net:806/FpsHandler","UserAgent" : "Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1"}
			,{"Action" : "login","ActionResult" : "login -> successfully","DeviceCode" : "a707e6620cce48a4ada3cd3887e5d77f","FingerprintCode" : "f4cf2f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","Flagged" : 2,"InvalidDevice" : null,"IP" : "103.199.41.17","IPId" : 1741105425,"LoginName" : "Khanh1973","PluginID" : null,"SubscriberName" : "11BET","TransStatus" : "0","TransTime" : "2021-11-21 00:00:00.2418","URL" : "http://l9j7ma.cx5888.com/FpsHandler","UserAgent" : "Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36"}
			]
            ');

	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions(
			LoginName					VARCHAR(100) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NOT NULL	
		,	SubscriberName				VARCHAR(50) 						NOT NULL
		,	TransTime					TIMESTAMP(4)	 					NOT NULL
		,	DeviceCode					VARCHAR(32) 						NULL		COMMENT 'Device Inject Code: 32 characters is auto generated'
		,	FingerprintCode				VARCHAR(620)						NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
		,	UserAgent					VARCHAR(1000)						NULL
		,	IP							VARCHAR(50) 						NULL
        ,	IPID						DECIMAL(50,0)						NULL
        ,	Flagged						SMALLINT							NULL
		,	PluginID					BIGINT 								NULL	
		,	URL							VARCHAR(500) 						NULL
        ,	`Action`					VARCHAR(100) 						NULL
		,	ActionResult				VARCHAR(100) 						NULL
		,	InvalidDevice				VARCHAR(1000)						CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		,	TransStatus					BIT(16)								NULL
    );     
		
	INSERT INTO Temp_Transactions(	LoginName, SubscriberName, TransTime, DeviceCode, FingerprintCode, UserAgent, IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus)
	SELECT	rt.LoginName
		,	rt.SubscriberName
		,	rt.TransTime
		,	(CASE WHEN rt.DeviceCode IS NULL THEN NULL ELSE rt.DeviceCode END) AS DeviceCode
		,	(CASE WHEN rt.FingerprintCode IS NULL OR rt.DeviceCode IS NULL	THEN NULL ELSE rt.FingerprintCode END) AS FingerprintCode
		,	LEFT((CASE WHEN rt.UserAgent IS NULL THEN NULL ELSE rt.UserAgent END),1000) AS UserAgent
		,	(CASE WHEN rt.IP IS NULL THEN NULL ELSE rt.IP END) AS IP
		,	(CASE WHEN rt.IPID = 0 THEN NULL ELSE rt.IPID END) AS IPID
		,	(CASE WHEN rt.Flagged = -1 THEN NULL ELSE rt.Flagged END) AS Flagged
		,	(CASE WHEN rt.PluginID = 0 THEN NULL ELSE rt.PluginID END) AS PluginID            
		,	(CASE WHEN rt.URL IS NULL THEN NULL ELSE rt.URL END) AS URL
		,	(CASE WHEN rt.Action IS NULL THEN NULL ELSE rt.Action END) AS Action
		,	(CASE WHEN rt.ActionResult IS NULL THEN NULL ELSE rt.ActionResult END) AS ActionResult
		,	LEFT((CASE WHEN rt.InvalidDevice IS NULL THEN NULL ELSE rt.InvalidDevice END),1000) AS InvalidDevice
		,	TransStatus
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
                            ,	Flagged					SMALLINT		PATH "$.Flagged"
							,	PluginID				BIGINT 			PATH "$.PluginID"
							,	URL						VARCHAR(500) 	PATH "$.URL"
                            ,	Action					VARCHAR(100)	PATH "$.Action"
							,	ActionResult			VARCHAR(100) 	PATH "$.ActionResult"
                            ,	InvalidDevice			TEXT			CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.InvalidDevice"
                            ,	TransStatus				BIT(16)			PATH "$.TransStatus"
				)
		   ) AS  rt; 
	
	INSERT INTO DCS_DataCenter.RawTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, UserAgent, IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, InsertTime)
	SELECT	rt.LoginName
		,	rt.SubscriberName
		,	rt.TransTime
		,	DATE(rt.TransTime) AS CreatedDate
		,	rt.DeviceCode
		,	rt.FingerprintCode
		,	rt.UserAgent
		,	rt.IP
        ,	rt.IPID
        ,	rt.Flagged
		,	rt.PluginID
		,	rt.URL
        ,	rt.Action
		,	rt.ActionResult
        ,	rt.InvalidDevice
        ,	rt.TransStatus
		,	CURRENT_TIMESTAMP(4) as InsertTime
	FROM Temp_Transactions AS rt;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
END$$

DELIMITER ;
