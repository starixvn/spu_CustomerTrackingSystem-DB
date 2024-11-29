/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBTransaction_Insert`(
        IN ip_FromTransID   BIGINT UNSIGNED
    ,   IN ip_ToTransID     BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Transform Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #214026]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBTransaction_Insert(1,200);
    */    
    DECLARE lv_CurrentDate 		TIMESTAMP(4) DEFAULT CURRENT_TIMESTAMP(4);
    
    DECLARE lv_ListMBDeviceCodeMediaDRM 	LONGTEXT;
    DECLARE lv_ListMBDeviceCodeTagging	 	LONGTEXT;
    DECLARE lv_MBAccountJson 				LONGTEXT;
    DECLARE lv_MBDeviceCodeMachineJson 		LONGTEXT;
    DECLARE lv_MBDeviceModelJson 			LONGTEXT;
    DECLARE lv_MBUserSettingJson 			LONGTEXT;

    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;
	CREATE TEMPORARY TABLE IF NOT EXISTS Temp_RawTransaction (
			ID 							BIGINT UNSIGNED PRIMARY KEY
		,	LoginName 					VARCHAR(100)
		,	SubscriberID 				INT
		,	SubscriberName 				VARCHAR(50)
		,	TransTime 					DATETIME(4)
		,	IP 							VARCHAR(50)
		,	IPID 						DECIMAL(500)
		,	Action 						VARCHAR(100)
		,	ActionResult 				VARCHAR(100)
		,	Flagged 					SMALLINT
		,	MBDeviceCodeMediaDRM 		VARCHAR(32)
		,	MBDeviceCodeMachine 		VARCHAR(32)
		,	MBDeviceCodeMachineOSType 	SMALLINT
		,	MBDeviceCodeTagging 		VARCHAR(32)
		,	IsEmulator 					TINYINT
		,	ModelName 					VARCHAR(32)
		,	Manufacturer 				VARCHAR(32)
		,	Brand 						VARCHAR(32)
		,	SDKVersion 					VARCHAR(32)
		,	OSName 						VARCHAR(32)
		,	CountryName					VARCHAR(32)
		,	Timezone 					VARCHAR(32)
		,	Language 					VARCHAR(32)
	);
        
	INSERT INTO Temp_RawTransaction(ID, LoginName, SubscriberName, TransTime, IP, IPID, Action, ActionResult, Flagged, MBDeviceCodeMediaDRM, MBDeviceCodeMachine, MBDeviceCodeMachineOSType, MBDeviceCodeTagging, IsEmulator, ModelName, Manufacturer, Brand, SDKVersion, OSName, CountryName, Timezone, Language)
    SELECT 	ID
		,	LoginName
        ,	SubscriberName
        ,	TransTime
        ,	IP
        ,	IPID
        ,	Action
        ,	ActionResult
        ,	Flagged
        ,	MBDeviceCodeMediaDRM
        ,	MBDeviceCodeMachine
        ,	MBDeviceCodeMachineOSType
        ,	MBDeviceCodeTagging
        ,	IsEmulator
        ,	ModelName
        ,	Manufacturer
        ,	Brand
        ,	SDKVersion
        ,	OSName
        ,	CountryName
        ,	Timezone
        ,	Language
	FROM DCS_DataCenter.RawTransaction
    WHERE ID BETWEEN ip_FromTransID AND ip_ToTransID;

	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN CTS_Admin.Subscriber AS sub ON tmp.SubscriberName = sub.SubscriberName
	SET tmp.SubscriberID = sub.SubscriberID;
    
    
    /* === Insert new MBAccount === */ 
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				SubscriberID
			,	LoginName
			,	TransTime
		FROM Temp_RawTransaction
		WHERE SubscriberID IS NOT NULL
			AND LoginName IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'SubscriberID'	, SubscriberID
				,	'LoginName'		, LoginName
				,	'TransTime'		, TransTime
			)
		) AS json_data
	INTO lv_MBAccountJson
	FROM cte_DistinctData;
    
    SET lv_MBAccountJson = IFNULL(lv_MBAccountJson,'[{}]');
	CALL DCS_DC_Transform_MBAccount_Insert(lv_MBAccountJson);
    
    
    /* === Insert new MBDeviceCodeMachine === */ -- [{"Code":"Code4","MachineOSType":"2"},{"Code":"Code2"},{"Code":"Code3","MachineOSType":""}]
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				MBDeviceCodeMachine
			,	MBDeviceCodeMachineOSType
		FROM Temp_RawTransaction
		WHERE SubscriberID IS NOT NULL
			AND LoginName IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'Code'			, MBDeviceCodeMachine
				,	'MachineOSType'	, MBDeviceCodeMachineOSType
			)
		) AS json_data
	INTO lv_MBDeviceCodeMachineJson
	FROM cte_DistinctData;
    
    IF lv_MBDeviceCodeMachineJson IS NOT NULL THEN
		CALL DCS_DC_Transform_MBDeviceCodeMachine_Insert(lv_MBDeviceCodeMachineJson);
	END IF;
    
    
    /* === Insert new MBUserSetting === */ -- {"CountryName":"CountryName1","TimeZone":"TimeZone1","LanguageName":"LanguageName1"}
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				CountryName
			,	TimeZone
			,	Brand
		FROM Temp_RawTransaction
		WHERE CountryName IS NOT NULL
			OR TimeZone IS NOT NULL
			OR LanguageName IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'CountryName'		, CountryName
				,	'TimeZone'			, TimeZone
				,	'LanguageName'		, LanguageName
			)
		) AS json_data
	INTO lv_MBUserSettingJson
	FROM cte_DistinctData;
    
    IF lv_MBUserSettingJson IS NOT NULL THEN
		CALL DCS_DC_Transform_MBUserSetting_Insert(lv_MBUserSettingJson);
	END IF;
    
    /* === Insert new MBOS === */ -- {"OSName":"OSName1","Version":"1.1.3"}
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				OSName
			,	SDKVersion
		FROM Temp_RawTransaction
		WHERE OSName IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'OSName'		, OSName
				,	'Version'		, SDKVersion
			)
		) AS json_data
	INTO lv_MBOSJson
	FROM cte_DistinctData;
    
    IF lv_MBOSJson IS NOT NULL THEN
		CALL DCS_DC_Transform_MBOS_Insert(lv_MBOSJson);
	END IF;
    

    /* === Insert new MBDeviceCodeMediaDRM === */
	SELECT GROUP_CONCAT(DISTINCT MBDeviceCodeMediaDRM)
	INTO lv_ListMBDeviceCodeMediaDRM
	FROM Temp_RawTransaction
	WHERE MBDeviceCodeMediaDRM IS NOT NULL;
    
    IF (lv_ListMBDeviceCodeMediaDRM IS NOT NULL AND lv_ListMBDeviceCodeMediaDRM <> '') THEN
		CALL DCS_DC_Transform_MBDeviceCodeMediaDRM_Insert(lv_ListMBDeviceCodeMediaDRM);
	END IF;
    

    /* === Insert new MBDeviceCodeTagging === */
	SELECT GROUP_CONCAT(DISTINCT MBDeviceCodeTagging)
	INTO lv_ListMBDeviceCodeTagging
	FROM Temp_RawTransaction
	WHERE MBDeviceCodeTagging IS NOT NULL;
    
    IF (lv_ListMBDeviceCodeTagging IS NOT NULL AND lv_ListMBDeviceCodeTagging <> '') THEN
		CALL DCS_DC_Transform_MBDeviceCodeTagging_Insert(lv_ListMBDeviceCodeTagging);
	END IF;
    
    
	/* ======= UPDATE ID ========= */
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBAccount AS acc ON acc.SubscriberID = tmp.SubscriberID AND acc.LoginName = tmp.LoginName
	SET tmp.MBAccountID = acc.ID;
    
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeMediaDRM AS drm ON drm.Code = tmp.MBDeviceCodeMediaDRM
	SET tmp.MBDeviceCodeMediaDRMID = drm.ID;
    
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeMachine AS mc ON mc.Code = tmp.MBDeviceCodeMachine AND mc.MachineOSType = tmp.MBDeviceCodeMachineOSType
	SET tmp.MBDeviceCodeMachineID = mc.ID;
    
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeTagging AS tg ON tg.Code = tmp.MBDeviceCodeTagging
	SET tmp.MBDeviceCodeTaggingID = tg.ID;
    
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceModel AS dm ON dm.ModelName = tmp.ModelName 
													AND dm.Manufacturer = tmp.Manufacturer
													AND dm.Brand = tmp.Brand
	SET tmp.MBDeviceModelID = dm.ID;
    
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBUserSetting AS us ON us.CountryName = tmp.CountryName 
													AND us.TimeZone = tmp.TimeZone
													AND us.LanguageName = tmp.LanguageName
	SET tmp.MBUserSettingID = us.ID;
    
	UPDATE Temp_RawTransaction AS tmp
		INNER JOIN DCS_DataCenter.MBOS AS os ON os.OSName = tmp.OSName 
											AND os.Version = tmp.SDKVersion
	SET tmp.MBOSID = os.ID;
    
    -- MBTransaction
END$$
DELIMITER ;