DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_UserAgent_GetNullBrowserOSList $$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_UserAgent_GetNullBrowserOSList(IN ip_size INT)
BEGIN
	/*
		Created:	20190815@Terry.Nguyen
		Task :		Get user agent list by size
		DB:			DCS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'DCS_DC_TransformData_UserAgent_GetNullBrowserOSList' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'GetNullBrowserOSList';		
    SET 	vrStepID = 1;
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime, TotalRecord)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime, ip_Size);	
	    
	### PERFORMANCE: END  
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	SELECT 		ua.UserAgentKey
				, ua.UserAgent
                , ua.CreatedDate
	FROM		DCS_DataCenter.UserAgent AS ua
    WHERE 		BrowserID IS NULL 
				AND OSID IS NULL
    LIMIT ip_size; 
	
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