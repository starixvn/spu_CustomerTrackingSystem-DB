/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DELIMITER $$
DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformToCTS_Account_GetPackage$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE DCS_DataCenter.DCS_DC_TransformToCTS_Account_GetPackage(IN ip_NoOfAccount INT, IN ip_NoOfBatch INT)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Get DeviceID NULL From Table Transaction
	DB: DCS_DataCenter
	Original:

	Revisions:
		#1. [20191217@CaseyHuynh][#125530]: Implement LastLoginTime 
		#2. [20200512@CaseyHuynh]: Add Nolock Statement
        #3. [20201112@CaseyHuynh][145271]:	
			+ GET Lastest Code Move Server P3, update Permission and Add Meta data
            + Enhance  script
	Param's Explanation (filtered by):
	*/
	
    DECLARE		TotalRecord		INT UNSIGNED DEFAULT 0;
	DECLARE		Batch			TINYINT DEFAULT 1;
    
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'DCS_DC_TransformToCTS_Account_GetPackage' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = CONCAT('Input: ',ip_NoOfAccount,'_', ip_NoOfBatch) ;		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO CTS_Log.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);

	### PERFORMANCE: END
    SET @RowId = 1;
    SET @MinAccountID = (SELECT MAX(AccountID) FROM DCS_DataCenter.Account AS ac) ;
    SET @MaxAccountID = 0;
    
	SET TotalRecord = ip_NoOfAccount*ip_NoOfBatch;  
	SELECT	ceil(@RowId/ip_NoOfAccount) AS BatchID
            , ac.AccountID
            , ac.LoginName
            , ac.SubscriberID
            , ac.LastLoginTime
            , @RowId := @RowId+1
            , @MinAccountID := LEAST(@MinAccountID,AccountID)
            , @MaxAccountID := GREATEST(@MinAccountID,AccountID)
	FROM 	DCS_DataCenter.Account AS ac
	WHERE	ac.IsCTSTransformed = 0
	LIMIT	TotalRecord;
    
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
    UPDATE	CTS_Log.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = @RowId
            , z.FromID 		= @MinAccountID
            , z.ToID		= @MaxAccountID

    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END 
END$$
DELIMITER ;
