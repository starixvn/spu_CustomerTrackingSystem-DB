DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_Device_Insert$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_Device_Insert(IN ip_TransJson LONGTEXT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Transform Device Info
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/

	DECLARE vrDeviceStatusNew			TINYINT DEFAULT 1;			# New Device
	DECLARE vrDeviceStatusOld			TINYINT DEFAULT 2;			# Old Device
	DECLARE vrDeviceStatusRecover		TINYINT DEFAULT 3;			# Recover Device
	DECLARE	vrMaxDeviceID				BIGINT;

	### PERFORMANCE START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName	VARCHAR(200) DEFAULT 'DCS_DC_TransformData_Device_Insert' ;
    DECLARE		vrStepID	INT;
	DECLARE 	vrNotes	 	VARCHAR(500);
	DECLARE 	vrStartTime	TIMESTAMP(4);
	DECLARE		vrEndTime 	TIMESTAMP(4);
	DECLARE		vrDuration 	BIGINT;
	
    DECLARE		vrFromID	BIGINT;
    DECLARE		vrToID		BIGINT;
    DECLARE		vrBegin		BIGINT;
    DECLARE		vrTotalRecord		INT;
  
    SET		vrExecKey = CRC32((UUID_Short()));
    
    SET		vrNotes = 'Insert(DC, DC, ASCT) and Update DeviceInfo to Transaction ';
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    SET 	vrStepID = 1;
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);    
	### PERFORMANCE  END
	
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	CREATE TEMPORARY TABLE Temp_InputTrans 
	(	
		TransID					BIGINT			UNSIGNED
		, AccountID				BIGINT			UNSIGNED
		, SubscriberID			INT
        , UserAgentKey			VARCHAR(32)		
		, DeviceCode			VARCHAR(64)
	);
    
	#========GET INPUT DATA===========================
	INSERT INTO Temp_InputTrans(
				TransID 
				, AccountID
				, SubscriberID
                , UserAgentKey
				, DeviceCode
				)
	SELECT TransID
			, AccountID
			, SubscriberID
            , UserAgentKey
			, DeviceCode
			 FROM
			   JSON_TABLE(
				ip_TransJson,
				 "$[*]" COLUMNS(
				  TransID 			BIGINT UNSIGNED PATH "$.TransId"         
				, AccountID					BIGINT UNSIGNED PATH "$.AccountId"
				, SubscriberID				INT PATH "$.SubscriberId"
                , UserAgentKey 				VARCHAR(32) PATH "$.UserAgentKey"         
				, DeviceCode				VARCHAR(64) PATH "$.DeviceCode"
				 )
			   ) AS  tmpTrans;
               
	#======GET DATA FROM RAW TRANSACTION===========================
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
	CREATE TEMPORARY TABLE Temp_Transaction(
		 TransID				BIGINT	UNSIGNED
		, AccountID				BIGINT	UNSIGNED
		, SubscriberID			INT
        , UserAgentKey			VARCHAR(32)
		, DeviceCode			VARCHAR(64)
		, FingerprintCode		VARCHAR(1000)
        , FingerprintMoreInfo	TEXT
		
		, PluginID				INT
		, CreatedDate			DATETIME
		, TransTime				DATETIME
		
		, DeviceID				BIGINT	UNSIGNED		NULL
		, DeviceStatus			TINYINT					NULL
		, FirstDeviceCode		VARCHAR(64)				NULL
        , LastDeviceStatus		TINYINT					NULL
        , GroupDeviceCode		VARCHAR(64)				NULL
	);
	  
	INSERT INTO Temp_Transaction(TransID, AccountID, SubscriberID, UserAgentKey, DeviceCode, FingerprintCode, FingerprintMoreInfo, PluginID, CreatedDate, TransTime)
	SELECT 		tit.TransID
				, tit.AccountID
				, tit.SubscriberID
                , tit.UserAgentKey
                , tit.DeviceCode
				, rt.FingerprintCode
                , rt.FingerprintMoreInfo
				, rt.PluginID
				, rt.CreatedDate
				, rt.TransTime
	FROM		Temp_InputTrans						AS tit
	INNER JOIN	DCS_RawTransaction.RawTransaction	AS rt
				ON	tit.TransID = rt.TransID;    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    
	#======DeviceCode EMPTY==================================
	UPDATE	Temp_Transaction AS tts
	SET		tts.DeviceID = 0
			, tts.DeviceStatus = 0
			, tts.FirstDeviceCode = ''
            , tts.LastDeviceStatus = 0
	WHERE	tts.DeviceCode = '';
    
	#=======DeviceCode EXISTING =================================
	UPDATE		Temp_Transaction AS tts
	INNER JOIN	DCS_DataCenter.DeviceCode AS dc
				ON	tts.DeviceCode = dc.DeviceCode
	SET			tts.DeviceID = dc.DeviceID
				, tts.DeviceStatus = (CASE WHEN dc.FirstTransID = tts.TransID THEN dc.FirstStatus ELSE vrDeviceStatusOld END)
				, tts.FirstDeviceCode = dc.FirstDeviceCode
                , tts.GroupDeviceCode = dc.FirstDeviceCode
	WHERE		tts.DeviceID IS NULL;
       
	#======GROUP BY NewDeviceCode=============================
	DROP TEMPORARY TABLE IF EXISTS Temp_NewDeviceCode;
	CREATE TEMPORARY TABLE Temp_NewDeviceCode(
		DeviceCode				VARCHAR(64)
		, MinTransID		BIGINT			UNSIGNED
		, MaxTransID		BIGINT			UNSIGNED
	);

	INSERT INTO Temp_NewDeviceCode(DeviceCode, MinTransID, MaxTransID)
	SELECT	tts.DeviceCode
			, MIN(tts.TransID)
			, MAX(tts.TransID)
	FROM	Temp_Transaction	AS tts
	GROUP BY	tts.DeviceCode;

	#======GET Recover DeviceID==============================    
	
	IF EXISTS (SELECT 1 FROM Temp_Transaction tts WHERE tts.DeviceID IS NULL LIMIT 1)
    THEN		
		UPDATE		Temp_Transaction AS tts    
		INNER JOIN	Temp_NewDeviceCode AS tnc
					ON	tts.TransID = tnc.MinTransID
		INNER JOIN	DCS_DataCenter.Association AS ass
					ON tts.SubscriberID = ass.SubscriberID AND tts.AccountID = ass.AccountID
		INNER JOIN	DCS_DataCenter.Device AS dv
					ON ass.DeviceID = dv.DeviceID
		INNER JOIN	DCS_DataCenter.DeviceFingerprint AS df
					ON  dv.DeviceID = df.DeviceID
					AND	DCS_DC_ISLISTSMATCHBYITEM(';',tts.FingerprintCode, df.FingerprintCode) = 1
		SET			tts.DeviceID = df.DeviceID
					, tts.DeviceStatus = vrDeviceStatusRecover
					, tts.DeviceCode = dv.FirstDeviceCode
                    , tts.GroupDeviceCode = dv.FirstDeviceCode
		WHERE		tts.DeviceID IS NULL;        
	END IF;
	
	#=======Update DeviceStatus: FOR New Device
    IF EXISTS (SELECT 1 FROM Temp_Transaction tts WHERE tts.DeviceID IS NULL)
    THEN
		UPDATE		Temp_Transaction AS tts
		LEFT JOIN	Temp_NewDeviceCode AS tnd
					ON	tts.TransID = tnd.MinTransID
		SET			tts.GroupDeviceCode = tnd.DeviceCode
					, tts.DeviceStatus = (CASE WHEN tnd.DeviceCode IS NOT NULL THEN vrDeviceStatusNew ELSE vrDeviceStatusOld END)
					, tts.FirstDeviceCode = tts.DeviceCode
		WHERE		tts.DeviceID IS NULL;    
	END IF;   
    
	#==========================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction_02;
	CREATE TEMPORARY TABLE Temp_Transaction_02(
		 TransID				BIGINT	UNSIGNED
		, AccountID				BIGINT	UNSIGNED
		, SubscriberID			INT
		, DeviceCode			VARCHAR(64)
		, FingerprintCode		VARCHAR(1000)
		, UserAgentKey			VARCHAR(32)
		, PluginID				INT
		, CreatedDate			DATETIME
		, TransTime				DATETIME
		
		, DeviceID				BIGINT	UNSIGNED		NULL
		, DeviceStatus			TINYINT					NULL
		, FirstDeviceCode		VARCHAR(64)				NULL
        , GroupDeviceCode		VARCHAR(64)				NULL
        
	);

	INSERT INTO Temp_Transaction_02( TransID, AccountID, SubscriberID, DeviceCode, FingerprintCode, UserAgentKey, PluginID, CreatedDate, TransTime, DeviceID, DeviceStatus, FirstDeviceCode, GroupDeviceCode)
	SELECT 		tts.TransID
				, tts.AccountID
				, tts.SubscriberID
				, tts.DeviceCode
				, tts.FingerprintCode
				, tts.UserAgentKey
				, tts.PluginID
				, tts.CreatedDate
				, tts.TransTime
				, tts.DeviceID
				, tts.DeviceStatus
				, tts.FirstDeviceCode
                , tts.GroupDeviceCode
	FROM		Temp_Transaction		AS tts
	INNER JOIN	Temp_NewDeviceCode		AS tnd
				ON tts.TransID = tnd.MinTransID;

	UPDATE 		Temp_Transaction AS tts
	INNER JOIN	Temp_NewDeviceCode	AS tnd
				ON tts.TransID = tnd.MinTransID
	INNER JOIN	Temp_Transaction_02	tts02
				ON	tts02.AccountID = tts.AccountID
					AND tts.TransID > tts02.TransID
					AND DCS_DC_ISLISTSMATCHBYITEM(';',tts.FingerprintCode, tts02.FingerprintCode) = 1
	SET		tts.DeviceStatus = vrDeviceStatusRecover
			, tts.FirstDeviceCode = tts02.DeviceCode
			, tts.GroupDeviceCode	= tts02.DeviceCode;            
	
    TRUNCATE TABLE Temp_Transaction_02;
    
    INSERT INTO Temp_Transaction_02(TransID, AccountID, SubscriberID, DeviceCode, FingerprintCode, UserAgentKey, PluginID, CreatedDate, TransTime, DeviceID, DeviceStatus, FirstDeviceCode)
	SELECT 		tts.TransID
				, tts.AccountID
				, tts.SubscriberID
				, tts.DeviceCode
				, tts.FingerprintCode
				, tts.UserAgentKey
				, tts.PluginID
				, tts.CreatedDate
				, tts.TransTime
				, tts.DeviceID
				, tts.DeviceStatus
				, tts.FirstDeviceCode
	FROM		Temp_Transaction		AS tts
	INNER JOIN	Temp_NewDeviceCode		AS tnd
				ON tts.TransID = tnd.MaxTransID;
    
    UPDATE 		Temp_Transaction AS tts
    INNER JOIN	Temp_Transaction_02 AS tts02
				ON tts.DeviceCode = tts02.DeviceCode
	SET			tts.LastDeviceStatus = tts02.DeviceStatus;
	
    DROP TEMPORARY TABLE Temp_Transaction_02;   
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	#=======Insert New Device    
	INSERT IGNORE INTO	DCS_DataCenter.Device (FirstDeviceCode, UserAgentKey, FirstTransID, CreatedDate, DeviceStatus, InsertTime)
	SELECT		tts.FirstDeviceCode
				, tts.UserAgentKey
				, tts.TransID
				, tts.CreatedDate
				, tts.DeviceStatus
                , CURRENT_TIMESTAMP(4) 		AS InsertTime
	FROM 		Temp_Transaction AS tts
	INNER JOIN	Temp_NewDeviceCode	AS tnd
				ON tts.TransID = tnd.MinTransID
	WHERE		tts.DeviceStatus = vrDeviceStatusNew
    ORDER BY	tts.TransID Desc;  
   
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceMaxID;
    CREATE TEMPORARY TABLE Temp_DeviceMaxID
    (
			DeviceID	BIGINT
            , MaxTransID	BIGINT	
    );
    
	INSERT INTO	Temp_DeviceMaxID(DeviceID,MaxTransID)
    SELECT		tts.DeviceID, Max(tts.TransID)
    FROM		Temp_Transaction tts
    GROUP BY	tts.DeviceID;    
    
	UPDATE		DCS_DataCenter.Device AS dv
    INNER JOIN	Temp_Transaction AS tts
				ON dv.DeviceID = tts.DeviceID
    INNER JOIN	Temp_DeviceMaxID	AS dmi
				ON tts.TransID = dmi.MaxTransID
    SET			dv.DeviceStatus = tts.DeviceStatus;
    
     UPDATE		Temp_Transaction AS tts
    INNER JOIN	DCS_DataCenter.Device AS dv
				ON dv.FirstDeviceCode = tts.DeviceCode
	SET			tts.DeviceID = dv.DeviceID;
    
	INSERT IGNORE INTO	DCS_DataCenter.DeviceCode (DeviceCode, DeviceID, CreatedDate, FirstDeviceCode, LastStatus, FirstTransID, FirstStatus, InsertTime)
	SELECT		tts.DeviceCode
				, tts.DeviceID
				, tts.CreatedDate
				, tts.FirstDeviceCode
				, tts.DeviceStatus			AS LastStatus
                , tts.TransID
                , tts.DeviceStatus
                , CURRENT_TIMESTAMP(4) 		AS InsertTime
	FROM 		Temp_Transaction AS tts
	INNER JOIN	Temp_NewDeviceCode	AS tnd
				ON tts.TransID = tnd.MinTransID
	WHERE		tts.DeviceStatus IN (vrDeviceStatusNew, vrDeviceStatusRecover);
				#AND tts.DeviceID !=0 ;   
  
	UPDATE 		DCS_DataCenter.DeviceCode dc
    INNER JOIN	Temp_Transaction AS tts
				ON tts.DeviceCode = dc.DeviceCode
	INNER JOIN	Temp_NewDeviceCode	AS tnd
				ON tts.TransID = tnd.MaxTransID
	SET			dc.LastStatus = tts.DeviceStatus;	
	
   
    
	INSERT IGNORE INTO DCS_DataCenter.DeviceFingerprint(FingerprintKey, FingerprintCode, FingerprintMoreInfo, UserAgentKey, PluginID, DeviceID, CreatedDate, InsertTime)
    SELECT		MD5(tts.FingerprintCode) AS FingerprintKey
				, tts.FingerprintCode
                , tts.FingerprintMoreInfo
                , tts.UserAgentKey
                , tts.PluginID
                , tts.DeviceID
                , tts.CreatedDate
                , CURRENT_TIMESTAMP(4)	AS InsertTime
    FROM		Temp_Transaction AS tts;
	#WHERE		tts.DeviceID != 0;   

   INSERT IGNORE INTO DCS_DataCenter.Association(AccountID, DeviceID, SubscriberID, CreatedDate, InsertTime)
	SELECT		tts.AccountID
				, tts.DeviceID
                , tts.SubscriberID
                , MIN(tts.CreatedDate)
                , CURRENT_TIMESTAMP(4) AS InsertTime
    FROM		Temp_Transaction AS tts
   
   # WHERE		tts.DeviceID != 0
    GROUP BY 	tts.SubscriberID
				, tts.AccountID
				, tts.DeviceID;   
    
   UPDATE DCS_DataCenter.Transaction ts
   INNER JOIN Temp_Transaction AS tts
				ON	ts.TransID = tts.TransID
   SET		ts.ReferDeviceID = tts.DeviceID
			, ts.ReferDeviceStatus = tts.DeviceStatus
			, ts.ReferDeviceCode = tts.FirstDeviceCode;
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);
	
    SELECT Count(1), Min(tts.TransID), Max(tts.TransID)
    INTO	vrTotalRecord, vrFromID, vrToID
    FROM	Temp_Transaction AS tts;
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrTotalRecord
            , z.FromID = vrFromID
            , z.ToID		= vrToID
    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END
	
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_NewDeviceCode;
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;

    #==============================================
END$$

DELIMITER ;
