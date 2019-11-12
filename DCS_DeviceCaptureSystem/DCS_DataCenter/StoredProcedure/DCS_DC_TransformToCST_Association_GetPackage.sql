DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformToCST_Association_GetPackage$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformToCST_Association_GetPackage(IN ip_NoOfTickets INT, IN ip_NoOfBatch INT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Get DeviceID NULL From Table Transaction
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
	
	DECLARE		TotalRecord		INT UNSIGNED DEFAULT 0;
	DECLARE		Batch			TINYINT DEFAULT 1;
    
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'DCS_DC_TransformToCST_Association_GetPackage' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = CONCAT('Input: ',ip_NoOfTickets,'_', ip_NoOfBatch) ;		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);

	### PERFORMANCE: END
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
    CREATE TEMPORARY TABLE Temp_Account 
    (	
		BatchID				TINYINT
        , AccountID			BIGINT	UNSIGNED
        , DeviceKey			BIGINT
        , CreatedTime		TIMESTAMP(4)
        , SubscriberID		INT
    ); 
   
	SET TotalRecord = ip_NoOfTickets*ip_NoOfBatch;
    
	INSERT INTO Temp_Account( AccountID, DeviceKey, CreatedTime, SubscriberID)
	SELECT	ass.AccountID
			, ass.DeviceKey
            , ass.CreatedDate
            , ass.SubscriberID
	FROM 	DCS_DataCenter.Association AS ass
	WHERE	ass.IsCTSTransformed = 0
	LIMIT	TotalRecord;
    
    WHILE (EXISTS (SELECT (1) FROM Temp_Account WHERE BatchID IS NULL LIMIT 1)) DO
    	  UPDATE 	Temp_Account
		  SET		BatchID = Batch
          WHERE		BatchID IS NULL 
          LIMIT 	ip_NoOfTickets;    
		  SET Batch = Batch + 1;
    END WHILE;
    
    SELECT	ass.BatchID
			, ass.AccountID
            , ass.DeviceKey
            , ass.CreatedTime
            , ass.SubscriberID
	FROM Temp_Account AS ass;
    
   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
    SELECT 	Count(1), Min(TransId), Max(TransId)
    INTO	vrTotalRecord, vrFromID, vrToID
    FROM	Temp_Account AS tts;
    
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
