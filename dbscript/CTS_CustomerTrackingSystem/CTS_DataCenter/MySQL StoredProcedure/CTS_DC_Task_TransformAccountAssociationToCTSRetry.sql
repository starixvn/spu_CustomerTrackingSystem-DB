/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsOwner" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_Task_TransformAccountAssociationToCTSRetry`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Task_TransformAccountAssociationToCTSRetry`()
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20201119@Casey.Huynh
		Task:		Turn on transform Account for new CTSCustomer
		DB:			CTS_DataCenter
		Original:

		Revisions: 
			- 20201119@CaseyHuynh: Created [RedmineID : #145277] 
			- 20210510@Aries.Nguyen: Remove insert log zzTracePerformance [Redmine ID: #154792]

		Param's Explanation (filtered by):
              
	*/    
    DECLARE vrCTSCustID BIGINT;
    DECLARE vrMinCTSCustID BIGINT;
    DECLARE vrMaxCTSCustID BIGINT;
    DECLARE vrTotalCTSCustID BIGINT;
    ### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200) DEFAULT 'CTS_DC_Task_TransformAccountAssociationToCTSRetry' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    #SET		vrExecKey = CRC32((UUID_Short()));    
    #SET		vrNotes = '';		
    #SET 	vrStepID = 1;
	#SET 	vrStartTime = CURRENT_TIMESTAMP(4);  
    
    #INSERT INTO CTS_Log.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    #VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	  
	### PERFORMANCE: END  
    SET vrCTSCustID = (SELECT ParameterValue FROM CTS_DataCenter.SystemParameter WHERE ParameterID = 4);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
    CREATE TEMPORARY TABLE Temp_CTSCustomer (
			CTSCustID bigint unsigned NOT NULL AUTO_INCREMENT
            , MapAccountID BIGINT
			, SubscriberID int unsigned DEFAULT NULL
			, UserName varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
			, UserName2 varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
            
			, INDEX (CTSCustID, MapAccountID)
			           
			, INDEX  IX_CTSCustomer_UserName_UserName2 (SubscriberID, UserName)
			, INDEX  IX_CTSCustomer_UserName2 (SubscriberID, UserName2)
	) ENGINE=InnoDB;    
    
	INSERT INTO Temp_CTSCustomer(CTSCustID, SubscriberID, UserName, UserName2)
	SELECT 		cus.CTSCustID, cus.SubscriberID, cus.UserName
				, TRIM(LEADING sub.SubscriberPrefix FROM cus.UserName2 ) AS UserName2
	FROM 		CTS_DataCenter.CTSCustomer		AS cus
	LEFT JOIN	CTS_Admin.Subscriber			AS sub
				ON sub.SubscriberID = cus.SubscriberID
	WHERE		cus.CTSCustID > vrCTSCustID
	LIMIT		1000;	
    
    UPDATE 		Temp_CTSCustomer AS temp_cus
	INNER JOIN 	CTS_DataCenter.CustDCSAccount	AS cua
				ON  temp_cus.CTSCustID = cua.CTSCustID
	SET 		MapAccountID = AccountID;      
    
	# Turn on Transformed Account if matching 

	UPDATE		DCS_DataCenter.Account	AS acc
	INNER JOIN	Temp_CTSCustomer AS tmp_cus
				ON tmp_cus.SubscriberID = acc.SubscriberID
					AND tmp_cus.UserName = acc.LoginName
	SET			acc.IsCTSTransformed = 0		
	WHERE		tmp_cus.MapAccountID IS NULL;


	UPDATE		DCS_DataCenter.Account	AS acc
	INNER JOIN	Temp_CTSCustomer AS tmp_cus
				ON tmp_cus.SubscriberID = acc.SubscriberID
					AND tmp_cus.UserName2 = acc.LoginName
	SET			acc.IsCTSTransformed = 0		
	WHERE		tmp_cus.MapAccountID IS NULL; 		
    
    UPDATE 	CTS_DataCenter.SystemParameter
    SET 	ParameterValue = (SELECT IFNULL(MAX(CTSCustID),ParameterValue) FROM Temp_CTSCustomer)
    WHERE 	ParameterID = 4;

    #=======================    
	### PERFORMANCE
	#SET	vrEndTime = CURRENT_TIMESTAMP(4);	
    
    SELECT 	Min(CTSCustID), Max(CTSCustID), COUNT(1)
    INTO 	vrMinCTSCustID, vrMaxCTSCustID, vrTotalCTSCustID
    FROM	Temp_CTSCustomer;
    
    #UPDATE	CTS_Log.zzTracePerformance AS z
    #SET		z.EndTime = vrEndTime
	#		 , z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
    #        , z.TotalRecord = vrTotalCTSCustID
    #        , z.FromID 		= vrMinCTSCustID
    #        , z.ToID		= vrMaxCTSCustID
    #WHERE	 z.ExecKey = vrExecKey  AND z.StepID = vrStepID;
    ### PERFORMANCE: END
END$$
DELIMITER ;