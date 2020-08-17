CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_TransformData_Device_Insert_Bobby`(IN ip_TransJson LONGTEXT)
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
	
    SET 	insertionTime = CURRENT_TIMESTAMP(4);	
	
	#======GET DATA FROM RAW TRANSACTION===========================
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
	CREATE TEMPORARY TABLE Temp_Transaction(
		 TransID				BIGINT	UNSIGNED
		, AccountID				BIGINT	UNSIGNED
		, SubscriberID			INT
        , UserAgentKey			VARCHAR(32)
		, DeviceCode			VARCHAR(32)
		, FingerprintCode		VARCHAR(2000)
        , FingerprintMoreInfo	TEXT	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
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
        #, INDEX			IX_Temp_Transaction_DeviceID(DeviceID,FingerprintCode)
	) 
    #ENGINE = MEMORY
    ;
    
	#========GET INPUT DATA===========================
	INSERT INTO Temp_Transaction(TransID, AccountID, SubscriberID, UserAgentKey, DeviceCode, CreatedDate, TransTime,  FingerprintCode, FingerprintMoreInfo, DeviceStatus)
    SELECT TransID
			, AccountID
			, SubscriberID
            , (CASE WHEN tmpTrans.UserAgentKey ="null" THEN NULL ELSE tmpTrans.UserAgentKey END) AS UserAgentKey
			, (CASE WHEN tmpTrans.DeviceCode ="null" THEN NULL ELSE tmpTrans.DeviceCode END) AS DeviceCode
            , CreatedDate
			, TransTime
            ,  (CASE WHEN tmpTrans.FingerprintCode ="null" THEN NULL ELSE tmpTrans.FingerprintCode END) FingerprintCode
			,  (CASE WHEN tmpTrans.FingerprintMoreInfo ="null" THEN NULL ELSE tmpTrans.FingerprintMoreInfo END)FingerprintMoreInfo
            , vrDeviceStatusNew AS DeviceStatus
			 FROM
			   JSON_TABLE(
				ip_TransJson,
				 "$[*]" COLUMNS(
				  TransID 			BIGINT UNSIGNED PATH "$.TransId"         
				, AccountID					INT UNSIGNED PATH "$.AccountId"
				, SubscriberID				INT PATH "$.SubscriberId"
                , UserAgentKey 				VARCHAR(32) PATH "$.UserAgentKey"         
				, DeviceCode				VARCHAR(32) PATH "$.DeviceCode"
                , TransTime				TIMESTAMP(4) PATH "$.TransTime"
				, CreatedDate			DATETIME PATH "$.CreatedDate"	
                , FingerprintCode			VARCHAR(2000) PATH "$.FingerprintCode"
                , FingerprintMoreInfo		TEXT CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.FingerprintMoreInfo"                			
				 )
			   ) AS  tmpTrans ;
               
	#select distinct devicecode, UserAgentKey from Temp_Transaction where devicecode is not null;
    SET batchCount = (SELECT COUNT(1) FROM Temp_Transaction);
    #SELECT batchCount AS batchCount;
    
    # START
    -- existed device
    CREATE TEMPORARY TABLE Temp_ExistedDevice(
		DeviceID				BIGINT PRIMARY KEY
        , DeviceCode   			VARCHAR(32) UNIQUE
        , DeviceCodeID  		BIGINT
        , FirstTransID  		BIGINT
        , DeviceFingerprintID 	BIGINT
        , FirstDeviceCode 		VARCHAR(32)
	) ENGINE = MEMORY;
    
    INSERT INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, FirstTransID, FirstDeviceCode)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT dv.DeviceID, tts.DeviceCode, dc.DeviceCodeID, dv.FirstTransID, dv.FirstDeviceCode
    FROM CTE_DeviceCode tts
	INNER JOIN DCS_DataCenter.Device dv ON dv.FirstDeviceCode = tts.DeviceCode
    INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode
    ;
    #select * from Temp_ExistedDevice;
    
    #recover step
    CREATE TEMPORARY TABLE Temp_RecoveredDevice(
		AccountID			BIGINT
        , DeviceCode   		VARCHAR(32)
		, FingerprintCode	VARCHAR(2000)
        , DeviceID			BIGINT
	) ENGINE = MEMORY;
    
    # Recover DeviceID by Association
    INSERT Temp_RecoveredDevice(AccountID, DeviceCode, FingerprintCode, DeviceID)
    WITH CTE_Assosiation AS (
		SELECT DISTINCT AccountID, DeviceCode, FingerprintCode 
        FROM Temp_Transaction tts
        WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice td WHERE td.DeviceCode = tts.DeviceCode)
	)
    SELECT AccountID, DeviceCode, FingerprintCode, DeviceID
    FROM (
		SELECT tts.AccountID, tts.DeviceCode, tts.FingerprintCode, MIN(ass.DeviceID) AS DeviceID
			, MIN(DCS_DC_ISLISTSMATCHBYITEM(';',tts.FingerprintCode, df.FingerprintCode)) AS IsMatched
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
    #select * from Temp_RecoveredDevice;
   
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
	
    # INSERT new DeviceCode
    INSERT IGNORE INTO DCS_DataCenter.DeviceCode(DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
    SELECT tts.DeviceCode
			, dv.DeviceID
			, MIN(tts.TransID) AS FirstTransID
			, MIN(tts.TransTime) AS CreatedTime
			, MIN(tts.CreatedDate) AS CreatedDate
			, insertionTime	AS InsertTime
	From	Temp_Transaction AS tts
	INNER JOIN DCS_DataCenter.Device dv ON dv.FirstDeviceCode = tts.DeviceCode
	WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedDevice de WHERE de.DeviceCode = tts.DeviceCode)
	GROUP BY tts.DeviceCode, dv.DeviceID
	;
	
    # MERGE existed, recoverd vs inserted devices
    INSERT IGNORE INTO Temp_ExistedDevice (DeviceID, DeviceCode, DeviceCodeID, FirstTransID, FirstDeviceCode)
    WITH CTE_DeviceCode AS (SELECT DISTINCT DeviceCode FROM Temp_Transaction)
    SELECT dc.DeviceID, tts.DeviceCode, dc.DeviceCodeID, dv.FirstTransID, dv.FirstDeviceCode
    FROM  CTE_DeviceCode tts
    INNER JOIN DCS_DataCenter.DeviceCode dc ON dc.DeviceCode = tts.DeviceCode
    INNER JOIN DCS_DataCenter.Device dv ON dv.DeviceID = dc.DeviceID
    ;
    
    # INSERT new DeviceFingerprint
	INSERT IGNORE INTO DCS_DataCenter.DeviceFingerprint(FingerprintCode, DeviceID, FingerprintMoreInfo, CreatedTime, CreatedDate, InsertTime)
	SELECT tts.FingerprintCode
            , de.DeviceID
            , MIN(tts.FingerprintMoreInfo) AS FingerprintMoreInfo
            , MIN(tts.TransTime) AS CreatedTime
            , MIN(tts.CreatedDate) AS CreatedDate
            , insertionTime	AS InsertTime
    FROM	Temp_Transaction AS tts
    INNER JOIN Temp_ExistedDevice de ON de.DeviceCode = tts.DeviceCode
    WHERE	tts.FingerprintCode IS NOT NULL
    GROUP BY tts.FingerprintCode, de.DeviceID
    ;    
    
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
    
 
    # UPDATE back Transaction
    UPDATE DCS_DataCenter.Transaction AS ts
    INNER JOIN Temp_Transaction tts	ON tts.TransID = ts.TransID
	LEFT JOIN Temp_ExistedDevice de ON de.DeviceCode = tts.DeviceCode
    LEFT JOIN Temp_RecoveredDevice dr ON dr.AccountID = tts.AccountID  AND dr.FingerprintCode = tts.FingerprintCode
	SET	ts.DeviceID 				= de.DeviceID
		, ts.FirstDeviceCode 		= de.FirstDeviceCode
		, ts.DeviceCodeID 			= de.DeviceCodeID
		, ts.DeviceFingerprintID 	= de.DeviceFingerprintID
		, ts.DeviceStatus 			= CASE 
										WHEN tts.TransId > de.FirstTransID THEN vrDeviceStatusOld
										WHEN dr.DeviceID > 0 THEN vrDeviceStatusRecover 
										ELSE vrDeviceStatusNew 
									END
	;
	# END
        
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_RecoveredDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    #==============================================
END