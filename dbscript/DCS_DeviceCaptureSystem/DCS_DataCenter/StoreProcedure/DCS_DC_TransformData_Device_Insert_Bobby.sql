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
    
    DECLARE code CHAR(5) DEFAULT '00000';
    DECLARE err_no int DEFAULT 0;
    DECLARE cod_name varchar(10) DEFAULT '';
	DECLARE err_message varchar(255) DEFAULT '';
	DECLARE sch_name varchar(128) DEFAULT 'DCS_DataCenter';
    DECLARE tab_name varchar(128) DEFAULT '';
    DECLARE col_name varchar(128) DEFAULT '';
    DECLARE sp_name varchar(128) DEFAULT 'DCS_DC_TransformData_Device_Insert_Bobby';
	
    # STATS count
    DECLARE insertionTime TIMESTAMP(4);
	DECLARE	rowCount 	INT;
    DECLARE updateCount INT DEFAULT 0;
    DECLARE insertCount INT DEFAULT 0;
    DECLARE transCount INT DEFAULT 0;
    DECLARE newASSCount INT DEFAULT 0;
    DECLARE newDFCount INT DEFAULT 0;
    DECLARE newDeviceCodeCount INT DEFAULT 0;
    DECLARE newDeviceCount INT DEFAULT 0;
    
    # Perf stats
    DECLARE call_time timestamp(4);
    DECLARE start_time timestamp(4);
    
    # ERROR handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			err_message = MESSAGE_TEXT
            ,err_no = MYSQL_ERRNO
            ,cod_name = RETURNED_SQLSTATE
            ,sch_name = SCHEMA_NAME
            ,tab_name = TABLE_NAME
            ,col_name = COLUMN_NAME;
		
		SELECT err_no, err_message;
        # Write error log
        #select * from Temp_PerformanceStats;
        
        INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
		WITH CTE_Stats AS (
			SELECT CONCAT('ERROR_',err_no) AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4) ) / 1000 as diff_time, JSON_OBJECT('cod_name', cod_name, 'err_message', err_message, 'sch_name', sch_name, 'tab_name', tab_name, 'col_name', col_name) as stats
		)
        SELECT step_name, start_time, diff_time, stats
        FROM CTE_Stats;
        
        SET sch_name = IF(LENGTH(sch_name) > 0, sch_name, 'DCS_DataCenter');
        INSERT INTO MonDB.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
        SELECT sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, CURRENT_TIMESTAMP(4) as end_time
		FROM Temp_PerformanceStats;
	END;
    
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoveredDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoverDeviceByBet;
    DROP TEMPORARY TABLE IF EXISTS Temp_PerformanceStats;
    #==============================================
    
    SET call_time = CURRENT_TIMESTAMP(4);
    
    CREATE TEMPORARY TABLE Temp_PerformanceStats(
		step_id int auto_increment primary key,
        step_name varchar(100),
		start_time timestamp(4),
        diff_time int,
        stats json
    ) ENGINE = InnoDB;
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_Transaction(
		 TransID				BIGINT	UNSIGNED PRIMARY KEY
		, AccountID				BIGINT	UNSIGNED
		, SubscriberID			INT
        , UserAgentKey			VARCHAR(32)
		, DeviceCode			VARCHAR(32)
		, FingerprintCode		VARCHAR(692) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , FingerprintMoreInfo	VARCHAR(250) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, CreatedDate			DATETIME
		, TransTime				TIMESTAMP(4) 
        , INDEX 				IX_Temp_Transaction_DeviceCode(DeviceCode)
        , INDEX 				IX_Temp_Transaction_AccountID(AccountID, DeviceCode, FingerprintCode)
	) ENGINE = MEMORY
    ;
    
	#========GET INPUT DATA===========================
    set start_time  = CURRENT_TIMESTAMP(4);
	INSERT INTO Temp_Transaction(TransID, AccountID, SubscriberID, UserAgentKey, DeviceCode, CreatedDate, TransTime,  FingerprintCode, FingerprintMoreInfo)
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
		,  (CASE WHEN tmpTrans.FingerprintCode ="null" THEN NULL ELSE tmpTrans.FingerprintCode END) AS FingerprintCode
		,  (CASE WHEN tmpTrans.FingerprintMoreInfo ="null" THEN NULL ELSE tmpTrans.FingerprintMoreInfo END) AS FingerprintMoreInfo
	FROM DCS_DataCenter.Transaction tmpTrans
	INNER JOIN CTE_Trans t ON tmpTrans.TransId = t.TransId
	FOR UPDATE SKIP LOCKED
    ;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'GET_DATA' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('batchCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
	IF rowCount = 0 then
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
    
    SET start_time = CURRENT_TIMESTAMP(4);
    INSERT INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, FirstTransID, FirstDeviceCode)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT DISTINCT dc.DeviceID, dc.DeviceCode, dc.DeviceCodeID, dv.FirstTransID, dv.FirstDeviceCode
    FROM CTE_DeviceCode tts
    INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode
    INNER JOIN DCS_DataCenter.Device dv ON dv.DeviceID = dc.DeviceID
    ;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'EXISTS_DEVICE' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    #recover step
    CREATE TEMPORARY TABLE Temp_RecoveredDevice(
		AccountID			BIGINT
        , DeviceCode   		VARCHAR(32)
		, FingerprintCode	VARCHAR(2000)
        , DeviceID			BIGINT DEFAULT 0
        , RecoverCode 		VARCHAR(32)
	) ENGINE = MEMORY;
    
    # Recover DeviceID by Association - Level 1
    SET start_time = CURRENT_TIMESTAMP(4);
    INSERT Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID)
    WITH CTE_Assosiation AS (
		SELECT DISTINCT AccountID, DeviceCode, FingerprintCode 
        FROM Temp_Transaction tts
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice td WHERE td.DeviceCode = tts.DeviceCode)
	)
    SELECT AccountID, DeviceCode, FingerprintCode, DeviceID
    FROM (
		SELECT tts.AccountID, tts.DeviceCode, tts.FingerprintCode, MIN(ass.DeviceID) AS DeviceID
			, MAX(DCS_DC_IsListsMatchByItem(';',tts.FingerprintCode, df.FingerprintCode)) AS IsMatched
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
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'RECOVER_DEVICE_L1' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
   
	# UPDATE recover level 2
	CREATE TEMPORARY TABLE Temp_RecoverDeviceByBet (
		TransID				BIGINT	UNSIGNED PRIMARY KEY
		, AccountID				BIGINT	UNSIGNED
		, DeviceCode			VARCHAR(32)
		, FingerprintCode		VARCHAR(692)
        , INDEX 				IX_Temp_RecoverDeviceByBet_AccountID(AccountID, DeviceCode, FingerprintCode)
        #, INDEX 				IX_Temp_RecoverDeviceByBet_DeviceCode(DeviceCode)
    ) engine=MEMORY;
    
    SET start_time = CURRENT_TIMESTAMP(4);
    INSERT INTO Temp_RecoverDeviceByBet(TransID, AccountID, DeviceCode, FingerprintCode)
	SELECT TransID, AccountID, DeviceCode, FingerprintCode 
	FROM Temp_Transaction tts
	WHERE tts.DeviceCode IS NOT NULL
		AND tts.FingerprintCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = tts.DeviceCode)
		AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = tts.DeviceCode)
	;
    
	INSERT IGNORE INTO Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID, RecoverCode)
    SELECT AccountID, DeviceCode, FingerprintCode, DeviceID, RecoverCode
    FROM (
		SELECT rb.AccountID, rb.DeviceCode, rb.FingerprintCode, 9999 AS DeviceID, tts.DeviceCode AS RecoverCode
			, row_number() over (partition by rb.AccountID, rb.DeviceCode, rb.FingerprintCode order by tts.TransTime asc) as rowIdx
		FROM Temp_Transaction tts
		INNER JOIN Temp_RecoverDeviceByBet rb ON rb.AccountID = tts.AccountID 
			AND rb.DeviceCode <> tts.DeviceCode
			AND DCS_DC_IsListsMatchByItem(';',tts.FingerprintCode, rb.FingerprintCode) = 1
		WHERE rb.TransID > tts.TransID
    ) as p
    WHERE rowIdx = 1
	;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'RECOVER_DEVICE_L2' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    SET insertionTime = CURRENT_TIMESTAMP(4);
    # INSERT new Devices
    SET start_time = CURRENT_TIMESTAMP(4);
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
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'NEW_DEVICE' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    # INSERT new DeviceCode
    SET start_time = CURRENT_TIMESTAMP(4);
    # NEW code - new DeviceID
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT t.DeviceCode
			, MIN(t.TransID) AS FirstTransID
			, MIN(t.TransTime) AS CreatedTime
			, MIN(t.CreatedDate) AS CreatedDate
            , insertionTime	AS InsertTime
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = t.DeviceCode)
			AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    )
    SELECT tts.DeviceCode
		, dv.DeviceID
		, tts.FirstTransID
		, tts.CreatedTime
		, tts.CreatedDate
		, tts.InsertTime
	FROM CTE_DeviceCode AS tts
	INNER JOIN DCS_DataCenter.Device dv ON dv.FirstDeviceCode = tts.DeviceCode
    ;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'NEW_DEVICECODE_L1' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    #NEW code vs Old DeviceID
    SET start_time = CURRENT_TIMESTAMP(4);
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
    CTE_NewCodeOldDeviceID AS (SELECT DISTINCT DeviceCode, DeviceID, RecoverCode FROM Temp_RecoveredDevice)
    SELECT tts.DeviceCode
		, IF(dr.DeviceID <> 9999 , dr.DeviceID, dc.DeviceID) AS DeviceID
		, tts.FirstTransID
		, tts.CreatedTime
		, tts.CreatedDate
		, tts.InsertTime
	FROM CTE_DeviceCode AS tts
	INNER JOIN CTE_NewCodeOldDeviceID dr ON dr.DeviceCode = tts.DeviceCode
    LEFT JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = dr.RecoverCode
	;
	GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'NEW_DEVICECODE_L2' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    # MERGE existed, recovered vs incoming devices
    SET start_time = CURRENT_TIMESTAMP(4);
    INSERT IGNORE INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, FirstTransID, FirstDeviceCode, IsNew)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT dc.DeviceID, tts.DeviceCode, dc.DeviceCodeID, dv.FirstTransID, dv.FirstDeviceCode, 1 AS IsNew
    FROM  CTE_DeviceCode tts
    INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode
    INNER JOIN DCS_DataCenter.Device dv ON dv.DeviceID = dc.DeviceID
    ;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'EXISTS_DEVICE_MEGRE' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    # INSERT new DeviceFingerprint
    SET start_time = CURRENT_TIMESTAMP(4);
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
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'NEW_FingerprintCode' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
   
    # INSERT new Association
    SET start_time = CURRENT_TIMESTAMP(4);
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
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'NEW_Association' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    # UPDATE back Transaction
    SET start_time = CURRENT_TIMESTAMP(4);
    UPDATE DCS_DataCenter.Transaction AS ts
    INNER JOIN Temp_Transaction tts	ON tts.TransID = ts.TransID
	LEFT JOIN Temp_ExistedDevice de ON de.DeviceCode = tts.DeviceCode
    LEFT JOIN Temp_RecoveredDevice dr ON dr.AccountID = tts.AccountID 
		AND dr.DeviceCode = tts.DeviceCode 
        AND dr.FingerprintCode = tts.FingerprintCode
	LEFT JOIN DCS_DataCenter.DeviceFingerprint df ON df.DeviceID = de.DeviceID AND df.FingerprintCode = tts.FingerprintCode
	SET	ts.DeviceID 				= CASE WHEN dr.DeviceID > 0 and dr.DeviceID <> 9999 then dr.DeviceID else de.DeviceID end
		, ts.FirstDeviceCode 		= de.FirstDeviceCode
		, ts.DeviceCodeID 			= de.DeviceCodeID
		, ts.DeviceFingerprintID 	= df.DeviceFingerprintID
		, ts.DeviceStatus 			= CASE 
										WHEN de.DeviceID > 0 AND tts.TransId > de.FirstTransID and dr.DeviceID IS NULL THEN vrDeviceStatusOld
										WHEN dr.DeviceID > 0 THEN vrDeviceStatusRecover 
										ELSE vrDeviceStatusNew 
									END
    ;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'UPDATE_Transaction' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
	# END
    
    /*****MOVE TRans competed to Trans07****************************************************/
	SET start_time = CURRENT_TIMESTAMP(4);
    INSERT IGNORE INTO  DCS_DataCenter.Transaction07(TransID, LoginName, TransTime, SubscriberID, AccountID
	, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
	, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)      
	SELECT 	ts.TransID, ts.LoginName, ts.TransTime, ts.SubscriberID, ts.AccountID
			, ts.URLID, ts.DeviceCodeID, ts.DeviceID, ts.FirstDeviceCode, ts.DeviceStatus, ts.DeviceFingerprintID
			, ts.UserAgentKey, ts.IP, ts.IPID, ts.ActionResultID, ts.Flagged, ts.PluginID, ts.TransStatus, ts.CreatedDate, ts.InsertTime
	FROM DCS_DataCenter.Transaction AS ts
	INNER JOIN	Temp_Transaction AS tmp_rm
				ON	ts.TransID = tmp_rm.TransID
	WHERE		ts.DeviceID IS NOT NULL;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'MOVE_Transaction07' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
    # INSERT perf counter
    INSERT INTO MonDB.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
	SELECT sch_name, sp_name, step_id, step_name, st.start_time, diff_time, stats, call_time, CURRENT_TIMESTAMP(4) as end_time
	FROM Temp_PerformanceStats st;
END