/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_SAI_GetTransactionInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_SAI_GetTransactionInfo`(
		IN ip_LastTransID BIGINT UNSIGNED
	,	IN ip_BatchSize INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20241122@Jonathan.Doan
	Task : Support return info for SAI team
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20241122@Jonathan.Doan: Get Data [Redmine ID: 214111]
		
	Param's Explanation (filtered by):

	Example:
		CALL DCS_DataCenter.DCS_DC_SAI_GetTransactionInfo(0, 10);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    
    CREATE TEMPORARY TABLE Temp_Transaction(
			TransID BIGINT UNSIGNED PRIMARY KEY
        ,	TransTime TIMESTAMP(4)
        ,	AccountID BIGINT UNSIGNED
        ,	LoginName VARCHAR(100)
        ,	SubscriberID INT
        ,	CreatedDate DATETIME
        ,	Flagged SMALLINT
        ,	UserAgentKey VARCHAR(32)
        ,	IP VARCHAR(50)
        ,	IPID DECIMAL(50,0)
        ,	URLID BIGINT UNSIGNED
        ,	ActionResultID BIGINT
        ,	TransStatus BIT(16)
        ,	InsertTime TIMESTAMP(4)
        ,	BotDetectionValue BIT(32)
        ,	BotComponentID BIGINT UNSIGNED
        ,	FakeIP VARCHAR(100)
        ,	DeviceID BIGINT UNSIGNED
        ,	DeviceCodeID BIGINT UNSIGNED
        ,	FirstDeviceCode VARCHAR(64)
        ,	DeviceStatus TINYINT
        ,	DeviceFingerprintID BIGINT UNSIGNED
        ,	FP_UserAgentID BIGINT UNSIGNED
    );
    
    INSERT IGNORE INTO Temp_Transaction(TransID, TransTime, AccountID, LoginName, SubscriberID, CreatedDate, Flagged, UserAgentKey, IP, IPID, URLID, ActionResultID, TransStatus, InsertTime, BotDetectionValue, BotComponentID, FakeIP, DeviceID, DeviceCodeID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID, FP_UserAgentID)
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
		,	FP_UserAgentID
    FROM DCS_DataCenter.Transaction07
    WHERE TransID > ip_LastTransID
    ORDER BY TransID ASC
    LIMIT ip_BatchSize;
    
	SELECT 	trans.TransID
		,	cus.CustID
		,	trans.TransTime
		,	trans.AccountID
		,	trans.loginName
		,	trans.SubscriberID
		,	sub.SubscriberName
		,	trans.CreatedDate
		,	trans.Flagged
		,	sl.ItemName AS RobotTracking
		,	trans.UserAgentKey
		,	ua.UserAgent
		,	trans.IP
		,	trans.IPID
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
		,	dc.DeviceCode
		,	trans.FirstDeviceCode
		,	trans.DeviceStatus
		,	trans.DeviceFingerprintID
		,	df.FingerprintCode
		,	fos.OSName
		,	fos.OSVersion
		,	fbr.BrowserName
		,	fbr.BrowserVersion
	FROM Temp_Transaction AS trans
		LEFT JOIN CTS_DataCenter.CustDCSAccount AS cda ON cda.AccountID = trans.AccountID
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = cda.CTSCustID
		LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = trans.SubscriberID
		LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.ItemID = trans.Flagged
		LEFT JOIN DCS_DataCenter.URL AS url ON url.URLID = trans.URLID
		LEFT JOIN DCS_DataCenter.UserAgent AS ua ON ua.UserAgentKey = trans.UserAgentKey
		LEFT JOIN DCS_DataCenter.ActionResult AS ar ON ar.ActionResultID = trans.ActionResultID
		LEFT JOIN DCS_DataCenter.DeviceCode AS dc ON dc.DeviceCodeID = trans.DeviceCodeID
		LEFT JOIN DCS_DataCenter.DeviceFingerprint AS df ON df.DeviceFingerprintID = trans.DeviceFingerprintID
		LEFT JOIN DCS_DataCenter.FP_UserAgent AS fua ON fua.ID = trans.FP_UserAgentID
		LEFT JOIN DCS_DataCenter.FP_OS AS fos ON fos.ID = fua.OSID
		LEFT JOIN DCS_DataCenter.FP_Browser AS fbr ON fbr.ID = fua.BrowserID;
END$$
DELIMITER ;