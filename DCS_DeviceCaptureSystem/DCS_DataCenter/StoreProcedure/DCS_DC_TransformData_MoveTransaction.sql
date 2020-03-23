DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_MoveTransaction$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_MoveTransaction(IN ip_NoOfTickets INT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Archive Data
	DB: DCS_DataCenter
	Original:

	Revisions:
			- [20200226@CaseyHuynh: Move Archive Data to New Table Transaction_BK01 and RawTransaction_BK01]
            - [20200318@CaseyHuynh: Move Archive Data to New Table Transaction07]
	Param's Explanation (filtered by):
	*/
	DECLARE	vr_FromID 	BIGINT	UNSIGNED;
	DECLARE	vr_MaxToID	BIGINT	UNSIGNED;

    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'DCS_DC_TransformData_MoveTransaction' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = CONCAT('ip_NoOfTickets: ',ip_NoOfTickets) ;		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
    
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveTrans;
    CREATE TEMPORARY TABLE Temp_RemoveTrans
    (
		TransID		BIGINT	UNSIGNED
    );
    
	  
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
	INSERT INTO Temp_RemoveTrans(TransID)
	SELECT TransID 
	FROM    DCS_DataCenter.Transaction
    WHERE 	DeviceID IS NOT NULL
	LIMIT   ip_NoOfTickets; 
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
     
		# ======================MOVE Transaction==========================================================
        SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		INSERT IGNORE INTO  DCS_DataCenter.Transaction07(TransID, LoginName, TransTime, SubscriberID, AccountID
        , URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
		, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)        
        SELECT 	ts.TransID, LoginName, TransTime, SubscriberID, AccountID
				, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
				, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime
        FROM		DCS_DataCenter.Transaction AS ts
        INNER JOIN	Temp_RemoveTrans	AS tmp_rm
					ON	ts.TransID = tmp_rm.TransID;
                    
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        
        DELETE	ts
        FROM		DCS_DataCenter.Transaction AS ts
        INNER JOIN	Temp_RemoveTrans	AS tmp_rm
					ON	ts.TransID = 	tmp_rm.TransID;
        #=====================================================================       
		UPDATE	DCS_DataCenter.MoveTransaction
		SET		LastTransID = (SELECT MAX(TransID) FROM Temp_RemoveTrans);        
        
        #--===================================================================        
    
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
    SELECT 	Count(1), Min(TransId), Max(TransId)
    INTO	vrTotalRecord, vrFromID, vrToID
    FROM	Temp_RemoveTrans AS tts;
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrTotalRecord
            , z.FromID = vrFromID
            , z.ToID		= vrToID

    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END 
    
END$$
DELIMITER ;
