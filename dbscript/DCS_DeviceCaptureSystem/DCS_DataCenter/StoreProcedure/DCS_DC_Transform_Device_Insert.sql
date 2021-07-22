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
            - 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]

	    Param's Explanation (filtered by):
	*/

	DECLARE lv_DeviceStatusNew			TINYINT DEFAULT 1;			# New Device
	DECLARE lv_DeviceStatusOld			TINYINT DEFAULT 2;			# Old Device
	DECLARE lv_DeviceStatusRecover		TINYINT DEFAULT 3;			# Recover Device
    
    DECLARE lv_Code                     CHAR(5) DEFAULT '00000';
    DECLARE lv_ErrNo                    INT DEFAULT 0;
    DECLARE lv_CodeName                 VARCHAR(10) DEFAULT '';
	DECLARE lv_ErrMessage               VARCHAR(255) DEFAULT '';
    DECLARE lv_InfoNo                   INT DEFAULT 0;
    DECLARE lv_InfoMessage              VARCHAR(255) DEFAULT '';
	DECLARE lv_DBName                   VARCHAR(128) DEFAULT 'DCS_DataCenter';
    DECLARE lv_TableName                VARCHAR(128) DEFAULT '';
    DECLARE lv_ColumnName               VARCHAR(128) DEFAULT '';
    DECLARE lv_SPName                   VARCHAR(128) DEFAULT 'DCS_DC_Transform_Device_Insert';
	
    # STATS count
    DECLARE lv_InsertionTime    TIMESTAMP(4);
	DECLARE	lv_BatchCount       INT;
    DECLARE	lv_RowCount         INT;
    
    # Perf stats
    DECLARE lv_CallTime         TIMESTAMP(4);
    DECLARE lv_StartTime        TIMESTAMP(4);
    
    # ERROR handler
    DECLARE CONTINUE HANDLER FOR 1062
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			    lv_InfoMessage    = MESSAGE_TEXT
			,   lv_CodeName       = RETURNED_SQLSTATE
            ,   lv_InfoNo         = MYSQL_ERRNO;
    END;
    
    DECLARE CONTINUE HANDLER FOR SQLWARNING
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			    lv_InfoMessage      = MESSAGE_TEXT
			,   lv_CodeName         = RETURNED_SQLSTATE
            ,   lv_InfoNo           = MYSQL_ERRNO;
    END;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET STACKED DIAGNOSTICS CONDITION 1	
			    lv_ErrMessage   = MESSAGE_TEXT
            ,   lv_ErrNo        = MYSQL_ERRNO
            ,   lv_CodeName     = RETURNED_SQLSTATE
            ,   lv_DBName       = SCHEMA_NAME
            ,   lv_TableName    = TABLE_NAME
            ,   lv_ColumnName   = COLUMN_NAME;
		
        INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
		WITH CTE_Stats AS (
			SELECT  CONCAT('ERROR_',lv_ErrNo) AS step_name
                ,   lv_StartTime AS start_time
                ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4) ) / 1000 AS diff_time
                ,   JSON_OBJECT('cod_name', lv_CodeName, 'err_message', lv_ErrMessage, 'sch_name', lv_DBName, 'tab_name', lv_TableName, 'col_name', lv_ColumnName) AS stats
		)
        SELECT  step_name
            ,   start_time
            ,   diff_time
            ,   stats
        FROM CTE_Stats;
        
        SET lv_DBName = IF(LENGTH(lv_DBName) > 0, lv_DBName, 'DCS_DataCenter');
        INSERT INTO MonDB.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
        SELECT  lv_DBName
            ,   lv_SPName
            ,   step_id
            ,   step_name
            ,   start_time
            ,   diff_time
            ,   stats
            ,   lv_CallTime
            ,   CURRENT_TIMESTAMP(4) AS end_time
		FROM Temp_PerformanceStats;
	END;
    
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoveredDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoverDeviceByBet;
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_PerformanceStats;
    #==============================================
    
    SET lv_CallTime = CURRENT_TIMESTAMP(4);
    
    CREATE TEMPORARY TABLE Temp_PerformanceStats(
		    step_id         INT SIGNED AUTO_INCREMENT PRIMARY KEY
        ,   step_name       VARCHAR(100)
		,   start_time      TIMESTAMP(4)
        ,   diff_time       INT
        ,   stats           VARCHAR(1000)
    ) ENGINE = MEMORY;
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_Transaction(
		    TransID				    BIGINT	UNSIGNED PRIMARY KEY
		,   AccountID				BIGINT	UNSIGNED
		,   SubscriberID			INT
        ,   UserAgentKey			VARCHAR(32)
		,   DeviceCode			    VARCHAR(32) 
		,   FingerprintCode		    VARCHAR(620)
        ,   FingerprintMoreInfo	    VARCHAR(250)
		,   CreatedDate			    DATETIME
		,   TransTime				TIMESTAMP(4) 
        ,   DeviceCodeID			BIGINT UNSIGNED
        ,   DeviceID				BIGINT UNSIGNED DEFAULT 0
        ,   FirstDeviceCode		    VARCHAR(32)
        ,   DeviceStatus			TINYINT
        ,   DeviceFingerprintID	    BIGINT UNSIGNED
        ,   INDEX 				IX_Temp_Transaction_DeviceCode(DeviceCode)
        ,   INDEX 				IX_Temp_Transaction_AccountID(AccountID, DeviceCode, FingerprintCode)
	) ENGINE = MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    
	#========GET INPUT DATA===========================
    SET lv_StartTime  = CURRENT_TIMESTAMP(4);
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
    SELECT  t.TransID
		,   AccountID
		,   SubscriberID
		,   (CASE WHEN tmpTrans.UserAgentKey ="null" THEN NULL ELSE tmpTrans.UserAgentKey END) AS UserAgentKey
		,   (CASE WHEN tmpTrans.DeviceCode ="null" THEN NULL ELSE tmpTrans.DeviceCode END) AS DeviceCode
		,   CreatedDate
		,   TransTime
		,  (CASE WHEN tmpTrans.FingerprintCode ="null" THEN NULL ELSE tmpTrans.FingerprintCode END) AS FingerprintCode
		,  (CASE WHEN tmpTrans.FingerprintMoreInfo ="null" THEN NULL ELSE tmpTrans.FingerprintMoreInfo END) AS FingerprintMoreInfo
	FROM DCS_DataCenter.Transaction tmpTrans
	    INNER JOIN CTE_Trans t ON tmpTrans.TransId = t.TransId
    ORDER BY t.TransId ASC;

    GET DIAGNOSTICS lv_BatchCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'GET_DATA' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime
            ,   CURRENT_TIMESTAMP(4)) / 1000 AS diff_time, JSON_OBJECT('batchCount', lv_BatchCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
	IF lv_BatchCount = 0 THEN
	    SIGNAL SQLSTATE '45000'
	    SET MESSAGE_TEXT = 'ERROR: Does not exist trans to process', MYSQL_ERRNO = 1001;
    END IF;
    
    # START
    -- existed device
    CREATE TEMPORARY TABLE Temp_ExistedDevice(
		    DeviceID				BIGINT NOT NULL
        ,   DeviceCode   			VARCHAR(32) NOT NULL
        ,   DeviceCodeID  		    BIGINT NOT NULL
        ,   FirstTransID  		    BIGINT
        ,   FirstDeviceCode 		VARCHAR(32)
        ,   IsNew					TINYINT DEFAULT 0
        ,   PRIMARY KEY 			PK_Temp_ExistedDevice(DeviceCode, DeviceID)
	) ENGINE = MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    #explain
    INSERT INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT  dc.DeviceID
        ,   dc.DeviceCode
        ,   dc.DeviceCodeID
    FROM CTE_DeviceCode tts
        INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode;

    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'EXISTS_DEVICE' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime
            ,   CURRENT_TIMESTAMP(4)) / 1000 AS diff_time, JSON_OBJECT('rowCount', lv_RowCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
    #recover steps
    CREATE TEMPORARY TABLE Temp_RecoveredDevice(
		    AccountID			BIGINT UNSIGNED
        ,   DeviceCode   		VARCHAR(32)
		,   FingerprintCode	    VARCHAR(620)
        ,   DeviceID			BIGINT UNSIGNED
        ,   RecoverCode 		VARCHAR(32)
        ,   PRIMARY KEY 		PK_Temp_RecoveredDevice(AccountID, DeviceCode,FingerprintCode)
        ,   INDEX 			    Temp_RecoveredDevice_Recover(DeviceCode, DeviceID, RecoverCode)
	) ENGINE = MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    
    # Recover DeviceID by Association - Level 1
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    INSERT INTO Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID)
    WITH CTE_Assosiation AS (
		SELECT  DISTINCT 
                AccountID
            ,   DeviceCode
            ,   FingerprintCode 
        FROM Temp_Transaction tts
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice td WHERE td.DeviceCode = tts.DeviceCode)
	)
    SELECT  tts.AccountID
        ,   tts.DeviceCode
        ,   tts.FingerprintCode
        ,   rc.DeviceID
    FROM CTE_Assosiation tts,
    LATERAL (
		SELECT ass.DeviceID
        FROM DCS_DataCenter.Association AS ass
            INNER JOIN	DCS_DataCenter.DeviceFingerprint AS df  ON ass.DeviceID = df.DeviceID
        WHERE ass.AccountID = tts.AccountID
			AND DCS_DC_IsListsMatchByItem(';',tts.FingerprintCode, df.FingerprintCode) = 1
		ORDER BY ass.DeviceID ASC
        LIMIT 1
    ) AS rc;

    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'RECOVER_DEVICE_L1' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 AS diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
   
	# UPDATE recover level 2 from incoming deviceid   
    CREATE TEMPORARY TABLE Temp_RecoverDeviceByBet(
		    TransID				BIGINT PRIMARY KEY
        ,   AccountID			BIGINT UNSIGNED
        ,   DeviceCode		    VARCHAR(32)
        ,   FingerprintCode 	VARCHAR(620)
        ,   INDEX 			    IX_RecoverDeviceByBet_Recover(AccountID,DeviceCode,FingerprintCode)
    ) ENGINE = MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
	
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    INSERT INTO Temp_RecoverDeviceByBet(TransID, AccountID, DeviceCode, FingerprintCode )
    SELECT  TransID
        ,   AccountID
        ,   DeviceCode
        ,   FingerprintCode 
	FROM Temp_Transaction tts
	WHERE tts.DeviceCode IS NOT NULL
		AND tts.FingerprintCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = tts.DeviceCode)
		AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = tts.DeviceCode);

    INSERT IGNORE INTO Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID, RecoverCode)
    SELECT  rb.AccountID
        ,   rb.DeviceCode
        ,   rb.FingerprintCode
        ,   rd.DeviceID
        ,   rd.RecoverCode
    FROM Temp_RecoverDeviceByBet rb,
    LATERAL (
		SELECT CASE WHEN rb.DeviceCode = ts.DeviceCode THEN 1 ELSE 0 END AS DeviceID
			, ts.DeviceCode AS RecoverCode
        FROM Temp_Transaction ts
        WHERE rb.AccountID = ts.AccountID
			AND rb.TransId > ts.TransId
			AND ( rb.DeviceCode = ts.DeviceCode #--> exists from incoming deviceid
				OR (rb.DeviceCode <> ts.DeviceCode	AND DCS_DC_IsListsMatchByItem(';',ts.FingerprintCode, rb.FingerprintCode) = 1) #--> recover from incoming deviceid
			)
		ORDER BY ts.TransId ASC
        LIMIT 1
    ) AS rd
    WHERE rd.DeviceID = 0; #--> just get recover case
    
    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'RECOVER_DEVICE_L2' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 AS diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
    SET lv_InsertionTime = CURRENT_TIMESTAMP(4);
    # INSERT new Devices
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    INSERT IGNORE INTO DCS_DataCenter.Device(FirstDeviceCode, UserAgentKey, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    SELECT 	tts.DeviceCode
		,   tts.UserAgentKey
		,   MIN(tts.TransID) AS FirstTransID
		,   MIN(tts.TransTime) AS CreatedTime
		,   MIN(tts.CreatedDate) AS CreatedDate
		,   lv_InsertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
    WHERE tts.DeviceCode IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = tts.DeviceCode)
		AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = tts.DeviceCode) 
    GROUP BY tts.DeviceCode, tts.UserAgentKey;
    
    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'NEW_DEVICE' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 AS diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount, 'warning', lv_InfoMessage, 'code', lv_InfoNo, 'state', lv_CodeName) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
    # INSERT new DeviceCode
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    # NEW code - new DeviceID
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT  t.DeviceCode
			,   MIN(t.TransID) AS FirstTransID
			,   MIN(t.TransTime) AS CreatedTime
			,   MIN(t.CreatedDate) AS CreatedDate
            ,   lv_InsertionTime	AS InsertTime
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = t.DeviceCode)
			AND NOT EXISTS (SELECT 1 FROM Temp_RecoveredDevice dr WHERE dr.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    )
    SELECT  tts.DeviceCode
		,   dv.DeviceID
		,   tts.FirstTransID
		,   tts.CreatedTime
		,   tts.CreatedDate
		,   tts.InsertTime
	FROM CTE_DeviceCode AS tts
	    INNER JOIN DCS_DataCenter.Device dv ON dv.FirstDeviceCode = tts.DeviceCode;

    
    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'NEW_DEVICECODE_L1' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 AS diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
    #NEW code vs Old DeviceID
    SET lv_StartTime = CURRENT_TIMESTAMP(4);

    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT  t.DeviceCode
			,   MIN(t.TransID) AS FirstTransID
			,   MIN(t.TransTime) AS CreatedTime
			,   MIN(t.CreatedDate) AS CreatedDate
            ,   lv_InsertionTime AS InsertTime
		FROM Temp_Transaction AS t
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = t.DeviceCode)
        GROUP BY t.DeviceCode
    ), 
    CTE_NewCodeOldDeviceID AS (
		SELECT  DISTINCT 
                DeviceCode
            ,   DeviceID
            ,   RecoverCode 
         FROM Temp_RecoveredDevice
	)
    SELECT  tts.DeviceCode
		,   IF(dr.DeviceID > 0 , dr.DeviceID, dc.DeviceID) AS DeviceID
		,   tts.FirstTransID
		,   tts.CreatedTime
		,   tts.CreatedDate
		,   tts.InsertTime
	FROM CTE_DeviceCode AS tts
	    INNER JOIN CTE_NewCodeOldDeviceID dr ON dr.DeviceCode = tts.DeviceCode
        LEFT JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = dr.RecoverCode AND dc.DeviceID > 0
    WHERE IF(dr.DeviceID > 0 , dr.DeviceID, dc.DeviceID)  > 0;
	
	GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'NEW_DEVICECODE_L2' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime
            ,   CURRENT_TIMESTAMP(4)) / 1000 AS diff_time, JSON_OBJECT('rowCount', lv_RowCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
    # MERGE existed, recovered vs incoming devices
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    INSERT IGNORE INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, IsNew)
    WITH CTE_DeviceCode AS (
        SELECT  DISTINCT 
                DeviceCode 
        FROM Temp_Transaction
    )
    SELECT  dc.DeviceID
        ,   tts.DeviceCode
        ,   dc.DeviceCodeID
        ,   1 AS IsNew
    FROM  CTE_DeviceCode tts
        INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode;

    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'EXISTS_DEVICE_MEGRE' AS step_name
            ,   lv_StartTime AS  start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime
            ,   CURRENT_TIMESTAMP(4)) / 1000 AS diff_time, JSON_OBJECT('rowCount', lv_RowCount) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
    
    # INSERT new DeviceFingerprint
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
	INSERT IGNORE INTO DCS_DataCenter.DeviceFingerprint(FingerprintCode, DeviceID, FingerprintMoreInfo, CreatedTime, CreatedDate, InsertTime)
    WITH CTE_DeviceCode AS (
		SELECT  DISTINCT 
                DeviceCode
            ,   DeviceID 
        FROM Temp_ExistedDevice
        UNION
        SELECT  DISTINCT 
                DeviceCode
            ,   DeviceID 
        FROM Temp_RecoveredDevice
    )
	SELECT  tts.FingerprintCode
		,   de.DeviceID
		,   MIN(tts.FingerprintMoreInfo) AS FingerprintMoreInfo
		,   MIN(tts.TransTime) AS CreatedTime
		,   MIN(tts.CreatedDate) AS CreatedDate
		,   lv_InsertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
        INNER JOIN CTE_DeviceCode AS de ON de.DeviceCode = tts.DeviceCode
    WHERE tts.FingerprintCode IS NOT NULL
    GROUP BY tts.FingerprintCode, de.DeviceID;
   
    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'NEW_FingerprintCode' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 AS diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount, 'warning', lv_InfoMessage, 'code', lv_InfoNo, 'state', lv_CodeName) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
   
    # INSERT new Association
    SET lv_StartTime = CURRENT_TIMESTAMP(4);
    INSERT IGNORE INTO DCS_DataCenter.Association(DeviceID, AccountID, SubscriberID, CreatedTime, CreatedDate,  InsertTime)
    SELECT  de.DeviceID
		,   tts.AccountID
		,   MIN(tts.SubscriberID) AS SubscriberID
		,   MIN(tts.TransTime) AS CreatedTime
		,   MIN(tts.CreatedDate) AS CreatedDate
		,   lv_InsertionTime	AS InsertTime
    FROM Temp_Transaction AS tts
        INNER JOIN Temp_ExistedDevice de ON de.DeviceCode = tts.DeviceCode
    GROUP BY  de.DeviceID, tts.AccountID;
	
    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'NEW_Association' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 AS diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount, 'warning', lv_InfoMessage, 'code', lv_InfoNo, 'state', lv_CodeName) AS stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
       
    # UPDATE back Temp_ExistedDevice
    SET lv_StartTime = CURRENT_TIMESTAMP(4);

    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDeviceInfo;
    CREATE TEMPORARY TABLE Temp_ExistedDeviceInfo(
		    DeviceID				BIGINT NOT NULL
        ,   FirstTransID  		    BIGINT
        ,   FirstDeviceCode 		VARCHAR(32)
        ,   INDEX 			IX_Temp_ExistedDeviceInfo_DeviceID(DeviceID)
	) ENGINE = MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

    INSERT INTO Temp_ExistedDeviceInfo(DeviceID, FirstTransID, FirstDeviceCode)
    SELECT  de.DeviceID
        ,   dv.FirstTransID
        ,   dv.FirstDeviceCode
    FROM Temp_ExistedDevice AS de
        INNER JOIN DCS_DataCenter.Device dv ON dv.DeviceID = de.DeviceID;

    UPDATE Temp_ExistedDevice AS de
        INNER JOIN Temp_ExistedDeviceInfo dv ON dv.DeviceID = de.DeviceID
    SET     de.FirstTransID = dv.FirstTransID
		,   de.FirstDeviceCode = dv.FirstDeviceCode;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
    CREATE TEMPORARY TABLE Temp_TransactionInfo(
		    TransID				    BIGINT	UNSIGNED 
        ,   DeviceID				BIGINT UNSIGNED DEFAULT 0
        ,   FirstDeviceCode		    VARCHAR(32)
        ,   DeviceCodeID			BIGINT UNSIGNED
        ,   DeviceFingerprintID	    BIGINT UNSIGNED
        ,   DeviceStatus			TINYINT
        ,   INDEX                   IX_Temp_TransactionInfo_TransID(TransID)
	) ENGINE = MEMORY DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

    # UPDATE back Temp_Transaction

    INSERT INTO Temp_TransactionInfo(TransID, DeviceID, FirstDeviceCode, DeviceCodeID, DeviceFingerprintID, DeviceStatus)
    SELECT  tts.TransID
        ,   IF(de.DeviceID > 0, de.DeviceID, tts.DeviceID) AS DeviceID
        ,   IF(de.DeviceID > 0, de.FirstDeviceCode, tts.FirstDeviceCode) AS FirstDeviceCode
        ,   IF(de.DeviceID > 0, de.DeviceCodeID, tts.DeviceCodeID) AS DeviceCodeID
        ,   IF(df.DeviceFingerprintID > 0, df.DeviceFingerprintID, tts.DeviceFingerprintID) AS DeviceFingerprintID
        ,   CASE 
				WHEN de.DeviceID > 0 AND tts.TransId > de.FirstTransID AND dr.DeviceID IS NULL THEN lv_DeviceStatusOld
				WHEN dr.DeviceID > 0 OR dr.RecoverCode IS NOT NULL THEN lv_DeviceStatusRecover
                WHEN de.DeviceID > 0 AND de.IsNew = 1 THEN lv_DeviceStatusNew  
				ELSE tts.DeviceStatus
			END AS DeviceStatus
    FROM Temp_Transaction AS tts
        LEFT JOIN Temp_ExistedDevice AS de ON de.DeviceCode = tts.DeviceCode
        LEFT JOIN Temp_RecoveredDevice AS dr ON dr.AccountID = tts.AccountID  AND dr.DeviceCode = tts.DeviceCode  AND dr.FingerprintCode = tts.FingerprintCode
	    LEFT JOIN DCS_DataCenter.DeviceFingerprint AS df ON df.DeviceID = de.DeviceID AND df.FingerprintCode = tts.FingerprintCode;

    UPDATE Temp_Transaction AS tts
	    INNER JOIN Temp_TransactionInfo AS info ON info.TransID = tts.TransID
	SET	    tts.DeviceID 				=  info.DeviceID
		,   tts.FirstDeviceCode 		=  info.FirstDeviceCode
		,   tts.DeviceCodeID 			=  info.DeviceCodeID
		,   tts.DeviceFingerprintID 	=  info.DeviceFingerprintID
		,   tts.DeviceStatus 			=  info.DeviceStatus;
										   										                                              																		       
    GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT  'UPDATE_Temp_Transaction' AS step_name
            ,   lv_StartTime AS start_time
            ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 as diff_time
            ,   JSON_OBJECT('rowCount', lv_RowCount) as stats
    )
    SELECT  step_name
        ,   start_time
        ,   diff_time
        ,   stats 
    FROM CTE_Stats;
	
    /*****MOVE TRans competed to Trans07****************************************************/
    IF lv_ErrNo = 0 THEN
		SET lv_StartTime = CURRENT_TIMESTAMP(4);
		INSERT IGNORE INTO  DCS_DataCenter.Transaction07(RawTransID, LoginName, TransTime, SubscriberID, AccountID, URLID,DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)
		SELECT 	IFNULL(ts.RawTransID, ts.TransID)
            ,   ts.LoginName
            ,   ts.TransTime
            ,   ts.SubscriberID
            ,   ts.AccountID
            ,   ts.URLID
		    ,   tmp_rm.DeviceCodeID
            ,   tmp_rm.DeviceID
            ,   tmp_rm.FirstDeviceCode
            ,   tmp_rm.DeviceStatus
            ,   tmp_rm.DeviceFingerprintID
		    ,   ts.UserAgentKey
            ,   ts.IP
            ,   ts.IPID
            ,   ts.ActionResultID
            ,   ts.Flagged
            ,   ts.PluginID
            ,   ts.TransStatus
            ,   ts.CreatedDate
            ,   ts.InsertTime
		FROM DCS_DataCenter.Transaction AS ts
		    INNER JOIN Temp_Transaction AS tmp_rm ON	ts.TransID = tmp_rm.TransID
		WHERE tmp_rm.DeviceID IS NOT NULL;

		#DELETE Transaction
		DELETE ts
		FROM DCS_DataCenter.Transaction AS ts
		    INNER JOIN	Temp_Transaction AS tmp_rm ON	ts.TransID = tmp_rm.TransID
		WHERE tmp_rm.DeviceID IS NOT NULL;

		GET DIAGNOSTICS lv_RowCount = ROW_COUNT;
		INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
		WITH CTE_Stats AS (
			SELECT  'MOVE_DELETE_Transaction07' AS step_name
                ,   lv_StartTime AS start_time
                ,   TIMESTAMPDIFF(MICROSECOND, lv_StartTime, CURRENT_TIMESTAMP(4)) / 1000 as diff_time
                ,   JSON_OBJECT('rowCount', lv_RowCount) as stats
		)
		SELECT  step_name
            ,   start_time
            ,   diff_time
            ,   stats 
        FROM CTE_Stats;
	END IF;
	# END transform
    
    # INSERT perf counter
    #INSERT INTO MonDB.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
	#SELECT lv_DBName, lv_SPName, step_id, step_name, st.start_time, diff_time, stats, lv_CallTime, CURRENT_TIMESTAMP(4) as end_time
	#FROM Temp_PerformanceStats st;
END$$

DELIMITER ;
