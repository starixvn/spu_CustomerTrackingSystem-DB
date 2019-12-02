DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DC_TransformDCSAccountToCTSCustomer$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_TransformDCSAccountToCTSCustomer`(IN ip_AccountList JSON)
BEGIN
	/*
		Created:	20191112@Terry
		Task:		Insert CTS Customer
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/
	DECLARE vrDepositSubType TINYINT DEFAULT 1;
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'CTS_DC_TransformDCSAccountToCTSCustomer_291119' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = 'Get Json Data';		
    SET 	vrStepID = 1;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	  
	### PERFORMANCE: END  
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Account;
    
	CREATE TEMPORARY TABLE Temp_Account 
    (	
		AccountID				BIGINT	UNSIGNED
        , LoginName				VARCHAR(100)        
        , SubscriberID			INT
		, SubscriberType		INT
		, LoginNameWithPrefix	VARCHAR(100)
        , CTSCustID				BIGINT UNSIGNED
    , PRIMARY KEY	PK_TempAccount_AccountID(AccountID)
	, UNIQUE KEY	UK_TempAccount_SubscriberIDLoginName(SubscriberID, LoginName)    
    );       
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;     

        
	INSERT INTO Temp_Account(AccountID, LoginName, SubscriberID, SubscriberType, LoginNameWithPrefix, CTSCustID)
	SELECT 	tmpTable.AccountID 
            , tmpTable.LoginName 
			, tmpTable.SubscriberID
            , sub.SubscriberType
            , CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) AS LoginNameWithPrefix
	FROM JSON_TABLE(ip_AccountList,
		 "$[*]" COLUMNS(
			  AccountID 				BIGINT 			PATH "$.AccountId"
            , LoginName					VARCHAR(100)	PATH "$.LoginName" 
			, SubscriberID				INT				PATH "$.SubscriberId"
		 )) as tmpTable  
	INNER JOIN 	CTS_Admin.Subscriber AS sub
				ON tmpTable.SubscriberID = sub.SubscriberID;
	
    
    UPDATE Temp_Account AS tmpTable
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cus USE INDEX (IX_UserName2,IX_Username, IX_Username_UserName2)
				ON CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) = cus.Username
                OR CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) = cus.Username2
	SET tmpTable.CTSCustID = cus.CTSCustID;
    
   
   /*
	INSERT INTO Temp_Account(AccountID, LoginName, SubscriberID, SubscriberType, LoginNameWithPrefix, CTSCustID)
	SELECT 	tmpTable.AccountID 
            , tmpTable.LoginName 
			, tmpTable.SubscriberID
            , sub.SubscriberType
            , CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) AS LoginNameWithPrefix
            , cus.CTSCustID
	FROM		DCS_DataCenter.Account AS tmpTable 
	INNER JOIN 	CTS_Admin.Subscriber AS sub
				ON tmpTable.SubscriberID = sub.SubscriberID
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cus 
				ON CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) = cus.Username
                OR CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) = cus.Username2
	WHERE IsCTSTransformed = 0
	LIMIT 200;	
	*/
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    
	SET		vrNotes = 'Get CTSCustomer Data';		
    SET 	vrStepID = 2;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
    
    #=============GET CTSCustomerInfo=========================================
    /*SELECT     *
    FROM 	Temp_Account AS acc
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cus #USE INDEX(IX_CTSCustomer_UserName_UserName2)
				ON	acc.LoginNameWithPrefix IN (cus.UserName, cus.UserName2);

    
    UPDATE 		Temp_Account AS acc
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cus #USE INDEX(IX_CTSCustomer_UserName_UserName2)
				ON	acc.LoginNameWithPrefix IN (cus.UserName, cus.UserName2)
	SET			acc.CTSCustID = cus.CTSCustID;
    */
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;    
    	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    
	SET		vrNotes = 'Inser Deposit Account Which Has not Deposit';		
    SET 	vrStepID = 3;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
    
    #=======New Deposit Account that not existing in CTSCustomer
    INSERT IGNORE INTO	CTS_DataCenter.CTSCustomer(SubscriberID, UserName2)
    SELECT		acc.SubscriberID
				, acc.LoginNameWithPrefix
    FROM 		Temp_Account AS acc
    WHERE		acc.SubscriberType = vrDepositSubType 
				AND acc.CTSCustID IS NULL;   			
    
    	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    
	SET		vrNotes = 'Get CTSCustomer Data For Not deposit Acc';		
    SET 	vrStepID = 4;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	UPDATE 		Temp_Account AS acc
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cus 
				ON	acc.LoginNameWithPrefix IN (cus.UserName, cus.UserName2)
	SET			acc.CTSCustID = cus.CTSCustID
	WHERE		acc.SubscriberType = vrDepositSubType 
				AND acc.CTSCustID IS NULL;   			
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    
	SET		vrNotes = 'Insert CTS_DataCenter.CustDCSAccount';		
    SET 	vrStepID = 5;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
    #=========================================
    INSERT IGNORE INTO CTS_DataCenter.CustDCSAccount(CTSCustID, AccountID, SubscriberID, InsertTime)
	SELECT  acc.CTSCustID
			, acc.AccountID
			, acc.SubscriberID 
            , CURRENT_TIMESTAMP(4) AS InserTime
    FROM 	Temp_Account as acc
	WHERE acc.CTSCustID IS NOT NULL;    
    
        	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    
	SET		vrNotes = 'END Return Acc Successfull';		
    SET 	vrStepID = 6;
	SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
    
    
    Update DCS_DataCenter.Account acc
	INNER JOIN	Temp_Account AS tac 
				ON acc.AccountID = tac.AccountID
	SET IsCTSTransformed = 1
     WHERE tac.CTSCustID IS NOT NULL
			OR (
				tac.SubscriberType = vrDepositSubType 
				AND tac.CTSCustID IS NULL   
            );
	/*
    SELECT acc.AccountID 
    FROM Temp_Account AS acc 
    WHERE acc.CTSCustID IS NOT NULL
			OR (
				acc.SubscriberType = vrDepositSubType 
				AND acc.CTSCustID IS NULL   
            );
	*/
    #=======================
	DROP TABLE IF EXISTS Temp_Account;
	#=======================
    
	### PERFORMANCE
	SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    WHERE	z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    
    ### PERFORMANCE: END
END$$
DELIMITER ;