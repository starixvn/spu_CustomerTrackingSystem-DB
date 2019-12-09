DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformDCSAccountToCTSCustomer$$
CREATE DEFINER=`fps`@`%` PROCEDURE CTS_DataCenter.CTS_DC_TransformDCSAccountToCTSCustomer(IN ip_AccountList JSON)
BEGIN
	/*
		Created:	20191112@Terry
		Task:		Transform Data
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/
	DECLARE vrDepositSubType TINYINT DEFAULT 1;
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'CTS_DC_TransformDCSAccountToCTSCustomer' ;
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
        , LoginName				VARCHAR(100)   	CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'     
        , SubscriberID			INT
		, SubscriberType		INT
		, LoginNameWithPrefix	VARCHAR(100)	CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'
        , CTSCustID				BIGINT UNSIGNED
    , PRIMARY KEY	PK_TempAccount_AccountID(AccountID)
	, UNIQUE KEY	UK_TempAccount_SubscriberIDLoginName(SubscriberID, LoginName)    
    );       
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;     

	INSERT INTO Temp_Account(AccountID, LoginName, SubscriberID, SubscriberType, LoginNameWithPrefix)
	SELECT 	tmpTable.AccountID 
            , tmpTable.LoginName 
			, tmpTable.SubscriberID
            , sub.SubscriberType
            , CONCAT(sub.SubscriberPrefix, tmpTable.LoginName) AS LoginNameWithPrefix
	FROM JSON_TABLE(ip_AccountList,
		 "$[*]" COLUMNS(
			  AccountID 				BIGINT 																	PATH "$.AccountId"
            , LoginName					VARCHAR(100) 	CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'  	PATH "$.LoginName" 
			, SubscriberID				INT																		PATH "$.SubscriberId"
		 )) as tmpTable  
	INNER JOIN 	CTS_Admin.Subscriber AS sub
				ON tmpTable.SubscriberID = sub.SubscriberID;
    
	 #=============GET CTSCustomerInfo=========================================
    UPDATE Temp_Account AS tmpTable
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cus USE INDEX(IX_CTSCustomer_UserName_UserName2,IX_CTSCustomer_UserName2)
				ON (tmpTable.LoginNameWithPrefix = cus.Username
					OR tmpTable.LoginNameWithPrefix = cus.Username2)
	SET 		tmpTable.CTSCustID = cus.CTSCustID;

    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    #=======New Deposit Account that not existing in CTSCustomer
    INSERT IGNORE INTO	CTS_DataCenter.CTSCustomer(SubscriberID, UserName2)
    SELECT		acc.SubscriberID
				, acc.LoginNameWithPrefix
    FROM 		Temp_Account AS acc
    WHERE		acc.SubscriberType = vrDepositSubType 
				AND acc.CTSCustID IS NULL;   			

    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	UPDATE 		Temp_Account AS acc
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cus USE INDEX(IX_CTSCustomer_UserName_UserName2,IX_CTSCustomer_UserName2)
				ON (acc.LoginNameWithPrefix = cus.Username
					OR acc.LoginNameWithPrefix = cus.Username2)
				#ON	acc.LoginNameWithPrefix COLLATE utf8mb4_unicode_ci IN (cus.UserName, cus.UserName2)
	SET			acc.CTSCustID = cus.CTSCustID
	WHERE		acc.SubscriberType = vrDepositSubType 
				AND acc.CTSCustID IS NULL;   	
	

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   
    INSERT IGNORE INTO CTS_DataCenter.CustDCSAccount(CTSCustID, AccountID, SubscriberID, InsertTime)
	SELECT  acc.CTSCustID
			, acc.AccountID
			, acc.SubscriberID 
            , CURRENT_TIMESTAMP(4) AS InserTime
    FROM 	Temp_Account as acc
	WHERE acc.CTSCustID IS NOT NULL;    
    
    
    Update DCS_DataCenter.Account acc
	INNER JOIN	Temp_Account AS tac 
				ON acc.AccountID = tac.AccountID
	SET IsCTSTransformed = 1
     WHERE tac.CTSCustID IS NOT NULL
			OR (
				tac.SubscriberType = vrDepositSubType 
				AND tac.CTSCustID IS NULL   
            );
            
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