/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Transaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Transaction_Insert`(
        IN ip_FromTransID   BIGINT UNSIGNED
    ,   IN ip_ToTransID     BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20190730@Casey.Huynh
	    Task : Insert Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20191217@CaseyHuynh: Implement LastLoginTime [RedmineID: #125530]
            - 20200416@Terry: Archive Completed RawTransaction to DCS_DataCenter.ProcessedTransaction.
		    - 20200506@CaseyHuynh: Not Deposit Account. Insert Ignore On Duplicate, Update (LastLoginTime, IsCTSTransfromed). Remove code "INSERT IGNORE INTO DCS_DataCenter.TransactionIP_TransformTemp" [RedmineID: #133486]
		    - 20200515@CaseyHuynh: Update LastLoginTime [RedmineID: #133263]
            - 20200918@CaseyHuynh: Change column TransID to RawTransID [RedmineID: #137963]
            - 20201006@CaseyHuynh: Move New Server, Move table RawTransaction from DB "DCS_RawTransaction" to "DCS_DataCenter" [RedmineID: #143011]
            - 20201019@CaseyHuynh: Move Server, Phase 2	 [RedmineID: #143011]
            - 20201112@CaseyHuynh: GET Lastest Code Move Server P3, update Permission and Add Meta data, Update login Retry for unsuccsess Transform (-1,-2,-3) (SET IsCTSTransformed = 0 instead of -1) [RedmineID: #145271]
		    - 20201119@CaseyHuynh: Enhance New Retry transform association/account Flow, change log to CTS_Log DB [RedmineID: #145271]
		    - 20210510@Aries.Nguyen: Remove insert log zzTracePerformance [Redmine ID: #154792]
            - 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]
			- 20211129@Casey.Huynh: Remove FingerprintMoreInfo Column [Redmine ID: #165167]
			- 20230323@Terry.Nguyen: Get InsertTime from RawTransaction [Redmine Id: #185185]
			- 20230426@Jonathan.Doan: Get BotDetectionValue from RawTransaction [Redmine ID: #186644]
			- 20230807@Terry.Nguyen: Add Fake IP [Redmine: 191829]
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
			- 20240627@Jonathan.Doan: Change data flow v6 [Redmine ID: #206403]
			- 20241111@Jonathan.Doan: Add Insert FP_Tagging [Redmine ID: #212696]
            - 20250825@Casey.Huynh: AI Power Device Fingerprint And Remove FPJs [Redmine ID: #236716]
            
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_Transaction_Insert(1,200);
    */
    DECLARE 	CONST_SYSTEMSETTINGID_MINCREATEDDATE	INT DEFAULT 2;
    
    DECLARE 	CONST_FPPATTERNTYPE01	INT DEFAULT 1;
    DECLARE 	CONST_FPPATTERNTYPE02	INT DEFAULT 2;
    
	DECLARE		lv_SysMinCreatedDate					DATETIME;
    DECLARE 	lv_CurrentDate 							DATETIME(4) DEFAULT CURRENT_TIMESTAMP(4);
    DECLARE 	lv_ListFPTagging 						LONGTEXT;

    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;
	CREATE TEMPORARY TABLE IF NOT EXISTS Temp_RawTransaction (
		    TransID				BIGINT UNSIGNED NOT NULL
		,   LoginName			VARCHAR(100) NOT NULL
		,   TransTime			DATETIME(4) NOT NULL
		,   SubscriberID		INT 				
        ,   AccountID			BIGINT	UNSIGNED 	
        ,   SubscriberType		TINYINT	UNSIGNED	
        ,   URLDetails			VARCHAR(250)		
		,   URLID				INT					
		,   DeviceCode			VARCHAR(32) COMMENT 'Trans Device Code'
        ,   UserAgentKey		VARCHAR(32)			
		,   IP					VARCHAR(50) 		
        ,   IPID				DECIMAL(50,0)			
		,   ActionResultID		INT					
		,   Flagged				SMALLINT COMMENT 'captcha & browserless'
		,   PluginID			BIGINT 				
		,   TransStatus			BIT(16) 			
		,   CreatedDate			DATETIME COMMENT 'Date Only' 
		,   InsertTime			DATETIME(4) 		
		,   FingerprintCode		VARCHAR(620)
        ,   BotDetectionValue	BIT(20)
        ,   BotComponentID		BIGINT UNSIGNED
        ,	FakeIP				VARCHAR(100)
        ,	ChallengeCode		VARCHAR(50)
        ,	IsIncognitoMode		BIT
        ,	JSChallengeInfoID	BIGINT UNSIGNED

        ,	WebRTCIPCode		VARCHAR(32)	
        ,	WebRTCIPID			BIGINT UNSIGNED
		,	FPPatternCode01 	VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group ' 
		,	FPPatternCode02  	VARCHAR(32) 
		,	FPPatternID01 		BIGINT UNSIGNED
		,	FPPatternID02  		BIGINT UNSIGNED
        ,	FPVersion			VARCHAR(10)
        ,	TransFlow				TINYINT(1)	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TEMPORARY TABLE  Temp_Account(
		    LoginName			VARCHAR(100) NOT NULL
		,   SubscriberID		INT 
        ,   SubscriberType		TINYINT	UNSIGNED	
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LastLoginTime;
    CREATE TEMPORARY TABLE Temp_LastLoginTime(
		    SubscriberID		INT
        ,   AccountID			BIGINT UNSIGNED
        ,   LastLoginTime		DATETIME(4)
    );
   
    DROP TEMPORARY TABLE IF EXISTS Temp_LastLoginTimeCTSCust;
    CREATE TEMPORARY TABLE Temp_LastLoginTimeCTSCust(
		    CTSCustID			BIGINT UNSIGNED
        ,   LastLoginTime		DATETIME(4)
    );
   
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistingPattern;
	CREATE TEMPORARY TABLE  Temp_ExistingPattern(
			ID				BIGINT UNSIGNED PRIMARY KEY
		,	FPPatternType	TINYINT
		,	FPPatternCode	VARCHAR(32) 
        ,	LastUsedDate 	DATE
        
        ,	INDEX IX_Temp_ExistingPattern_FPGroupCode(FPPatternType, FPPatternCode)
    ); 
       
    SELECT DATE(VValue)
    INTO lv_SysMinCreatedDate
    FROM DCS_DataCenter.SystemSetting 
    WHERE ID = CONST_SYSTEMSETTINGID_MINCREATEDDATE;

	INSERT INTO Temp_RawTransaction(TransID, LoginName, TransTime, SubscriberID, SubscriberType, DeviceCode , URLDetails, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, FingerprintCode, BotDetectionValue, BotComponentID, FakeIP, IsIncognitoMode, ChallengeCode, WebRTCIPCode, FPPatternCode01, FPPatternCode02, FPVersion, TransFlow)
	SELECT  rt.TransID
	    ,   rt.LoginName
        ,   rt.TransTime
        ,   su.SubscriberID
        ,   su.SubscriberType
        ,   rt.DeviceCode
        ,   rt.URL
        ,   MD5(LOWER(rt.UserAgent))
        ,   rt.IP
        ,   rt.IPID
        ,   ar.ActionResultID
        ,   rt.Flagged
        ,   rt.PluginID
        ,   rt.TransStatus
        ,   rt.CreatedDate
        ,   rt.FingerprintCode
        ,   rt.BotDetectionValue
        ,   rt.BotComponentID
        ,   rt.FakeIP
        ,   rt.IsIncognitoMode
        ,   rt.ChallengeCode        
        ,	rt.WebRTCIPCode
        ,	rt.FPPatternCode01
        ,	rt.FPPatternCode02
        ,	rt.FPVersion
        ,	rt.TransFlow
	FROM DCS_DataCenter.RawTransaction AS rt
        INNER JOIN CTS_Admin.Subscriber AS su ON rt.SubscriberName = su.SubscriberName
	    LEFT JOIN DCS_DataCenter.ActionResult AS ar ON rt.Action = ar.Action AND IFNULL(rt.ActionResult,'') = ar.ActionResult
	WHERE   rt.IsProcessed = 0
	    AND rt.TransID BETWEEN ip_FromTransID AND ip_ToTransID
        AND rt.CreatedDate >= lv_SysMinCreatedDate;   
	

    /* === Add index for Temp_RawTransaction === */
	ALTER TABLE Temp_RawTransaction
		ADD INDEX IX_Temp_RawTransaction_ChallengeCode (ChallengeCode)
    ,	ADD INDEX IX_Temp_RawTransaction_FPPatternCode01(FPPatternCode01)
    ,	ADD INDEX IX_Temp_RawTransaction_FPPatternCode02(FPPatternCode02)
    ,	ADD INDEX IX_Temp_RawTransaction_WebRTCIPCode(WebRTCIPCode);
	
    #===================FINGERPRINT PARTTERN=======================================
	UPDATE Temp_RawTransaction AS rt
		INNER JOIN DCS_DataCenter.FPPattern AS fp1 ON fp1.FPPatternType = CONST_FPPATTERNTYPE01 AND fp1.FPPatternCode = rt.FPPatternCode01 
	SET rt.FPPatternID01 = fp1.FPPatternID
    WHERE rt.FPPatternCode01 IS NOT NULL
		AND rt.TransFlow = 1;
    
    UPDATE Temp_RawTransaction AS rt
		INNER JOIN DCS_DataCenter.FPPattern AS fp2 ON fp2.FPPatternType = CONST_FPPATTERNTYPE02 AND fp2.FPPatternCode = rt.FPPatternCode02
	SET rt.FPPatternID02 = fp2.FPPatternID
    WHERE rt.FPPatternCode02 IS NOT NULL
		AND rt.TransFlow = 1;
    
    #===================FINGERPRINT WebRTCIP=======================================
    UPDATE Temp_RawTransaction AS rt
		INNER JOIN DCS_DataCenter.WebRTCIP AS wip ON wip.WebRTCIPCode = rt.WebRTCIPCode
	SET rt.WebRTCIPID = wip.WebRTCIPID
    WHERE rt.WebRTCIPCode IS NOT NULL
		AND rt.TransFlow = 1;  
    
    #==================INSERT SUBCRIBERURL =====================================   
    INSERT IGNORE INTO DCS_DataCenter.URL(URLDetails, SubscriberID, CreatedDate)
	SELECT	trt.URLDetails
        ,   trt.SubscriberID
        ,   MIN(trt.CreatedDate)
	FROM Temp_RawTransaction AS trt
	GROUP BY trt.SubscriberID
        ,    trt.URLDetails;
    
	# Insert New Account
    INSERT IGNORE INTO DCS_DataCenter.Account(LoginName, SubscriberID, SubscriberType, CreatedDate, InsertTime, CreatedTime, LastLoginTime)
    SELECT  trt.LoginName
	    ,   trt.SubscriberID
	    ,   trt.SubscriberType
	    ,   MIN(trt.CreatedDate)
	    ,   lv_CurrentDate AS InsertTime
        ,   MIN(trt.TransTime) AS CreatedTime
        ,   MAX(trt.TransTime) AS LastLoginTime
    FROM Temp_RawTransaction AS trt
    WHERE NOT EXISTS (SELECT 1 FROM DCS_DataCenter.Account AS acc WHERE trt.LoginName = acc.LoginName AND trt.SubscriberID = acc.SubscriberID)
    GROUP BY trt.SubscriberID
        ,    trt.LoginName
        ,    trt.SubscriberType;
    
    # Update AccountID & URLID
    UPDATE Temp_RawTransaction AS tmp
        INNER JOIN DCS_DataCenter.Account AS acc ON acc.SubscriberID = tmp.SubscriberID AND acc.LoginName = tmp.LoginName
	    LEFT JOIN DCS_DataCenter.URL AS url ON url.URLDetails = tmp.URLDetails
    SET tmp.AccountID = acc.AccountID,
		tmp.URLID = url.URLID;
    
    #==============Remove Temp Trans If AccountID Is NULL=======================
    DELETE 	trt
    FROM	Temp_RawTransaction AS trt
    WHERE 	trt.AccountID IS NULL;
    
    UPDATE 	DCS_DataCenter.Association AS ass
        INNER JOIN	(SELECT DISTINCT AccountID FROM Temp_RawTransaction trt) AS trtAcc ON ass.AccountID = trtAcc.AccountID
        INNER JOIN	CTS_DataCenter.CustDCSAccount AS acc ON ass.AccountID = acc.AccountID
	SET ass.IsCTSTransformed = 0
    WHERE ass.IsCTSTransformed < 0;
  
    INSERT INTO Temp_LastLoginTime(SubscriberID, AccountID, LastLoginTime)
    SELECT  acc.SubscriberID
        ,   acc.AccountID
        ,   tac.LastLoginTime
    FROM DCS_DataCenter.Account AS acc
        INNER JOIN (SELECT trt.AccountID, MAX(trt.TransTime) AS LastLoginTime
					FROM Temp_RawTransaction AS trt
                    GROUP BY trt.AccountID) AS tac ON	acc.AccountID = tac.AccountID
    WHERE tac.LastLoginTime > acc.LastLoginTime;

    INSERT INTO Temp_LastLoginTimeCTSCust(CTSCustID, LastLoginTime)
    SELECT  cus.CTSCustID
	    ,   MAX(lgn.LastLoginTime)
    FROM Temp_LastLoginTime AS lgn
        INNER JOIN  CTS_DataCenter.CustDCSAccount AS cus ON lgn.AccountID = cus.AccountID
	GROUP BY 	cus.CTSCustID;
	
    INSERT INTO DCS_DataCenter.AccountLastLoginTimeProcess(AccountID, LastLoginTime)
    SELECT  tll.AccountID
        ,   tll.LastLoginTime
    FROM Temp_LastLoginTime AS tll;

    INSERT INTO DCS_DataCenter.CTSCustomerLastLoginTimeProcess(CTSCustID, LastLoginTime)
    SELECT  CTSCustID
        ,   LastLoginTime
    FROM  Temp_LastLoginTimeCTSCust AS tmp_cus;

	UPDATE Temp_RawTransaction AS tmp
		LEFT JOIN DCS_DataCenter.JSChallengeInfo AS jsc ON jsc.ChallengeCode = tmp.ChallengeCode
	SET tmp.JSChallengeInfoID = CASE WHEN tmp.ChallengeCode IS NULL THEN NULL ELSE IFNULL(jsc.ID, 0) END;
	
	/* ======= INSERT Transaction ========= */
    INSERT IGNORE INTO DCS_DataCenter.Transaction(RawTransID, LoginName, TransTime, SubscriberID, AccountID, URLID, UserAgentKey , IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime, DeviceCode, FingerprintCode, BotDetectionValue, BotComponentID, FakeIP, IsIncognitoMode, JSChallengeInfoID
    , FPPatternID01, FPPatternID02, WebRTCIPID, TransFlow)
   	SELECT  trt.TransID
	    ,   trt.LoginName
        ,   trt.TransTime
	    ,   trt.SubscriberID
        ,   trt.AccountID
	    ,   trt.URLID
        ,   trt.UserAgentKey
        ,   trt.IP
        ,   trt.IPID
        ,   trt.ActionResultID
	    ,   trt.Flagged
        ,   trt.PluginID
        ,   trt.TransStatus
	    ,   trt.CreatedDate
        ,   lv_CurrentDate AS InsertTime
        ,   trt.DeviceCode
        ,   trt.FingerprintCode
        ,   trt.BotDetectionValue
        ,   trt.BotComponentID
        ,   trt.FakeIP
        ,   trt.IsIncognitoMode
        ,   trt.JSChallengeInfoID
        ,	IFNULL(trt.FPPatternID01, 0) AS FPPatternID01
        ,	IFNULL(trt.FPPatternID02, 0) AS FPPatternID02
        ,	trt.WebRTCIPID
        ,	trt.TransFlow
	FROM Temp_RawTransaction AS trt;   

    #================================================================
	INSERT IGNORE INTO DCS_DataCenter.ProcessedTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, UserAgent , IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, IsProcessed, TransID, InsertTime, BotDetectionValue, BotComponentID, FakeIP, IsIncognitoMode, ChallengeCode, WebRTCIPCode, FPPatternCode01, FPPatternCode02, FPVersion, TransFlow)
	SELECT  rt.LoginName
        ,   rt.SubscriberName
        ,   rt.TransTime
        ,   rt.CreatedDate
        ,   rt.DeviceCode
        ,   rt.FingerprintCode
        ,   rt.UserAgent
	    ,   rt.IP
        ,   rt.IPID
        ,   rt.Flagged
        ,   rt.PluginID
        ,   rt.URL
        ,   rt.Action
        ,   rt.ActionResult
        ,   rt.InvalidDevice
        ,   rt.TransStatus
        ,   rt.IsProcessed
        ,   rt.TransID
		,	rt.InsertTime
		,	rt.BotDetectionValue
		,	rt.BotComponentID
		,	rt.FakeIP
        ,   rt.IsIncognitoMode
        ,   rt.ChallengeCode
        ,	rt.WebRTCIPCode
        ,	rt.FPPatternCode01
        ,	rt.FPPatternCode02
        ,	rt.FPVersion
        , 	rt.TransFlow
	FROM DCS_DataCenter.RawTransaction AS rt
	    INNER JOIN	Temp_RawTransaction	AS tmp_rm ON rt.TransID = tmp_rm.TransID AND rt.CreatedDate = tmp_rm.CreatedDate;
        
	DELETE rt
	FROM DCS_DataCenter.RawTransaction AS rt
	    INNER JOIN	Temp_RawTransaction	AS tmp_rm ON rt.TransID = tmp_rm.TransID AND rt.CreatedDate = tmp_rm.CreatedDate;
    
END$$
DELIMITER ;
