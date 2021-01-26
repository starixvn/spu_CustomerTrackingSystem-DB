/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TransformUpdateLastLoginTime`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TransformUpdateLastLoginTime`(IN ip_Batch int)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20190815@Terry.Nguyen
		Task :		Update User Agent (OS, Browser)
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			
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

	# --===GET Association which has CTSCustID
    INSERT INTO Temp_CustLastLogin(ID, CTSCustID, LastLoginTime)
    SELECT		lt.ID
				, lt.CTSCustID
                , lt.LastLoginTime
    FROM		DCS_DataCenter.LastLoginTime_TransformTemp AS lt
    ORDER BY 	ID ASC
    LIMIT		ip_Batch;

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