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
			- 20230426@Jonathan.Doan: Add BotD [Redmine ID: #186644]
			- 20230807@Terry.Nguyen: Add Fake IP [Redmine ID: #191829]
			- 20231108@Jonathan.Doan: Integrate FPSjs [Redmine ID: #196570]
            - 20240313@Teddy.le : Add JsChallengeID  [Redmine ID: #196667]
			- 20240621@Jonathan.Doan: Change data flow v6 [Redmine ID: #206403]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DataCenter.DCS_DC_Transform_RawTrans_Insert('[{"LoginName":"testz","SubscriberName":"Alpha","TransTime":"2024-06-26T09:30:22.1678","CreatedDate":"0001-01-01T00:00:00","DeviceCode":"464d165f74c441ee924c2c7adedba28f","FingerprintCode":"75f5834ffbb965923fa1b4e867c47beed230e081;58e4ec9612dd39a0cd99a0d7e1fe9ce4","FingerprintMoreInfo":"rGMAUmSIRW5iU9EJCzUkbsp/BtnFdh0z0sHpjkVJDY8=","UserAgent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36","IP":"::1","FakeIP":"","IPId":1,"IsIPV6":true,"PluginID":0,"URL":"http://localhost:60207","Action":"Login","ActionResult":"Successfull","InvalidDevice":null,"TransStatus":0,"FPSTransId":0,"FlaggedCode":"Human","BotDetection":"","BotComponent":"","FPTagging":"4132559cff0869c7e6958530cb914fa1","FPFingerPrintCode":"4132559cff0869c7e6958530cb914fa2","FPFingerPrintExtraCode":"a811b6c2f6a5d39d8e6cc9e5a807d025","FPFingerPrintOldCode":"7a8f56652855ae80aae2e34dc5dc4e81","FPUserAgentCode":"a811b6c2f6a5d39d8e6cc9e5a807d025","ChallengeCode":"dd61a2aab50f41738effdeacc3c927ff","IsIncognitoMode":false}]');

	*/
	
    DECLARE lv_FlaggedHuman	INT UNSIGNED DEFAULT 1;
    DECLARE lv_InsertionTime TIMESTAMP(4) DEFAULT CURRENT_TIMESTAMP(4);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_BotDetection;
	DROP TEMPORARY TABLE IF EXISTS Temp_BotComponent;
    
	CREATE TEMPORARY TABLE Temp_Transaction(
			ID							INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	LoginName					VARCHAR(100) 				NOT NULL	
		,	SubscriberName				VARCHAR(50) 				NOT NULL
		,	TransTime					TIMESTAMP(4)	 			NOT NULL
		,	DeviceCode					VARCHAR(32) 				NULL		COMMENT 'Device Inject Code: 32 characters is auto generated'
		,	FingerprintCode				VARCHAR(620)				NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
		,	UserAgent					VARCHAR(1000)				NULL
		,	IP							VARCHAR(50) 				NULL
        ,	IPID						DECIMAL(50,0)				NULL
		,	PluginID					BIGINT 						NULL	
		,	URL							VARCHAR(500) 				NULL
        ,	`Action`					VARCHAR(100) 				NULL
		,	ActionResult				VARCHAR(100) 				NULL
		,	InvalidDevice				VARCHAR(1000)				CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		,	TransStatus					BIT(16)						NULL
        ,	FlaggedCode					VARCHAR(100)				NULL
        ,	BotDetection				LONGTEXT					NULL
        ,	BotDetectionValue			BIT(32)						NULL		DEFAULT 0
        ,	BotComponentID				BIGINT UNSIGNED				NULL
        ,	BotComponent				LONGTEXT					NULL
        ,	BotComponentCode			VARCHAR(100)				NULL
		,	FakeIP						VARCHAR(100) 				NULL
        ,	FP_Tagging					VARCHAR(32)					NULL
        ,	FP_FingerPrintCode			VARCHAR(32)					NULL
        ,	FP_FingerPrintExtraCode		VARCHAR(32)					NULL
        ,	FP_FingerPrintOldCode		VARCHAR(32)					NULL
        ,	FP_UserAgentCode			VARCHAR(32)					NULL
        ,	ChallengeCode				VARCHAR(50)					NULL
        ,	IsIncognitoMode				BOOLEAN						NULL
    );

	CREATE TEMPORARY TABLE Temp_BotDetection(
			ID							INT UNSIGNED PRIMARY KEY
        ,	BotDetectionValue			BIT(32) NULL DEFAULT 0
    );

	CREATE TEMPORARY TABLE Temp_BotComponent(
			Code						VARCHAR(100) NOT NULL		PRIMARY KEY
        ,	Component					LONGTEXT 	 NOT NULL
        ,	FlaggedCode					VARCHAR(100) NOT NULL
        
		,	IsNewRecord					TINYINT		 				DEFAULT 1
    );
		
	INSERT INTO Temp_Transaction(LoginName, SubscriberName, TransTime, DeviceCode, FingerprintCode, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FlaggedCode, BotDetection, BotComponent, BotComponentCode, FakeIP, FP_Tagging, FP_FingerPrintCode, FP_FingerPrintExtraCode, FP_FingerPrintOldCode, FP_UserAgentCode, ChallengeCode, IsIncognitoMode)
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
		,	rt.FakeIP
		,	rt.FP_Tagging
		,	rt.FP_FingerPrintCode
		,	rt.FP_FingerPrintExtraCode
		,	rt.FP_FingerPrintOldCode
		,	rt.FP_UserAgentCode
		,	rt.ChallengeCode
		,	rt.IsIncognitoMode
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
                            ,	FakeIP					VARCHAR(100)	PATH "$.FakeIP"
                            ,	FP_Tagging				VARCHAR(32)		PATH "$.FPTagging"
                            ,	FP_FingerPrintCode		VARCHAR(32)		PATH "$.FPFingerPrintCode"
                            ,	FP_FingerPrintExtraCode	VARCHAR(32)		PATH "$.FPFingerPrintExtraCode"
                            ,	FP_FingerPrintOldCode	VARCHAR(32)		PATH "$.FPFingerPrintOldCode"
                            ,	FP_UserAgentCode		VARCHAR(32)		PATH "$.FPUserAgentCode"
                            ,	ChallengeCode			VARCHAR(50)		PATH "$.ChallengeCode"
                            ,	IsIncognitoMode			BOOLEAN			PATH "$.IsIncognitoMode"
				)
		   ) AS  rt; 
           
    /******* Add index ********************/
	ALTER TABLE Temp_Transaction
	ADD INDEX IX_Temp_Transaction_BotComponentCode (BotComponentCode);
    
    /******* BotDetection ********************/
	INSERT INTO Temp_BotDetection(ID, BotDetectionValue)
    SELECT 	tmp.ID
		, 	SUM(bd.Value) as Value
	FROM Temp_Transaction AS tmp
		INNER JOIN DCS_DataCenter.BotDetection bd ON FIND_IN_SET(bd.Name, tmp.BotDetection)
	GROUP BY tmp.ID;
    
	UPDATE Temp_Transaction AS tmp
		INNER JOIN Temp_BotDetection tmpBD ON tmpBD.ID = tmp.ID
	SET tmp.BotDetectionValue = tmpBD.BotDetectionValue;
    
    /******* BotComponent ********************/
    INSERT IGNORE INTO Temp_BotComponent(Code, Component, FlaggedCode)
	SELECT 	BotComponentCode AS Code
		,	BotComponent AS Component
		,	FlaggedCode
	FROM Temp_Transaction;
    
    UPDATE Temp_BotComponent AS tmp
		INNER JOIN DCS_DataCenter.BotComponent AS bc ON bc.Code = tmp.Code
    SET tmp.IsNewRecord = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.BotComponent(Code, Component, IsHuman, CreatedDate, ModifiedDate)
    SELECT 	Code
		,	Component
		,	CASE WHEN FlaggedCode = 'Human' THEN 1 ELSE 0 END AS IsHuman
		,	lv_InsertionTime AS CreatedDate
		,	DATE(lv_InsertionTime) AS ModifiedDate
    FROM Temp_BotComponent AS tmp
    WHERE IsNewRecord = 1;
    
    UPDATE Temp_Transaction AS tmp
		INNER JOIN DCS_DataCenter.BotComponent AS bds ON bds.Code = tmp.BotComponentCode
	SET tmp.BotComponentID = bds.ID;
    
    /*******RawTransaction********************/
	INSERT INTO DCS_DataCenter.RawTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, UserAgent, IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, InsertTime, BotDetectionValue, BotComponentID, FakeIP, FP_Tagging, FP_FingerPrintCode, FP_FingerPrintExtraCode, FP_FingerPrintOldCode, FP_UserAgentCode, ChallengeCode, IsIncognitoMode)
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
		,	rt.FakeIP
        ,   rt.FP_Tagging
        ,   rt.FP_FingerPrintCode
        ,   rt.FP_FingerPrintExtraCode
        ,   rt.FP_FingerPrintOldCode
        ,   rt.FP_UserAgentCode
        ,   rt.ChallengeCode
        ,   rt.IsIncognitoMode
	FROM Temp_Transaction AS rt
		LEFT JOIN DCS_DataCenter.StaticList AS sl 	ON sl.ListID = 1 /*Flagged*/   
													AND sl.ItemCode = rt.FlaggedCode;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
END$$

DELIMITER ;
