DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformUpdateLastLoginTime $$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_TransformUpdateLastLoginTime(IN ip_Batch INT)
BEGIN
	/*
		Created:	20190815@Terry.Nguyen
		Task :		Update User Agent (OS, Browser)
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'CTS_DC_TransformUpdateLastLoginTime' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;
	
    SET ip_Batch = 500;
    
    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Transform Update Last Login Time';		
    SET 	vrStepID = 1;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	  
	### PERFORMANCE: END  
	
	# =====================================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_CustLastLogin;
    CREATE TEMPORARY TABLE Temp_CustLastLogin
    (
			ID				BIGINT UNSIGNED
            , CTSCustID 	BIGINT UNSIGNED
            , LastLoginTime	TIMESTAMP(4)
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	# --===GET Association which has CTSCustID
    INSERT INTO Temp_CustLastLogin(ID, CTSCustID, LastLoginTime)
    SELECT		lt.ID
				, lt.CTSCustID
                , lt.LastLoginTime
    FROM		DCS_DataCenter.LastLoginTime_TransformTemp AS lt
    ORDER BY 	ID ASC
    LIMIT		ip_Batch;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    # --===Update CTSCustomer.LastLoginTime
    UPDATE 		CTS_DataCenter.CTSCustomer AS ct
    INNER JOIN	Temp_CustLastLogin AS  gc
				ON ct.CTSCustID = gc.CTSCustID
	SET		ct.LastLoginTime = gc.LastLoginTime
    WHERE	ct.LastLoginTime < gc.LastLoginTime
			OR ct.LastLoginTime IS NULL;
            
    DELETE 		lt
    FROM		DCS_DataCenter.LastLoginTime_TransformTemp AS lt
    INNER JOIN 	Temp_CustLastLogin AS al
				ON lt.ID = al.ID;
	
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