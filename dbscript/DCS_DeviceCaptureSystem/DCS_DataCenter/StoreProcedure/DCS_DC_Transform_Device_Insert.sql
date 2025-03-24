/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Device_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Device_Insert`(
    IN ip_TransIDs LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20200730@Bobby.Nguyen
	    Task : Transform Device Info
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
		    - 20200908@Bobby.Nguyen: Support multiple threads [Redmine ID: 137963]
            - 0200918@CaseyHuynh: Change column TransID to RawTransID [Redmine ID: 137963]
            - 20201006@CaseyHuynh: Move Server, Get Lastest SP From PRO And Update data length of FingerprintCode from 692 to 620 [Redmine ID: 143011]
		    - 20201019@CaseyHuynh:	Move Server, Phase 2 [Redmine ID: 143011]	
            - 20201020@CaseyHuynh: Update Owner, metadata [Redmine ID: 145271]
            - 20210510@Aries.Nguyen: Remove insert log dba_SP_PerformanceStats [Redmine ID: #154792]
            - 20211129@Casey.Huynh: Remove Transaction07.FingerprintMoreInfo AND Devicefingerprint.CreatedDate Column [Redmine ID: #165167]
			- 20211201@Casey.Huynh: Fix Issue Devicefingerprint.DeviceID = 0 [Redmine ID: #165164]
			- 20230316@Jonathan.Doan: Support return new device login for Alpha [Redmine ID: #185185]
			- 20230426@Jonathan.Doan: Get BotDetectionValue from RawTransaction [Redmine ID: #186644]
			- 20230807@Terry.Nguyen: Add Fake IP [Redmine ID: #191829]
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
			- 20240326@Jonathan.Doan: Enhance for EC24 [Redmine: 202878] 
			- 20240806@Jonathan.Doan: Change data flow v6 [Redmine ID: #206403]
			- 20250324@Jonathan.Doan: Use CURRENT_TIMESTAMP for InsertTime [Redmine ID: #217768]
	    Param's Explanation (filtered by):
        
        Example:
			SET sql_safe_updates = 0;
			CALL DCS_DC_Transform_Device_Insert('32');
	*/

	DECLARE vrDeviceStatusNew			TINYINT DEFAULT 1;			# New Device
	DECLARE vrDeviceStatusOld			TINYINT DEFAULT 2;			# Old Device
	DECLARE vrDeviceStatusRecover		TINYINT DEFAULT 3;			# Recover Device
	
    DECLARE lv_AssociationJson 			LONGTEXT;
    DECLARE lv_NewAccountDeviceJson 	LONGTEXT;
    
    DECLARE lv_InsertionTime 			TIMESTAMP(4) DEFAULT CURRENT_TIMESTAMP(4);
    
    #============================================
	DROP TEMPORARY TABLE IF EXISTS Temp_Input;
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoveredDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoverDeviceByBet;
    #==============================================
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_Input(
			TransID			 		BIGINT	UNSIGNED NOT NULL		PRIMARY KEY
    );
    
	CREATE TEMPORARY TABLE Temp_Transaction(
			TransID					BIGINT	UNSIGNED PRIMARY KEY
        , 	RawTransID				BIGINT UNSIGNED
		, 	AccountID				BIGINT	UNSIGNED
		, 	LoginName				VARCHAR(100)
		, 	SubscriberID			INT
        , 	UserAgentKey			VARCHAR(32)
        , 	IP						VARCHAR(50)
		, 	DeviceCode				VARCHAR(32) 
		, 	FingerprintCode			VARCHAR(620)
		, 	FingerprintCode1		VARCHAR(300)
		, 	FingerprintCode2		VARCHAR(300)
		, 	CreatedDate				DATETIME
		, 	TransTime				TIMESTAMP(4) 
        , 	DeviceCodeID			BIGINT UNSIGNED
        , 	DeviceID				BIGINT UNSIGNED DEFAULT 0
        , 	FirstDeviceCode			VARCHAR(32)
        , 	DeviceStatus			TINYINT
        , 	DeviceFingerprintID		BIGINT UNSIGNED
        
        , 	FP_DeviceID				BIGINT UNSIGNED
        , 	FP_DeviceMappingID		BIGINT UNSIGNED
        , 	FP_DeviceStatus			TINYINT
	);
    
    CREATE TEMPORARY TABLE Temp_ExistedDevice(
			DeviceID				BIGINT NOT NULL
        , 	DeviceCode   			VARCHAR(32) NOT NULL
        , 	DeviceCodeID  			BIGINT NOT NULL
        , 	FirstTransID  			BIGINT
        , 	FirstDeviceCode 		VARCHAR(32)
        , 	IsNew					TINYINT DEFAULT 0
        , 	PRIMARY KEY 			PK_Temp_ExistedDevice(DeviceCode, DeviceID)
	);
    
    CREATE TEMPORARY TABLE Temp_RecoveredDevice(
			AccountID				BIGINT UNSIGNED
        ,	DeviceCode   			VARCHAR(32)
		,	FingerprintCode			VARCHAR(620)
        ,	DeviceID				BIGINT UNSIGNED
        ,	RecoverCode 			VARCHAR(32)
        ,	PRIMARY KEY 			PK_Temp_RecoveredDevice(AccountID, DeviceCode,FingerprintCode)
        ,	INDEX 					IX_Temp_RecoveredDevice_DeviceCode_DeviceID_RecoverCode(DeviceCode, DeviceID, RecoverCode)
	);
    
    CREATE TEMPORARY TABLE Temp_RecoverDeviceByBet(
			TransID							BIGINT PRIMARY KEY
        ,	AccountID						BIGINT UNSIGNED
        ,	DeviceCode						VARCHAR(32)
        ,	FingerprintCode 				VARCHAR(620)
		, 	FingerprintCode_CommaSeparated	VARCHAR(620)
        ,	INDEX 							IX_Temp_RecoverDeviceByBet_AccountID_DeviceCode_FingerprintCode(AccountID,DeviceCode,FingerprintCode)
    );
	
    
	#========GET INPUT DATA===========================
    SET @sql = CONCAT("INSERT IGNORE INTO Temp_Input(TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    
	INSERT INTO Temp_Transaction(TransID, RawTransID, AccountID, LoginName, SubscriberID, UserAgentKey, IP, DeviceCode, CreatedDate, TransTime, FingerprintCode)
    SELECT 	trans.TransID
		, 	trans.RawTransID
		, 	trans.AccountID
		, 	trans.LoginName
		, 	trans.SubscriberID
		, 	trans.UserAgentKey
		, 	trans.IP
		, 	trans.DeviceCode
		, 	trans.CreatedDate
		, 	trans.TransTime
		, 	trans.FingerprintCode
	FROM Temp_Input AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = tmp.TransID
    ORDER BY tmp.TransID ASC;
    
    /* === Add index Temp_Transaction === */
	ALTER TABLE Temp_Transaction
	ADD INDEX IX_Temp_Transaction_RawTransID (RawTransID),
	ADD INDEX IX_Temp_Transaction_DeviceCode (DeviceCode),
	ADD INDEX IX_Temp_Transaction_AccountID_DeviceCode_FingerprintCode (AccountID, DeviceCode, FingerprintCode);
        
    UPDATE Temp_Transaction
	SET FingerprintCode1 = SUBSTRING_INDEX(FingerprintCode, ';', 1),
		FingerprintCode2 = SUBSTRING_INDEX(FingerprintCode, ';', -1)
    WHERE FingerprintCode IS NOT NULL;
    
    # START
    -- existed device
    INSERT INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID)
    WITH CTE_DeviceCode AS 
    (
		SELECT DISTINCT DeviceCode 
        FROM Temp_Transaction
	)
    SELECT 	dc.DeviceID
		,	dc.DeviceCode
        ,	dc.DeviceCodeID
    FROM CTE_DeviceCode AS cte
		INNER JOIN DCS_DataCenter.DeviceCode AS dc ON dc.DeviceCode = cte.DeviceCode;

    #recover steps
    # Recover DeviceID by Association - Level 1
    INSERT INTO Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID)
    WITH CTE_Assosiation AS (
		SELECT 	DISTINCT 
				AccountID
			,	DeviceCode
            ,	FingerprintCode
            ,	FingerprintCode1
            ,	FingerprintCode2
        FROM Temp_Transaction AS tmpT
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice td WHERE td.DeviceCode = tmpT.DeviceCode)
	)
    SELECT 	cte.AccountID
		,	cte.DeviceCode
        ,	cte.FingerprintCode
        ,	rc.DeviceID
    FROM CTE_Assosiation AS cte,
    LATERAL (
		SELECT ass.DeviceID
        FROM DCS_DataCenter.Association AS ass
			INNER JOIN	DCS_DataCenter.DeviceFingerprint AS df ON ass.DeviceID = df.DeviceID
        WHERE ass.AccountID = cte.AccountID
			AND (FIND_IN_SET(cte.FingerprintCode1, REPLACE(df.FingerprintCode,';',',')) > 0
				OR FIND_IN_SET(cte.FingerprintCode2, REPLACE(df.FingerprintCode,';',',')) > 0)
		ORDER BY ass.DeviceID ASC
        LIMIT 1
    ) AS rc;

	# UPDATE recover level 2 from incoming deviceid
    INSERT INTO Temp_RecoverDeviceByBet(TransID, AccountID, DeviceCode, FingerprintCode, FingerprintCode_CommaSeparated)
    SELECT 	TransID
		,	AccountID
        ,	DeviceCode
        ,	FingerprintCode
        ,	REPLACE(FingerprintCode,';',',') AS FingerprintCode_CommaSeparated
	FROM Temp_Transaction AS tts
	WHERE tts.DeviceCode IS NOT NULL
		AND tts.FingerprintCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice AS de WHERE de.DeviceCode = tts.DeviceCode)
		AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice AS dr WHERE dr.DeviceCode = tts.DeviceCode);

    INSERT IGNORE INTO Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID, RecoverCode)
    SELECT 	rb.AccountID
		,	rb.DeviceCode
        ,	rb.FingerprintCode
        ,	rd.DeviceID
        ,	rd.RecoverCode
    FROM Temp_RecoverDeviceByBet AS rb,
    LATERAL (
		SELECT 	(CASE WHEN rb.DeviceCode = ts.DeviceCode THEN 1 ELSE 0 END) AS DeviceID
			, 	ts.DeviceCode AS RecoverCode
        FROM Temp_Transaction AS ts
        WHERE rb.AccountID = ts.AccountID
			AND rb.TransId > ts.TransId
			AND (
				rb.DeviceCode = ts.DeviceCode #--> exists from incoming deviceid
				OR (rb.DeviceCode <> ts.DeviceCode
					AND (FIND_IN_SET(ts.FingerprintCode1, rb.FingerprintCode_CommaSeparated) > 0
						OR FIND_IN_SET(ts.FingerprintCode2, rb.FingerprintCode_CommaSeparated) > 0
                        )
					) #--> recover from incoming deviceid
			)
		ORDER BY ts.TransId ASC
        LIMIT 1
    ) AS rd
    WHERE rd.DeviceID = 0; #--> just get recover case
    
    # INSERT new Devices
    INSERT IGNORE INTO DCS_DataCenter.Device(FirstDeviceCode, UserAgentKey, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    SELECT 	tts.DeviceCode
		,	tts.UserAgentKey
		,	MIN(tts.TransID) 		AS FirstTransID
		,	MIN(tts.TransTime) 		AS CreatedTime
		,	MIN(tts.CreatedDate) 	AS CreatedDate
		,	lv_InsertionTime		AS InsertTime
    FROM Temp_Transaction AS tts
    WHERE tts.DeviceCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice AS de WHERE de.DeviceCode = tts.DeviceCode)
		AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice AS dr WHERE dr.DeviceCode = tts.DeviceCode)
    GROUP BY tts.DeviceCode, tts.UserAgentKey; #--> Use GROUP BY UserAgentKey combined with INSERT IGNORE to correctly retrieve the UserAgentKey of the first record
    
    # INSERT new DeviceCode
    # NEW code - new DeviceID
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT 	t.DeviceCode
			,	MIN(t.TransID) 		AS FirstTransID
			,	MIN(t.TransTime) 	AS CreatedTime
			,	MIN(t.CreatedDate) 	AS CreatedDate
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice AS de WHERE de.DeviceCode = t.DeviceCode)
			AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice AS dr WHERE dr.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    )
    SELECT 	tts.DeviceCode
		,	dv.DeviceID
		,	tts.FirstTransID
		,	tts.CreatedTime
		,	tts.CreatedDate
		,	lv_InsertionTime AS InsertTime
	FROM CTE_DeviceCode AS tts
	INNER JOIN DCS_DataCenter.Device AS dv ON dv.FirstDeviceCode = tts.DeviceCode;

    #NEW code vs Old DeviceID
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT 	t.DeviceCode
			,	MIN(t.TransID) 		AS FirstTransID
			,	MIN(t.TransTime) 	AS CreatedTime
			,	MIN(t.CreatedDate) 	AS CreatedDate
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice AS de WHERE de.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    ), 
    CTE_NewCodeOldDeviceID AS (
		SELECT 	DISTINCT 
				DeviceCode
			,	DeviceID
            ,	RecoverCode 
        FROM Temp_RecoveredDevice
	)
    SELECT 	tts.DeviceCode
		,	IF(dr.DeviceID > 0 , dr.DeviceID, dc.DeviceID) AS DeviceID
		,	tts.FirstTransID
		,	tts.CreatedTime
		,	tts.CreatedDate
		,	lv_InsertionTime AS InsertTime
	FROM CTE_DeviceCode AS tts
		INNER JOIN CTE_NewCodeOldDeviceID AS dr ON dr.DeviceCode = tts.DeviceCode
		LEFT JOIN DCS_DataCenter.DeviceCode AS dc ON dc.DeviceCode = dr.RecoverCode AND dc.DeviceID > 0
    WHERE IF(dr.DeviceID > 0 , dr.DeviceID, dc.DeviceID)  > 0;
	
    # MERGE existed, recovered vs incoming devices
    INSERT IGNORE INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, IsNew)
    WITH CTE_DeviceCode AS (
		SELECT DISTINCT DeviceCode
        FROM Temp_Transaction
	)
    SELECT	dc.DeviceID
		,	tts.DeviceCode
        ,	dc.DeviceCodeID
        ,	1 AS IsNew
    FROM  CTE_DeviceCode AS tts
		INNER JOIN DCS_DataCenter.DeviceCode AS dc ON dc.DeviceCode = tts.DeviceCode;

    # INSERT new DeviceFingerprint
    INSERT IGNORE INTO DCS_DataCenter.DeviceFingerprint(FingerprintCode, DeviceID, CreatedTime, InsertTime)
	SELECT 	tts.FingerprintCode
		,	tmpEd.DeviceID
		,	MIN(tts.TransTime) 	AS CreatedTime
		,	lv_InsertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
		INNER JOIN Temp_ExistedDevice AS tmpEd ON tmpEd.DeviceCode = tts.DeviceCode
    WHERE tts.FingerprintCode IS NOT NULL
    GROUP BY tts.FingerprintCode, tmpEd.DeviceID;
    
    # UPDATE back Temp_ExistedDevice
    UPDATE Temp_ExistedDevice AS de
		INNER JOIN DCS_DataCenter.Device AS dv ON dv.DeviceID = de.DeviceID
    SET de.FirstTransID = dv.FirstTransID
		, de.FirstDeviceCode = dv.FirstDeviceCode;

    UPDATE Temp_Transaction AS tts
		LEFT JOIN Temp_ExistedDevice AS de ON de.DeviceCode = tts.DeviceCode
		LEFT JOIN Temp_RecoveredDevice AS dr ON dr.AccountID = tts.AccountID 
											AND dr.DeviceCode = tts.DeviceCode 
											AND dr.FingerprintCode = tts.FingerprintCode
		LEFT JOIN DCS_DataCenter.DeviceFingerprint df ON df.DeviceID = de.DeviceID 
													AND df.FingerprintCode = tts.FingerprintCode
	SET	tts.DeviceID 				= IF(de.DeviceID > 0, de.DeviceID, tts.DeviceID)
		, tts.FirstDeviceCode 		= IF(de.DeviceID > 0, de.FirstDeviceCode, tts.FirstDeviceCode)
		, tts.DeviceCodeID 			= IF(de.DeviceID > 0, de.DeviceCodeID, tts.DeviceCodeID)
		, tts.DeviceFingerprintID 	= IF(df.DeviceFingerprintID > 0, df.DeviceFingerprintID, tts.DeviceFingerprintID)
		, tts.DeviceStatus 			= CASE WHEN de.DeviceID > 0 AND tts.TransId > de.FirstTransID AND dr.DeviceID IS NULL THEN vrDeviceStatusOld
										WHEN dr.DeviceID > 0 OR dr.RecoverCode IS NOT NULL THEN vrDeviceStatusRecover
                                        WHEN de.DeviceID > 0 AND (tts.TransId = de.FirstTransID OR de.IsNew = 1) THEN vrDeviceStatusNew  
										ELSE tts.DeviceStatus END;
    
    UPDATE Temp_Transaction AS tmp
		INNER JOIN DCS_DataCenter.FP_TransactionDeviceMapping AS tdm ON tdm.RawTransID = tmp.RawTransID
	SET tmp.FP_DeviceMappingID = tdm.FP_DeviceMappingID,
		tmp.FP_DeviceID = tdm.FP_DeviceID,
		tmp.FP_DeviceStatus = tdm.FP_DeviceStatus;
	
    /* === Insert new Association === */
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				AccountID
			,	DeviceID
			,	FP_DeviceID
			,	SubscriberID
			,	TransTime
			,	CreatedDate
		FROM Temp_Transaction
		WHERE AccountID IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'AccountID'		, AccountID
				,	'DeviceID'		, DeviceID
				,	'FP_DeviceID'	, FP_DeviceID
				,	'SubscriberID'	, SubscriberID
				,	'CreatedTime'	, TransTime
				,	'CreatedDate'	, CreatedDate
			)
		) AS json_data
	INTO lv_AssociationJson
	FROM cte_DistinctData;
    
    SET lv_AssociationJson = IFNULL(lv_AssociationJson,'[{}]');
	CALL DCS_DC_Transform_Association_Insert(lv_AssociationJson);
    
    
    /* === Insert into NewAccountDevice === */
    WITH cte_DistinctData AS (
		SELECT	DISTINCT
				AccountID
			,	DeviceID
            ,	SubscriberID
            ,	RawTransID
            ,	CreatedDate
            ,	LoginName
            ,	TransTime
            ,	UserAgentKey
            ,	IP
		FROM Temp_Transaction
		WHERE AccountID IS NOT NULL
			AND DeviceID IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
					'AccountID'			, AccountID
				,	'DeviceID'			, DeviceID
				,	'SubscriberID'		, SubscriberID
				,	'RawTransID'		, RawTransID
				,	'CreatedDate'		, CreatedDate
				,	'LoginName'			, LoginName
				,	'TransTime'			, TransTime
				,	'UserAgentKey'		, UserAgentKey
				,	'IP'				, IP
			)
		) AS json_data
	INTO lv_NewAccountDeviceJson
	FROM cte_DistinctData;
    
    SET lv_NewAccountDeviceJson = IFNULL(lv_NewAccountDeviceJson,'[{}]');
	CALL DCS_DC_Transform_NewAccountDevice_Insert(lv_NewAccountDeviceJson);
	
	INSERT IGNORE INTO  DCS_DataCenter.Transaction07(RawTransID, LoginName, TransTime, SubscriberID, AccountID, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime, BotDetectionValue, BotComponentID, FakeIP, IsIncognitoMode, JSChallengeInfoID, FP_UserAgentID, FP_DeviceMappingID, FP_DeviceID, FP_DeviceStatus)
	SELECT 	ts.RawTransID
		,	ts.LoginName
		,	ts.TransTime
		,	ts.SubscriberID
		,	ts.AccountID
		,	ts.URLID
		,	tmp.DeviceCodeID
		,	tmp.DeviceID
		,	tmp.FirstDeviceCode
		,	tmp.DeviceStatus
		,	tmp.DeviceFingerprintID
		,	ts.UserAgentKey
		,	ts.IP
		,	ts.IPID
		,	ts.ActionResultID
		,	ts.Flagged
		,	ts.PluginID
		,	ts.TransStatus
		,	ts.CreatedDate
		,	lv_InsertionTime AS InsertTime
		,	ts.BotDetectionValue
		,	ts.BotComponentID
		,	ts.FakeIP
		,	ts.IsIncognitoMode
		,	ts.JSChallengeInfoID
		,	ts.FP_UserAgentID
		,	tmp.FP_DeviceMappingID
		,	tmp.FP_DeviceID
		,	tmp.FP_DeviceStatus
	FROM Temp_Transaction AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS ts ON ts.TransID = tmp.TransID
	WHERE tmp.DeviceID IS NOT NULL;
	
	DELETE trans
	FROM DCS_DataCenter.Transaction AS trans
		INNER JOIN Temp_Transaction AS tmp ON tmp.TransID = trans.TransID
	WHERE tmp.DeviceID IS NOT NULL;
    
    DELETE tdm
    FROM DCS_DataCenter.FP_TransactionDeviceMapping AS tdm
		INNER JOIN Temp_Transaction AS tmp ON tmp.RawTransID = tdm.RawTransID;
END$$

DELIMITER ;