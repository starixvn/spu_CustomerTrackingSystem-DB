
DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_UnhandleSubscriberAction$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_UnhandleSubscriberAction(IN ip_FromTransID BIGINT, IN ip_ToTransID BIGINT)
BEGIN
	
    /*
	Created: 20190730@Casey.Huynh
	Task :  Filter Unhandled Subscriber by IsProcessed = -1, Action Result
	DB: DCS_RawTransaction(rtaging)
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
    
	DECLARE	vrUnhandleStatus_Subscriber	 BIT(16) DEFAULT 1;
    DECLARE	vrUnhandleStatus_Action	 BIT(16) DEFAULT 2;
    DECLARE vrUnhandleStatus	TINYINT DEFAULT 0;
    DECLARE vrNotTransformedStatus BIT(16);
    
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'DCS_DC_TransformData_UnhandleSubscriberAction' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Process Unhandle Subscriber and Action';		
    SET 	vrStepID = 1;
    SET 	vrStartTime = CURRENT_TIMESTAMP(4); 
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime, FromID, ToID)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime, ip_FromTransID, ip_ToTransID);
	
	### PERFORMANCE: END 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    CREATE TEMPORARY TABLE Temp_Transaction 
    (	
		TransID			BIGINT
		, SubscriberName		VARCHAR(30)        
        , ActionResult			VARCHAR(200)
        , URLDetails			VARCHAR(250)
        , TransStatus			INT
        , CreatedDate			DATETIME	#	Date Only        
        , SubscriberID			INT
		, SubscriberStatus		TINYINT
        , ActionResultID		BIGINT
        , ActionResultStatus	TINYINT        
        , IsProcessed			BIT	DEFAULT 0
    );
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;    
    
    INSERT	INTO Temp_Transaction(TransID, SubscriberName, ActionResult, URLDetails, TransStatus, CreatedDate, SubscriberID
									, SubscriberStatus, ActionResultID, ActionResultStatus)
    SELECT 	rt.TransID
			, rt.SubscriberName
            , rt.ActionResult
            , rt.URL
            , rt.TransStatus
            , rt.CreatedDate
            , su.SubscriberID
            , su.SubscriberStatus
            , ActionResultID
            , ActionResultStatus
	FROM	DCS_RawTransaction.RawTransaction AS rt
	LEFT JOIN	CTS_Admin.Subscriber AS su
				ON rt.SubscriberName = su.SubscriberName
	LEFT JOIN	DCS_DataCenter.ActionResult AS ar
				ON rt.ActionResult = ar.ActionResultDetails
    WHERE	rt.TransID BETWEEN ip_FromTransID AND ip_ToTransID
				AND rt.IsProcessed = 0;   
        
    #==UNHANDLE SUBSCRIBER================================================================
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	INSERT IGNORE INTO CTS_Admin.Subscriber (SubscriberName, CreatedDate, SubscriberStatus)
	SELECT 		ts.SubscriberName
				, MIN(ts.CreatedDate) AS CreatedDate
				, vrUnhandleStatus	AS Status # vrUnhandleStatus_Subscriber
    FROM		Temp_Transaction AS ts   
    WHERE		ts.SubscriberID IS NULL
    GROUP BY	ts.SubscriberName;

    #==UNHANDLE ACTION================================================================    
	INSERT IGNORE INTO DCS_DataCenter.ActionResult (ActionResultDetails, CreatedDate, ActionResultStatus)
	SELECT 		ts.ActionResult 		AS ActionResultDetails
				, MIN(ts.CreatedDate)	AS CreatedDate
				, vrUnhandleStatus		AS ActionResultStatus # vrUnhandleStatus_Subscriber
    FROM		Temp_Transaction	AS ts
    GROUP BY	ts.ActionResult;
	
	
    SET vrNotTransformedStatus = DCS_DC_GetTransStatus_NotTransformed();

    #===Update NOT Transform status for the Invalid Transaction (Invalid Subscriber)
    UPDATE 		Temp_Transaction AS ts
	SET			TransStatus = TransStatus | vrUnhandleStatus_Subscriber
    WHERE		ts.SubscriberID IS NULL
				OR ts.SubscriberStatus = vrUnhandleStatus;
	    
   # SELECT 		ts.TransID, ts.TransStatus, vrNotTransformedStatus, ts.TransStatus & vrNotTransformedStatus
    #FROM		Temp_Transaction AS ts;
    
	#===Update NOT Transform status for the Invalid Action Result(Invalid Action Result)
    UPDATE 		Temp_Transaction AS ts
	SET			TransStatus = TransStatus | vrUnhandleStatus_Action
    WHERE		ts.ActionResultID IS NULL
				OR ts.ActionResultStatus = vrUnhandleStatus; 

	
    #==========================================================================
    
   # SELECT 		ts.TransID, ts.TransStatus, vrNotTransformedStatus, ts.TransStatus & vrNotTransformedStatus
    #FROM		Temp_Transaction AS ts;
    
   
    UPDATE		DCS_RawTransaction.RawTransaction AS rt
    INNER JOIN	Temp_Transaction AS ts
				ON rt.TransID = ts.TransID
	SET			rt.IsProcessed = CASE WHEN (ts.TransStatus & vrNotTransformedStatus) != 0 THEN -1 ELSE rt.IsProcessed END 
				, rt.TransStatus = ts.TransStatus;
   
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END
 
END$$
DELIMITER ;
