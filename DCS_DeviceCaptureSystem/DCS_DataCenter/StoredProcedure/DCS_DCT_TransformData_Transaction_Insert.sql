DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_Transaction_Insert$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_Transaction_Insert(IN ip_FromTransID BIGINT, IN ip_ToTransID BIGINT)
BEGIN
/*
	Created: 20190730@Casey.Huynh
	Task : Insert Transaction
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
*/

	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'DCS_DC_TransformData_Transaction_Insert' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Insert Transaction';		
    SET 	vrStepID = 1;
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime, FromID, ToID)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime, ip_FromTransID, ip_ToTransID);
	
	### PERFORMANCE: END  
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    # =================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;
	CREATE TEMPORARY TABLE IF NOT EXISTS Temp_RawTransaction (
		TransID					BIGINT UNSIGNED NOT NULL
		, LoginName				VARCHAR(100) NOT NULL
        , LoginNameKey			BIGINT	UNSIGNED NOT NULL
		, TransTime				TIMESTAMP(4) NOT NULL
		, SubscriberID			INT NULL
        , AccountID				BIGINT	UNSIGNED NULL
        , SubscriberType		TINYINT	UNSIGNED	NULL
		, URLKey				BIGINT UNSIGNED NULL
		, DeviceCode			VARCHAR(32) NULL COMMENT 'Trans Device Code'
		, DeviceCodeKey			BIGINT NULL
		, FingerprintCodeKey	BIGINT UNSIGNED NULL
		, UserAgentKey			BIGINT NULL
		, IP					VARCHAR(50) NULL
		, ActionResultKey		BIGINT NULL
		, Flagged				SMALLINT NULL COMMENT 'captcha & browserless'
		, PluginID				BIGINT NULL
		, TransStatus			BIT(16) NULL
		, CreatedDate			DATETIME NULL COMMENT 'Date Only' NOT NULL
		, InsertTime			TIMESTAMP(4) NULL
	);
    # =================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TABLE IF NOT EXISTS Temp_Account(
		LoginName				VARCHAR(100) NOT NULL
		, SubscriberID			INT NULL
        , SubscriberType		TINYINT	UNSIGNED	NULL
    );
      
	INSERT INTO Temp_RawTransaction(TransID, LoginName, LoginNameKey, TransTime, SubscriberID, SubscriberType, URLKey, DeviceCode, DeviceCodeKey, FingerprintCodeKey
				, UserAgentKey, IP, ActionResultKey, Flagged, PluginID, TransStatus, CreatedDate)
	SELECT  rt.TransID
			, rt.LoginName
            , CRC32(LOWER(rt.LoginName)) AS LoginNameKey
            , rt.TransTime
            , su.SubscriberID
            , su.SubscriberType
            , CRC32(LOWER(rt.URL)) AS URLKey
            , rt.DeviceCode
            , CRC32(rt.DeviceCode) AS DeviceCodeKey
            , CRC32(rt.FingerprintCode) AS FingerprintCodeKey
            , CRC32(LOWER(rt.UserAgent)) AS UserAgentKey
            , rt.IP
            , CRC32(LOWER(rt.ActionResult)) ActionResultKey
            , 0 AS Flagged
            , rt.PluginID
            , rt.TransStatus
            , rt.CreatedDate
	FROM		DCS_RawTransaction.RawTransaction AS rt
    INNER JOIN	CTS_Admin.Subscriber AS su
				ON	rt.SubscriberName = su.SubscriberName
	WHERE		rt.IsProcessed = 0
				AND rt.TransID BETWEEN ip_FromTransID AND ip_ToTransID;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	         
    INSERT IGNORE INTO DCS_DataCenter.Account(LoginName, LoginNameKey, SubscriberID, SubscriberType, CreatedDate, InsertTime)
    SELECT		trt.LoginName
				, trt.LoginNameKey
				, trt.SubscriberID
				, trt.SubscriberType
				, MIN(trt.CreatedDate)
				, CURRENT_TIMESTAMP(4)	AS InsertTime
    FROM		Temp_RawTransaction AS trt
    GROUP BY	trt.SubscriberID, trt.SubscriberType, trt.LoginName, trt.LoginNameKey;
    
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;      
    UPDATE 		Temp_RawTransaction AS trt
    INNER JOIN	DCS_DataCenter.Account AS ac
				ON trt.LoginNameKey = ac.LoginNameKey
    SET		trt.AccountID = ac.AccountID;  
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    INSERT IGNORE INTO  DCS_DataCenter.Transaction(TransID, LoginName, LoginNameKey, TransTime, SubscriberID, AccountID, URLKey, DeviceCode, DeviceCodeKey
			, FingerprintCodeKey, UserAgentKey, IP, ActionResultKey, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)
   	SELECT 		trt.TransID
				, trt.LoginName
                , trt.LoginNameKey
                , trt.TransTime                
				, trt.SubscriberID
                , trt.AccountID
				, trt.URLKey
                , trt.DeviceCode
                , trt.DeviceCodeKey
                , trt.FingerprintCodeKey
                , trt.UserAgentKey   
                , trt.IP
                , trt.ActionResultKey
				, trt.Flagged
                , trt.PluginID
                , trt.TransStatus				
				, trt.CreatedDate                
                , CURRENT_TIMESTAMP(4) 	AS InsertTime
	FROM		Temp_RawTransaction AS trt;	
    
    #================================================================
    UPDATE		DCS_RawTransaction.RawTransaction AS rt
    INNER JOIN	Temp_RawTransaction AS trt
				ON rt.TransID = trt.TransID
    SET			rt.IsProcessed = 1;
	#===============================================================================================================	
  
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);
    
	UPDATE DCS_DataCenter.zzTracePerformance AS z 
	SET 
		z.EndTime = vrEndTime,
		z.Duration = TIMESTAMPDIFF(MICROSECOND,
			vrStartTime,
			vrEndTime)
	WHERE
		z.ExecKey = vrExecKey
			AND z.StepID = z.StepID;
    ### PERFORMANCE: END
    
END$$
DELIMITER ;
