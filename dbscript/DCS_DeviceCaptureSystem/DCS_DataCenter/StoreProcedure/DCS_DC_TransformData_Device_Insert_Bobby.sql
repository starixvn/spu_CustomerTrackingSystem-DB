CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_TransformData_Device_Insert_Bobby`(IN ip_TransJson LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_520_ci)
BEGIN
	/*
	Created: 20200730@Bobby.Nguyen
	Task : Transform Device Info
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/

	DECLARE vrDeviceStatusNew			TINYINT DEFAULT 1;			# New Device
	DECLARE vrDeviceStatusOld			TINYINT DEFAULT 2;			# Old Device
	DECLARE vrDeviceStatusRecover		TINYINT DEFAULT 3;			# Recover Device
    DECLARE insertionTime TIMESTAMP(4);
	DECLARE	batchCount 			INT;
    DECLARE code CHAR(5) DEFAULT '00000';
    DECLARE error_no int DEFAULT 0;
	DECLARE error_message varchar(255) DEFAULT '';
	
    # STATS count
    DECLARE updateCount INT DEFAULT 0;
    DECLARE insertCount INT DEFAULT 0;
    DECLARE transCount INT DEFAULT 0;
    DECLARE newASSCount INT DEFAULT 0;
    DECLARE newDFCount INT DEFAULT 0;
    DECLARE newDeviceCodeCount INT DEFAULT 0;
    DECLARE newDeviceCount INT DEFAULT 0;
    
    # ERROR handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			error_message = MESSAGE_TEXT
            ,error_no = MYSQL_ERRNO
            ,code = RETURNED_SQLSTATE;
		
		SELECT error_no, error_message;
	END;
    
    SET insertionTime = CURRENT_TIMESTAMP(4);	
	
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoveredDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoverDeviceByBet;
    #==============================================
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_Transaction(
		 TransID				BIGINT	UNSIGNED
		, AccountID				BIGINT	UNSIGNED
		, SubscriberID			INT
        , UserAgentKey			VARCHAR(32)
		, DeviceCode			VARCHAR(32)
		, FingerprintCode		VARCHAR(2000) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , FingerprintMoreInfo	VARCHAR(250) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, CreatedDate			DATETIME
		, TransTime				TIMESTAMP(4)
		, DeviceCodeID			BIGINT	UNSIGNED		NULL
        , FirstDeviceCode		VARCHAR(32)				NULL
        , DeviceID				BIGINT	UNSIGNED		NULL
		, DeviceStatus			TINYINT					NULL DEFAULT 1
		, DeviceFingerprintID	BIGINT	UNSIGNED		NULL
        , RecoverTransID		BIGINT  UNSIGNED		NULL
        
        , PRIMARY KEY	PK_Temp_Transaction_TransID(TransID)
        , INDEX 		IX_Temp_Transaction_DeviceCode(DeviceCode)
	) 
    #ENGINE = MEMORY
    ;
    
	#========GET INPUT DATA===========================
	INSERT INTO Temp_Transaction(TransID, AccountID, SubscriberID, UserAgentKey, DeviceCode, CreatedDate, TransTime,  FingerprintCode, FingerprintMoreInfo, DeviceStatus)
    WITH CTE_Trans AS (
		SELECT TransID
		FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
				TransID BIGINT UNSIGNED PATH "$.TransId" 
			  )
		) AS t
    )
    SELECT t.TransID
		, AccountID
		, SubscriberID
		, (CASE WHEN tmpTrans.UserAgentKey ="null" THEN NULL ELSE tmpTrans.UserAgentKey END) AS UserAgentKey
		, (CASE WHEN tmpTrans.DeviceCode ="null" THEN NULL ELSE tmpTrans.DeviceCode END) AS DeviceCode
		, CreatedDate
		, TransTime
		,  (CASE WHEN tmpTrans.FingerprintCode ="null" THEN NULL ELSE tmpTrans.FingerprintCode END) FingerprintCode
		,  (CASE WHEN tmpTrans.FingerprintMoreInfo ="null" THEN NULL ELSE tmpTrans.FingerprintMoreInfo END)FingerprintMoreInfo
		, vrDeviceStatusNew AS DeviceStatus
	FROM DCS_DataCenter.Transaction tmpTrans
	INNER JOIN CTE_Trans t ON tmpTrans.TransId = t.TransId
	FOR UPDATE SKIP LOCKED
    ;
    GET DIAGNOSTICS batchCount = ROW_COUNT;
    
	IF batchCount = 0 then
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'ERROR: Does not exist trans to process', MYSQL_ERRNO = 1001;
    END IF;
    
    # START
    -- existed device
    CREATE TEMPORARY TABLE Temp_ExistedDevice(
		DeviceID				BIGINT
        , DeviceCode   			VARCHAR(32)
        , DeviceCodeID  		BIGINT
        , FirstTransID  		BIGINT
        , DeviceFingerprintID 	BIGINT
        , FirstDeviceCode 		VARCHAR(32)
        , IsNew					TINYINT(1) DEFAULT 0
        , PRIMARY KEY PK_Temp_ExistedDevice(DeviceCode, DeviceID)
	) ENGINE = MEMORY;
    
    INSERT INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, FirstTransID, FirstDeviceCode)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT DISTINCT dc.DeviceID, dc.DeviceCode, dc.DeviceCodeID, dv.FirstTransID, dv.FirstDeviceCode
    FROM CTE_DeviceCode tts
    INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode
    INNER JOIN DCS_DataCenter.Device dv ON dv.DeviceID = dc.DeviceID
    ;
    
    #recover step
    CREATE TEMPORARY TABLE Temp_RecoveredDevice(
		AccountID			BIGINT
        , DeviceCode   		VARCHAR(32)
		, FingerprintCode	VARCHAR(2000)
        , DeviceID			BIGINT DEFAULT 0
	) ENGINE = MEMORY;
    
    # Recover DeviceID by Association - Level 1
    INSERT Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID)
    WITH CTE_Assosiation AS (
		SELECT DISTINCT AccountID, DeviceCode, FingerprintCode 
        FROM Temp_Transaction tts
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice td WHERE td.DeviceCode = tts.DeviceCode)
	)
    SELECT AccountID, DeviceCode, FingerprintCode, DeviceID
    FROM (
		SELECT tts.AccountID, tts.DeviceCode, tts.FingerprintCode, MIN(ass.DeviceID) AS DeviceID
			, MAX(DCS_DC_ISLISTSMATCHBYITEM(';',tts.FingerprintCode, df.FingerprintCode)) AS IsMatched
		FROM 
			CTE_Assosiation tts
		INNER JOIN DCS_DataCenter.Association AS ass 
			ON tts.AccountID = ass.AccountID
		INNER JOIN	DCS_DataCenter.DeviceFingerprint AS df 
			ON ass.DeviceID = df.DeviceID
		GROUP BY tts.AccountID, tts.DeviceCode, tts.FingerprintCode
    ) AS t
    WHERE IsMatched = 1
    ;
   
   # UPDATE recover level 2
    CREATE TEMPORARY TABLE Temp_RecoverDeviceByBet 
    SELECT TransID, AccountID, DeviceCode, FingerprintCode 
    FROM Temp_Transaction tts
    WHERE tts.DeviceCode IS NOT NULL
		AND tts.FingerprintCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = tts.DeviceCode)
        AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = tts.DeviceCode)
	;
    INSERT IGNORE INTO Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID)
    SELECT DISTINCT rb.AccountID, rb.DeviceCode, rb.FingerprintCode, 9999 AS DeviceID
    FROM Temp_Transaction tts
    INNER JOIN Temp_RecoverDeviceByBet rb ON rb.AccountID = tts.AccountID 
		AND rb.DeviceCode <> tts.DeviceCode
        AND DCS_DC_ISLISTSMATCHBYITEM(';',tts.FingerprintCode, rb.FingerprintCode) = 1
    INNER JOIN Temp_ExistedDevice de ON de.DeviceCode = rb.DeviceCode
    WHERE tts.TransID > rb.TransID
    ;
    
    # INSERT new Devices
    INSERT IGNORE INTO DCS_DataCenter.Device(FirstDeviceCode, UserAgentKey, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    SELECT 	tts.DeviceCode
		, tts.UserAgentKey
		, MIN(tts.TransID) AS FirstTransID
		, MIN(tts.TransTime) AS CreatedTime
		, MIN(tts.CreatedDate) AS CreatedDate
		, insertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
    WHERE tts.DeviceCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = tts.DeviceCode)
		AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = tts.DeviceCode) 
    GROUP BY tts.DeviceCode, tts.UserAgentKey
    ;
	GET DIAGNOSTICS insertCount = ROW_COUNT;
    SET newDeviceCount = insertCount;
    
    # INSERT new DeviceCode
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT t.DeviceCode
			, MIN(t.TransID) AS FirstTransID
			, MIN(t.TransTime) AS CreatedTime
			, MIN(t.CreatedDate) AS CreatedDate
            , insertionTime	AS InsertTime
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    )
    # NEW code - new DeviceID
    SELECT tts.DeviceCode
		, dv.DeviceID
		, tts.FirstTransID
		, tts.CreatedTime
		, tts.CreatedDate
		, tts.InsertTime
	FROM CTE_DeviceCode AS tts
	INNER JOIN DCS_DataCenter.Device dv ON dv.FirstDeviceCode = tts.DeviceCode
    ;
    GET DIAGNOSTICS insertCount = ROW_COUNT;
    SET newDeviceCodeCount = insertCount;
    
    #NEW code vs Old DeviceID
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT t.DeviceCode
			, MIN(t.TransID) AS FirstTransID
			, MIN(t.TransTime) AS CreatedTime
			, MIN(t.CreatedDate) AS CreatedDate
            , insertionTime	AS InsertTime
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    ), 
    CTE_NewCodeOldDeviceID AS (SELECT DISTINCT DeviceCode, DeviceID FROM Temp_RecoveredDevice)
    SELECT tts.DeviceCode
		, IF(dr.DeviceID > 0 , dr.DeviceID, dv.DeviceID) AS DeviceID
		, tts.FirstTransID
		, tts.CreatedTime
		, tts.CreatedDate
		, tts.InsertTime
	FROM CTE_DeviceCode AS tts
	INNER JOIN CTE_NewCodeOldDeviceID dr ON dr.DeviceCode = tts.DeviceCode
    LEFT JOIN DCS_DataCenter.Device dv ON dv.FirstDeviceCode = tts.DeviceCode
	;
	GET DIAGNOSTICS insertCount = ROW_COUNT;
    SET newDeviceCodeCount := newDeviceCodeCount + insertCount;
    
    # MERGE existed, recovered vs incoming devices
    INSERT IGNORE INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, FirstTransID, FirstDeviceCode, IsNew)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT dc.DeviceID, tts.DeviceCode, dc.DeviceCodeID, dv.FirstTransID, dv.FirstDeviceCode, 1 AS IsNew
    FROM  CTE_DeviceCode tts
    INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode
    INNER JOIN DCS_DataCenter.Device dv ON dv.DeviceID = dc.DeviceID
    ;
    
    # INSERT new DeviceFingerprint
	INSERT IGNORE INTO DCS_DataCenter.DeviceFingerprint(FingerprintCode, DeviceID, FingerprintMoreInfo, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT DISTINCT DeviceCode, DeviceID FROM Temp_ExistedDevice
        UNION 
        SELECT DISTINCT DeviceCode, DeviceID FROM Temp_RecoveredDevice
    )
	SELECT tts.FingerprintCode
		, de.DeviceID
		, MIN(tts.FingerprintMoreInfo) AS FingerprintMoreInfo
		, MIN(tts.TransTime) AS CreatedTime
		, MIN(tts.CreatedDate) AS CreatedDate
		, insertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
    INNER JOIN CTE_DeviceCode AS de ON de.DeviceCode = tts.DeviceCode
    WHERE tts.FingerprintCode IS NOT NULL
    GROUP BY tts.FingerprintCode, de.DeviceID
    ;    
    GET DIAGNOSTICS insertCount = ROW_COUNT;
    SET newDFCount = insertCount;
    
    # UPDATE DeviceFingerprintID
    WITH cte_Trans AS (SELECT DISTINCT DeviceCode, FingerprintCode FROM Temp_Transaction)
    UPDATE Temp_ExistedDevice de
    INNER JOIN cte_Trans tts ON tts.DeviceCode = de.DeviceCode
    INNER JOIN DCS_DataCenter.DeviceFingerprint df ON df.DeviceID = de.DeviceID AND df.FingerprintCode = tts.FingerprintCode
    SET 
		de.DeviceFingerprintID = df.DeviceFingerprintID
    ;
    #select * from Temp_ExistedDevice;
   
    # INSERT new Association
    INSERT IGNORE INTO DCS_DataCenter.Association(DeviceID, AccountID, SubscriberID, CreatedTime, CreatedDate,  InsertTime)
    SELECT de.DeviceID
		, tts.AccountID
		, tts.SubscriberID
		, MIN(tts.TransTime) AS CreatedTime
		, MIN(tts.CreatedDate) AS CreatedDate
		, insertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
    INNER JOIN Temp_ExistedDevice de ON de.DeviceCode = tts.DeviceCode
    GROUP BY  de.DeviceID
			, tts.AccountID
            , tts.SubscriberID
	;
    GET DIAGNOSTICS insertCount = ROW_COUNT;
    SET newASSCount = insertCount;
    
    # UPDATE back Transaction
    UPDATE DCS_DataCenter.Transaction AS ts
    INNER JOIN Temp_Transaction tts	ON tts.TransID = ts.TransID
	LEFT JOIN Temp_ExistedDevice de ON de.DeviceCode = tts.DeviceCode
    LEFT JOIN Temp_RecoveredDevice dr ON dr.AccountID = tts.AccountID 
		AND dr.DeviceCode = tts.DeviceCode 
        AND dr.FingerprintCode = tts.FingerprintCode
	SET	ts.DeviceID 				= de.DeviceID
		, ts.FirstDeviceCode 		= de.FirstDeviceCode
		, ts.DeviceCodeID 			= de.DeviceCodeID
		, ts.DeviceFingerprintID 	= de.DeviceFingerprintID
		, ts.DeviceStatus 			= CASE 
										WHEN tts.TransId > de.FirstTransID AND dr.DeviceID = 0 THEN vrDeviceStatusOld
										WHEN dr.DeviceID > 0 THEN vrDeviceStatusRecover 
										ELSE vrDeviceStatusNew 
									END
    ;
    GET DIAGNOSTICS updateCount = ROW_COUNT;
    SET transCount = updateCount;
	# END
END