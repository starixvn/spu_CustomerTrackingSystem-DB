DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_UserAgent_UpdateOSBrowser $$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_UserAgent_UpdateOSBrowser(IN ip_UserAgentJson JSON)
BEGIN
	/*
		Created:	20190815@Terry.Nguyen
		Task :		Update User Agent (OS, Browser)
		DB:			DCS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'DCS_DC_TransformData_UserAgent_UpdateOSBrowser' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Update OS Browser';		
    SET 	vrStepID = 1;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	  
	### PERFORMANCE: END  
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;     

	DROP TABLE IF EXISTS Temp_UserAgent;

	CREATE TEMPORARY TABLE Temp_UserAgent
	( 
		UserAgentKey 		VARCHAR(32)
		,	BrowserName		VARCHAR(100)
		,	OSName			VARCHAR(100)
        ,   CreatedDate		DATETIME
        ,	BrowserID		INT
        ,	OSID			INT
	);

	#=======================

	INSERT INTO Temp_UserAgent(UserAgentKey, BrowserName, OSName, CreatedDate)
	SELECT 	tmpUA.UserAgentKey
            , tmpUA.BrowserName
            , tmpUA.OSName
            , tmpUA.CreatedDate
	FROM
	JSON_TABLE(
				ip_UserAgentJson
				, "$[*]" COLUMNS(
								UserAgentKey 		VARCHAR(32) PATH "$.UserAgentKey"							
								, BrowserName		VARCHAR(100) PATH "$.BrowserName" 
								, OSName			VARCHAR(100) PATH "$.OSName"
                                , CreatedDate		DATETIME PATH "$.CreatedDate" 
								)
				) AS  tmpUA;

	#=======================
	
	# Insert Browser
	INSERT IGNORE INTO DCS_DataCenter.Browser(BrowserName, CreatedDate)
	SELECT		tmpBr.BrowserName, MIN(CreatedDate) 
    FROM 		Temp_UserAgent AS tmpBr 
    GROUP BY 	tmpBr.BrowserName;

	# Insert OS
	INSERT IGNORE INTO DCS_DataCenter.OS(OSName, CreatedDate)
	SELECT 		tmpOs.OSName, MIN(CreatedDate) 
	FROM 		Temp_UserAgent AS tmpOs 
    GROUP BY 	tmpOs.OSName;

	# Update Browser and OS Id into temporary table
	UPDATE 		Temp_UserAgent as tmpAU 
	INNER JOIN	DCS_DataCenter.OS AS os
				ON tmpAU.OSName = os.OSName
	INNER JOIN	DCS_DataCenter.Browser AS br 
				ON tmpAU.BrowserName = br.BrowserName
	SET  		tmpAU.BrowserID = br.BrowserID
				, tmpAU.OSID = os.OSID;             
	
	# Update Browser and OS into User Agent table
	UPDATE 		DCS_DataCenter.UserAgent AS us 
	INNER JOIN	Temp_UserAgent AS tmp 
				ON us.UserAgentKey = tmp.UserAgentKey
	SET 		us.BrowserID = tmp.BrowserID
				, us.OSID = tmp.OSID
				, us.Browser = tmp.BrowserName
				, us.OS = tmp.OSName;

	#=======================
	DROP TABLE IF EXISTS Temp_UserAgent;
	#=======================
    
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    
    ### PERFORMANCE: END
END$$

DELIMITER ;