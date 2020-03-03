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

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Transform Update Last Login Time';		
    SET 	vrStepID = 1;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	  
	### PERFORMANCE: END  
	
	# =====================================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_AccLastLogin;
    CREATE TEMPORARY TABLE Temp_AccLastLogin
    (
			ID				BIGINT UNSIGNED
            , AccountID 	BIGINT UNSIGNED
            , LastLoginTime	TIMESTAMP(4)
            , CTSCustID		BIGINT UNSIGNED
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	# --===GET Association which has CTSCustID
    INSERT INTO Temp_AccLastLogin(ID, AccountID, LastLoginTime, CTSCustID)
    SELECT		lt.ID
				, lt.AccountID
                , lt.LastLoginTime
                , ca.CTSCustID
    FROM		DCS_DataCenter.TransformTemp_LastLoginTime AS lt
    INNER JOIN	CTS_DataCenter.CustDCSAccount	AS ca
				ON	lt.AccountID = ca.AccountID
    LIMIT		ip_Batch;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    # --===Update CTSCustomer.LastLoginTime
    UPDATE CTS_DataCenter.CTSCustomer AS ct
    INNER JOIN	(	SELECT 		CTSCustID
								, MAX(LastLoginTime) AS MaxLastLoginTime
					FROM		Temp_AccLastLogin AS al
                    GROUP BY 	al.CTSCustID
				) AS gc
				ON ct.CTSCustID =gc.CTSCustID
	SET		ct.LastLoginTime = gc.MaxLastLoginTime
    WHERE	ct.LastLoginTime < gc.MaxLastLoginTime;
    
    DELETE 		lt
    FROM		DCS_DataCenter.TransformTemp_LastLoginTime AS lt
    INNER JOIN 	Temp_AccLastLogin al
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