DELIMITER $$

USE DCS_RawTransaction$$

DROP PROCEDURE IF EXISTS DCS_RawTransaction.DCS_ST_TransformData_UpdateCompletedProcess$$
CREATE PROCEDURE DCS_RawTransaction.DCS_ST_TransformData_UpdateCompletedProcess(IN ip_FromTransID BIGINT, IN ip_ToTransID BIGINT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Mark Completed from Raw Transaction
	DB: DCS_RawTransaction(Staging)
	Original:

	Revisions:
	Param's Explanation (filtered by):
*/

		### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'DCS_RT_TransformData_UpdateCompletedProcess' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Update Completed Transfrom';		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4); 
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime, FromID, ToID)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime, ip_FromTransID, ip_ToTransID);
	   
	### PERFORMANCE: END  
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
  
	UPDATE 		DCS_RawTransaction.RawTransaction AS rt
    INNER JOIN	DCS_DataCenter.Transaction AS ts
				ON ts.TransID = rt.TransID
	SET			rt.IsProcessed = 1
    WHERE		rt.IsProcessed = 0
				AND rt.TransID BETWEEN ip_FromTransID AND ip_ToTransID;
            
     SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);

    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END

END$$
DELIMITER ;
