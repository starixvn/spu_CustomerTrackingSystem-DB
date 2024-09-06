/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Device_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Device_Insert`(
    IN ip_TransJson LONGTEXT
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
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_Device_Insert('[{"TransId": 1},{"TransId": 2}]');
	*/

	DECLARE vrDeviceStatusNew			TINYINT DEFAULT 1;			# New Device
	DECLARE vrDeviceStatusOld			TINYINT DEFAULT 2;			# Old Device
	DECLARE vrDeviceStatusRecover		TINYINT DEFAULT 3;			# Recover Device
	
    # STATS count
    DECLARE lv_InsertionTime TIMESTAMP(4);
    SET lv_InsertionTime = CURRENT_TIMESTAMP(4);
    
    #============================================
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoveredDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoverDeviceByBet;
    #==============================================
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_Transaction(
			TransID					BIGINT	UNSIGNED PRIMARY KEY
		, 	AccountID				BIGINT	UNSIGNED
		, 	SubscriberID			INT
        , 	UserAgentKey			VARCHAR(32)
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
        , 	INDEX 					IX_Temp_Transaction_DeviceCode(DeviceCode)
        , 	INDEX 					IX_Temp_Transaction_AccountID(AccountID, DeviceCode, FingerprintCode)
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
	INSERT INTO Temp_Transaction(TransID, AccountID, SubscriberID, UserAgentKey, DeviceCode, CreatedDate, TransTime,  FingerprintCode)
    WITH CTE_Trans AS (
		SELECT TransID
		FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
				TransID BIGINT UNSIGNED PATH "$.TransId" 
			  )
		) AS t
    )
    SELECT 	trans.TransID
		, 	trans.AccountID
		, 	trans.SubscriberID
		, 	trans.UserAgentKey
		, 	trans.DeviceCode
		, 	trans.CreatedDate
		, 	trans.TransTime
		, 	trans.FingerprintCode
	FROM CTE_Trans AS cte
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = cte.TransID
    ORDER BY cte.TransID ASC;
    
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
		, tts.DeviceStatus 			= CASE 
										WHEN de.DeviceID > 0 AND tts.TransId > de.FirstTransID AND dr.DeviceID IS NULL THEN vrDeviceStatusOld
										WHEN dr.DeviceID > 0 OR dr.RecoverCode IS NOT NULL THEN vrDeviceStatusRecover
                                        WHEN de.DeviceID > 0 AND (tts.TransId = de.FirstTransID OR de.IsNew = 1) THEN vrDeviceStatusNew  
										ELSE tts.DeviceStatus 
									END;

	SELECT 	TransID
		,	DeviceCodeID
		,	DeviceID
		,	FirstDeviceCode
		,	DeviceStatus
		,	DeviceFingerprintID
	FROM Temp_Transaction
	WHERE DeviceID IS NOT NULL;
END$$

DELIMITER ;
