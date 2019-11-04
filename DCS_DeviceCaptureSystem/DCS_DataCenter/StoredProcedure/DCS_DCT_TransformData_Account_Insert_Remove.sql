
DELIMITER $$

USE DCS_DataCenter$$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DCT_TransformData_Account_Insert$$

CREATE PROCEDURE DCS_DataCenter.DCS_DCT_TransformData_Account_Insert(IN ip_AccountJson JSON)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Insert Account
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/

    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName	VARCHAR(200) DEFAULT 'DCS_DCT_TransformData_Account_Insert' ;
    DECLARE		vrStepID	INT;
	DECLARE 	vrNotes	 	VARCHAR(500);
	DECLARE 	vrStartTime	TIMESTAMP(4);
	DECLARE		vrEndTime 	TIMESTAMP(4);
	DECLARE		vrDuration 	BIGINT;	
    DECLARE		vrTotalRecord		INT;
  
    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Insert New Account by Json';	
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);    
    	
	### PERFORMANCE: END  
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	

    #=========================================================================================
    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	
	CREATE TEMPORARY TABLE Temp_Account
    ( 
        SubscriberID			BIGINT
        , IsDeposit				TINYINT
		, LoginName				VARCHAR(50)
        , LoginNameWithPrefix	VARCHAR(100)
		, CreatedDate			DATETIME        
		, CustID				BIGINT
		, Username				VARCHAR(50)
		, Username2				VARCHAR(50)
		, RoleID				TINYINT			
		, CurrencyID			SMALLINT
		, CurrencyName			VARCHAR(50)        
	);   
   
    INSERT INTO Temp_Account(
				SubscriberID, 
				IsDeposit, 
				LoginName, 
				LoginNameWithPrefix,
				CustID, 
				Username, 
				Username2, 
				RoleID, 
				CurrencyID, 
				CurrencyName, 
				CreatedDate)
	SELECT *
			 FROM
			   JSON_TABLE(
				ip_AccountJson,
				 "$[*]" COLUMNS(
                 LoginName				VARCHAR(100) PATH "$.LoginName"
				, SubscriberID 			BIGINT PATH "$.SubscriberId"         
				, IsDeposit				TINYINT PATH "$.IsDeposit"   
                , CreatedDate			DATETIME PATH "$.CreatedDate"
				 )
			   ) AS  tmpAcc;               
   
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   
	INSERT IGNORE INTO DCS_DataCenter.Account
		(
		LoginName
        , SubscriberID
		, IsDeposit
        , CreatedDate
        , InsertTime
		)
	SELECT    
		tac.LoginName
        , tac.SubscriberID
		, tac.IsDeposit
        , tac.CreatedDate
        , CURRENT_TIMESTAMP(4) AS InsertTime
	FROM	Temp_Account AS tac;
 
    
	### PERFORMANCE  
	SET	vrEndTime = CURRENT_TIMESTAMP(4);
    SELECT Count(1)
    INTO	vrTotalRecord
    FROM	Temp_Account AS tts;
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrTotalRecord
    WHERE	z.ExecKey = vrExecKey AND z.StepID = z.StepID;
    ### PERFORMANCE: END
    	
    #============================================
	DROP TEMPORARY TABLE IF EXISTS Temp_Account;
    #============================================

END$$
DELIMITER ;
