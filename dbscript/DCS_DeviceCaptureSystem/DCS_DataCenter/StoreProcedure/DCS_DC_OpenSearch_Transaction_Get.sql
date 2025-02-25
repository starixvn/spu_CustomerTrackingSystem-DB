/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_OpenSearch_Transaction_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_OpenSearch_Transaction_Get`(
		IN ip_BatchSize INT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20250213@Lando.Vu
	Task : Optimize and Enhance OpenSearch
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20250213@Lando.Vu: Created [Redmine ID: 217768]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataCenter.DCS_DC_OpenSearch_Transaction_Get(100);
	*/
    DECLARE CONST_OPENSEARCH_LISTSUBID 				INT 		DEFAULT 100;
	DECLARE CONST_OPENSEARCH_TRANSACTION07_TRANSID 	INT 		DEFAULT 101;
	DECLARE CONST_OPENSEARCH_CUTOFF_MINUTES 	INT 		DEFAULT 102;
    
	DECLARE lv_MaxTransID  			BIGINT UNSIGNED;
	DECLARE lv_ListSubID			VARCHAR(500);
	DECLARE lv_CurrentDatetime 		DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_CutoffMinute			INT;
	DECLARE lv_MaxInsertTime 		DATETIME;
    
	SET lv_MaxTransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_OPENSEARCH_TRANSACTION07_TRANSID);
    SET lv_ListSubID = (SELECT VValue FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_OPENSEARCH_LISTSUBID);
    SET lv_CutoffMinute = (SELECT VValue FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_OPENSEARCH_CUTOFF_MINUTES);
    SET lv_MaxInsertTime = (SELECT DATE_SUB(NOW(), INTERVAL lv_CutoffMinute MINUTE));
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans07;
	DROP TEMPORARY TABLE IF EXISTS Temp_SubscriberID;
	DROP TEMPORARY TABLE IF EXISTS Temp_BotDetection;
    
	CREATE TEMPORARY TABLE Temp_Trans07(
			TransID						BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	TransTime 					TIMESTAMP(4)
		,	AccountID 					BIGINT UNSIGNED
        ,	LoginName 					VARCHAR(100)
        ,	SubscriberID 				INT
		,	URLID 						BIGINT UNSIGNED
		,	DeviceCodeID 				BIGINT UNSIGNED
		, 	DeviceID					BIGINT UNSIGNED
        ,	FirstDeviceCode 			VARCHAR(64)
        ,	DeviceStatus 				TINYINT
        ,	DeviceFingerprintID 		BIGINT UNSIGNED
        ,	UserAgentKey 				VARCHAR(32)
        ,	IP 							VARCHAR(50)
        ,	IPID 						DECIMAL(50,0)
        , 	ActionResultID 				BIGINT
        ,	Flagged 					SMALLINT
        ,	PluginID 					BIGINT
        ,	TransStatus 				BIT(16)
        ,	CreatedDate 				DATETIME
        , 	InsertTime 					TIMESTAMP(4)
        ,	RawTransID 					BIGINT UNSIGNED
        , 	BotDetectionValue 			BIT(32)
        ,	FakeIP 						VARCHAR(100)
        , 	IsIncognitoMode 			TINYINT(1)
        ,	FingerprintCode 			VARCHAR(620)
        ,	DeviceCode					VARCHAR(32)
        ,	UserAgent					VARCHAR(1000)
        ,	BotDetection				LONGTEXT
	);

	CREATE TEMPORARY TABLE Temp_SubscriberID(
			SubscriberID				INT NOT NULL AUTO_INCREMENT PRIMARY KEY
	);
    
    CREATE TEMPORARY TABLE Temp_BotDetection(
			TransID						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
		,	BotDetection				LONGTEXT
	);
    
    SET @sql = CONCAT("INSERT IGNORE INTO Temp_SubscriberID (SubscriberID) VALUES ('", REPLACE(lv_ListSubID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	INSERT IGNORE INTO Temp_Trans07(TransID, TransTime, AccountID, LoginName, SubscriberID, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime, RawTransID, BotDetectionValue, FakeIP, IsIncognitoMode)
    SELECT 	    TransID
			,   TransTime
            , 	AccountID
            , 	LoginName
            , 	SubscriberID
			,   URLID
			,   DeviceCodeID
			,   DeviceID
			,   FirstDeviceCode
			,   DeviceStatus
			,   DeviceFingerprintID
			,   UserAgentKey
			,   IP
			,   IPID
			,   ActionResultID
			,   Flagged
			,   PluginID
			,   TransStatus
			,   CreatedDate
			,   InsertTime
			,   RawTransID
			,   BotDetectionValue
			,   FakeIP
			,   IsIncognitoMode
    FROM DCS_DataCenter.Transaction07
    WHERE TransID > lv_MaxTransID
		AND InsertTime < lv_MaxInsertTime
    ORDER BY TransID ASC
    LIMIT ip_BatchSize;
    
    ALTER TABLE Temp_Trans07
    ADD KEY IX_Temp_Trans07_SubscriberID (SubscriberID);
    
	DELETE trans
 	FROM Temp_Trans07 trans
		LEFT JOIN Temp_SubscriberID subs ON trans.SubscriberID = subs.SubscriberID
 	WHERE subs.SubscriberID IS NULL;
	
    INSERT IGNORE INTO Temp_BotDetection(TransID, BotDetection)
    SELECT trans.TransID AS TransID
		,	GROUP_CONCAT(bd.Name ORDER BY bd.Value) AS BotDetection
	FROM Temp_Trans07 trans
		INNER JOIN DCS_DataCenter.BotDetection bd ON (trans.BotDetectionValue & bd.Value) = bd.Value
	GROUP BY trans.TransID;
    
    ALTER TABLE Temp_BotDetection
    ADD KEY IX_Temp_BotDetection_TransID (TransID);
    
	UPDATE Temp_Trans07 AS trans
		INNER JOIN DCS_DataCenter.DeviceFingerprint AS df ON df.DeviceFingerprintID = trans.DeviceFingerprintID AND df.DeviceID = trans.DeviceID
	SET trans.FingerprintCode = df.FingerprintCode;
    
    UPDATE Temp_Trans07 AS trans
		INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
	SET trans.UserAgent = ua.UserAgent;
    
	UPDATE Temp_Trans07 AS trans
		INNER JOIN DCS_DataCenter.DeviceCode AS dc ON dc.DeviceCodeID = trans.DeviceCodeID
	SET trans.DeviceCode = dc.DeviceCode;
    
    UPDATE Temp_Trans07 AS trans
		INNER JOIN Temp_BotDetection AS bd ON bd.TransID = trans.TransID
	SET trans.BotDetection = bd.BotDetection;
    
	SELECT 	    trans.TransID
			,   trans.TransTime
            ,	trans.AccountID
			,	trans.LoginName
			,	sub.SubscriberName
			,	url.URLDetails 				AS 	URL
			,   trans.DeviceID
			,	trans.DeviceCode
			,   trans.FirstDeviceCode
			,   trans.DeviceStatus
			,	trans.FingerprintCode
            ,	trans.UserAgent
			,   trans.IP
			,   trans.IPID
			,	ar.Action
			,	sl.ItemName 				AS Flagged
			,   trans.PluginID
			,   trans.TransStatus
			,   trans.CreatedDate
			,   trans.InsertTime
			,   trans.RawTransID
            , 	trans.BotDetection
			,   trans.FakeIP
			,   trans.IsIncognitoMode
	FROM Temp_Trans07 trans
		LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.Status = 1 AND sl.ItemID = trans.Flagged
		LEFT JOIN DCS_DataCenter.URL AS url ON url.URLID = trans.URLID
		LEFT JOIN DCS_DataCenter.ActionResult AS ar ON ar.ActionResultID = trans.ActionResultID;
END$$
DELIMITER ;
