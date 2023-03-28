/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Transform`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Abnormal_Transasction_Transform`(
	IN ip_Size	INT
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20230321@Jonathan.Doan
	Task : Support return new device login for Alpha
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20230321@Jonathan.Doan: Transform data from Transaction07 to AbnormalTransasction [Redmine ID: 185185]
		
	Param's Explanation (filtered by):

	Example:
		- CALL DCS_DataCenter.DCS_DC_Abnormal_Transasction_Transform(10);
	*/
    
    DECLARE lv_DeviceStatusNewDevice INT DEFAULT 1; # New Device
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    DECLARE lv_SystemSettingVGroup VARCHAR(128) DEFAULT 'DCS_AbnormalTransaction_Transform';
    DECLARE lv_SystemSettingVName VARCHAR(128) DEFAULT 'MaxTransId';
    DECLARE lv_SystemSettingVValue BIGINT UNSIGNED;
    
    SET lv_SystemSettingVValue 	= IFNULL((SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE VGroup=lv_SystemSettingVGroup AND VName=lv_SystemSettingVName), 0);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    
	#======GET DATA FROM TRANSACTION07===========================
	CREATE TEMPORARY TABLE Temp_Transaction(
		 TransID				BIGINT	UNSIGNED PRIMARY KEY
		, AccountID				BIGINT	UNSIGNED
		, LoginName				VARCHAR(100)
		, TransTime				TIMESTAMP(4)
        , UserAgentKey			VARCHAR(32)
        , IP					VARCHAR(50)
	);
    
    INSERT INTO Temp_Transaction(
			TransID
		,	AccountID
		,	LoginName
		,	TransTime
		,	UserAgentKey
		,	IP
	)
	SELECT 	trans.TransID
		,	trans.AccountID
		,	trans.LoginName
		,	trans.TransTime
		,	trans.UserAgentKey
		,	trans.IP
	FROM DCS_DataCenter.Transaction07 AS trans
	WHERE trans.TransID > lv_SystemSettingVValue
		AND trans.DeviceStatus = lv_DeviceStatusNewDevice
		AND trans.SubscriberID IN (2,168,271,2339,13659)
	LIMIT ip_Size;
    
    /*****Add Into Abnormal Transaction****************************************************/
	INSERT IGNORE INTO DCS_DataCenter.AbnormalTransasction(
			TransID
		, 	AccountID
		, 	LoginName
		,	TransTime
		,	UserAgentKey
		,	IP
		,	CreatedDate
	)
	SELECT 	tmp.TransID
		,	tmp.AccountID
		,	tmp.LoginName
		,	tmp.TransTime
		,	tmp.UserAgentKey
		,	tmp.IP
		,	lv_CurrentDatetime AS CreatedDate
	FROM Temp_Transaction AS tmp;
    
    /*****UPDATE MaxTransID in SystemSetting****************************************************/
    SELECT MAX(TransID)
    INTO lv_SystemSettingVValue
	FROM Temp_Transaction;
    
    UPDATE DCS_DataCenter.SystemSetting AS ss
	SET 	ss.VValue = CONCAT('', lv_SystemSettingVValue)
	   ,	ss.UpdatedTime = lv_CurrentDatetime
    WHERE VGroup=lv_SystemSettingVGroup 
		AND VName=lv_SystemSettingVName;
END$$
DELIMITER ;
