/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_GetTransactionByLoginName`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_GetTransactionByLoginName`(
		IN	ip_SubscriberID		INT
	,	IN  ip_LoginName		VARCHAR(50)
	,	IN 	ip_BatchSize 		INT
	,	IN	ip_FromDate			DATE
	,	IN	ip_ToDate 			DATE
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20250725@Aida.Tran
	Task : Support return info for verify test case
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20250725@Aida.Tran: Get Data [Redmine ID: 233595]
		
	Param's Explanation (filtered by):

	Example:
		CALL DCS_DataCenter.DCS_DC_GetTransactionByLoginName(2, 'test1', 10, '2025-06-05', '2025-06-05');
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
	
	CREATE TEMPORARY TABLE Temp_Transaction(
			TransID 			BIGINT UNSIGNED PRIMARY KEY
		,	TransTime 			TIMESTAMP(4)
		,	AccountID 			BIGINT UNSIGNED
		,	LoginName 			VARCHAR(100)
		,	SubscriberID 		INT
		,	CreatedDate 		DATETIME
		,	Flagged 			SMALLINT
		,	UserAgentKey 		VARCHAR(32)
		,	IP 					VARCHAR(50)
		,	IPID 				DECIMAL(50,0)
		,	URLID 				BIGINT UNSIGNED
		,	ActionResultID 		BIGINT
		,	TransStatus 		BIT(16)
		,	InsertTime 			TIMESTAMP(4)
		,	BotDetectionValue 	BIT(32)
		,	BotComponentID 		BIGINT UNSIGNED
		,	FakeIP 				VARCHAR(100)
		,	DeviceID 			BIGINT UNSIGNED
		,	DeviceCodeID 		BIGINT UNSIGNED
		,	FirstDeviceCode 	VARCHAR(64)
		,	DeviceStatus 		TINYINT
		,	DeviceFingerprintID BIGINT UNSIGNED
		,	FP_DeviceMappingID	BIGINT UNSIGNED
		,	FingerprintCode 	VARCHAR(620)
		,	DeviceCode 			VARCHAR(32)
		,	UserAgent 			VARCHAR(1000)
		,	OSName 				VARCHAR(100)
		,	BrowserName 		VARCHAR(100)
		,	DeviceType 			VARCHAR(20)
		,	Attribute 			JSON
	);
	
	INSERT IGNORE INTO Temp_Transaction(TransID, TransTime, AccountID, LoginName, SubscriberID, CreatedDate, Flagged, UserAgentKey, IP, IPID, URLID, ActionResultID, TransStatus, InsertTime, BotDetectionValue, BotComponentID, FakeIP, DeviceID, DeviceCodeID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID, FP_DeviceMappingID)
	SELECT 	TransID
		,	TransTime
		,	AccountID
		,	LoginName
		,	SubscriberID
		,	CreatedDate
		,	Flagged
		,	UserAgentKey
		,	IP
		,	IPID
		,	URLID
		,	ActionResultID
		,	TransStatus
		,	InsertTime
		,	BotDetectionValue
		,	BotComponentID
		,	FakeIP
		,	DeviceID
		,	DeviceCodeID
		,	FirstDeviceCode
		,	DeviceStatus
		,	DeviceFingerprintID
		,	FP_DeviceMappingID
	FROM DCS_DataCenter.Transaction07
	WHERE SubscriberID = ip_SubscriberID 
		AND TransTime >= ip_FromDate
		AND TransTime < DATE_ADD(ip_ToDate, INTERVAL 1 DAY)
		AND LoginName = ip_LoginName
	ORDER BY TransID DESC
	LIMIT ip_BatchSize;
	
	UPDATE Temp_Transaction AS trans
		INNER JOIN DCS_DataCenter.DeviceFingerprint AS df ON df.DeviceFingerprintID = trans.DeviceFingerprintID AND df.DeviceID = trans.DeviceID
	SET trans.FingerprintCode = df.FingerprintCode;
    
	UPDATE Temp_Transaction AS trans
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.ID = trans.FP_DeviceMappingID
		INNER JOIN DCS_DataCenter.FP_FingerPrint AS fp ON fp.ID = dm.FP_FingerPrintID
	SET trans.Attribute = fp.Attribute;
	
	UPDATE Temp_Transaction AS trans
		INNER JOIN DCS_DataCenter.DeviceCode AS dc ON dc.DeviceCodeID = trans.DeviceCodeID
	SET trans.DeviceCode = dc.DeviceCode;
	
	UPDATE Temp_Transaction AS trans
		INNER JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
		LEFT JOIN DCS_DataCenter.OS AS os ON os.OSID = ua.OSID
		LEFT JOIN DCS_DataCenter.Browser AS br ON br.BrowserID = ua.BrowserID
		LEFT JOIN DCS_DataCenter.DeviceType AS dt ON dt.DeviceTypeID = ua.DeviceTypeID
	SET trans.UserAgent = ua.UserAgent,
		trans.OSName = os.OSName,
		trans.BrowserName = br.BrowserName,
		trans.DeviceType = dt.DeviceTypeName;
	
	/* === Return values === */
	SELECT 	trans.TransID
		,	trans.TransTime
		,	trans.AccountID
		,	trans.LoginName
		,	trans.SubscriberID
		,	sub.SubscriberName
		,	trans.CreatedDate
		,	trans.Flagged
		,	sl.ItemName AS RobotTracking
		,	trans.UserAgentKey
		,	trans.UserAgent
		,	trans.OSName
		,	NULL AS OSVersion
		,	trans.BrowserName
		,	NULL AS BrowserVersion
		,	trans.DeviceType
		,	trans.IP
		,	CAST(trans.IPID AS CHAR) AS IPID
		,	trans.URLID
		,	url.URLDetails
		,	trans.ActionResultID
		,	ar.Action
		,	ar.ActionResult
		,	trans.TransStatus
		,	trans.InsertTime
		,	trans.BotDetectionValue
		,	trans.BotComponentID
		,	trans.FakeIP
		,	trans.DeviceID
		,	trans.DeviceCode
		,	trans.FirstDeviceCode
		,	trans.DeviceStatus
		,	trans.DeviceFingerprintID
		,	trans.FP_DeviceMappingID
		,	trans.FingerprintCode
		,	trans.Attribute
	FROM Temp_Transaction AS trans
		LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.Status = 1 AND sl.ItemID = trans.Flagged
		LEFT JOIN DCS_DataCenter.URL AS url ON url.URLID = trans.URLID
		LEFT JOIN DCS_DataCenter.ActionResult AS ar ON ar.ActionResultID = trans.ActionResultID
	ORDER BY trans.TransID DESC;
		
END$$
DELIMITER ;