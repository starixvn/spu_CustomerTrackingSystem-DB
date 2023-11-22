/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_History_Archive`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_History_Archive`(
    	OUT	op_IsDataExist		SMALLINT
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*
		Created:	20210901@Aries.Nguyen	
		Task :		Clean-up Classification History are not used. Only take 30 lastest days.
		DB:			CTS_DataCenter
		Original:
		
		Revisions:	
			- 20210901@Aries.Nguyen: 	Created [RedmineID: #160758]	
			- 20220519@Aries.Nguyen: 	Renovate the Category Log History[Redmine ID: #172560]
			- 20220909@Aries.Nguyen: 	Handle lv_NextLastID is null [Redmine ID: #176992] 
			- 20230210@Long.Luu: Fix 	Customer Classification Log [Redmine ID: #183279] 
			- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
			- 20230404@Victoria.Le		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeID [Redmine ID: #185319] 
			- 20230428@Jonas.Huynh: 	Realtime Renovation [Redmine ID: #186678]
			- 20231108@Victoria.Le: 	Add First5TWGBTicketCount [Redmine ID: #195060]
             
		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_History_DataChanged_CleanUp(@IsDataExist);
	*/
	DECLARE lv_BatchSize 		INT;
	DECLARE lv_DateValid 		DATE;
    DECLARE lv_NextDate			DATE;
	DECLARE lv_TakeDay 			INT;
    DECLARE lv_LastID 			BIGINT UNSIGNED;
	DECLARE lv_NextLastID 		BIGINT UNSIGNED;
	DECLARE lv_LastIDValid 		BIGINT UNSIGNED;
	DECLARE lv_EndID 			BIGINT UNSIGNED;
	DECLARE lv_NextIDInvalid 	BIGINT UNSIGNED;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_History;
    CREATE TEMPORARY TABLE Temp_History (
			ID  					BIGINT UNSIGNED 
		,	CustID  				BIGINT UNSIGNED
		,	CTSCustID  				BIGINT UNSIGNED
		,	SportGroupID  			SMALLINT UNSIGNED 
		,	CategoryID  			SMALLINT  
		,	TurnoverRM  			DECIMAL(20 , 4 )  
		,	WinlossRM  				DECIMAL(20 , 4 )  
		,	BetCount  				BIGINT  
		,	ActiveDays  			INT  
		,	RobotCounter  			SMALLINT  
		,	ProbationPeriodWinloss  DECIMAL(20,4)  
		,	TargetCC  				SMALLINT  
		,	SourceTypeID  			SMALLINT UNSIGNED  
		,	FromCategoryID  		SMALLINT UNSIGNED  
		,	ToCategoryID  			SMALLINT UNSIGNED  
		,	IsAppliedCC  			BIT(1)
		,	IsDataChanged  			BIT(1)
		,	ActionType  			TINYINT  
		,	IsAuto  				BIT(1)  
		,	LastModifiedDate  		DATETIME  
		,	LastModifiedBy  		INT UNSIGNED  
		,	InsertDate  			DATETIME
		,	TaggingType  			SMALLINT
		,	TargetDangerLevel1  	SMALLINT  
		,	IsAppliedDangerLevel1  	BIT(1)
		,	TWGroupBettingRate  	DECIMAL(10,4)  
		,	TWTicketRejectRate  	DECIMAL(10,4)  
		,	TWBetCount  			BIGINT  
		,	TWDesktopUsageRate  	DECIMAL(10,4)  
        ,	Remark 					VARCHAR(500)
		,	IsDirect				BIT(1) 
		,	TVSRequestID			BIGINT UNSIGNED 
        ,	IsFromTVS 				BIT 
		,	IsFromTW 				BIT
		,	IsFromCTS 				BIT
		,	IsFromAI 				BIT 
		,	IsFromImperva			BIT
		,	IsParlay				BIT
		,	SportType				SMALLINT
		,	IssueTypeID				TINYINT
        ,	PerformanceTime			DATETIME
        ,	First5TWGBTicketCount	TINYINT UNSIGNED
		,	PRIMARY KEY (ID)
		,	KEY 					IX_CTSCustomerClassification_History_CustID (CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDataShouldBeRemoved;
    CREATE TEMPORARY TABLE Temp_CustDataShouldBeRemoved (
			CustID  				BIGINT UNSIGNED PRIMARY KEY
    ); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_HistoryShouldNotBeRemoved;
    CREATE TEMPORARY TABLE Temp_HistoryShouldNotBeRemoved (
			ID  BIGINT UNSIGNED PRIMARY KEY
    );            

    SELECT ParameterValue
	INTO lv_LastID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 35; 
    
    SELECT ParameterValue
	INTO lv_BatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 40; 

	SELECT ParameterValue
	INTO lv_TakeDay
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 41;
	
    SET	lv_DateValid = DATE_SUB(CURRENT_DATE(), INTERVAL lv_TakeDay DAY);

	SELECT MAX(tbl.ID)
    INTO lv_NextLastID
    FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_History
		  WHERE ID > lv_LastID
		  ORDER BY ID ASC
		  LIMIT lv_BatchSize) AS tbl;
	
	IF lv_NextLastID IS NULL THEN
		SET op_IsDataExist = 0;
		LEAVE sp; 
	END IF;

    INSERT INTO Temp_History(	
			ID
		,	CustID
		,	CTSCustID
		,	SportGroupID
		,	CategoryID,TurnoverRM 
		,	WinlossRM
		,	BetCount
		,	ActiveDays
		,	RobotCounter
		,	ProbationPeriodWinloss
		,	TargetCC
		,	SourceTypeID
		,	FromCategoryID
		,	ToCategoryID
		,	IsAppliedCC
		,	IsDataChanged
		,	ActionType
		,	IsAuto
		,	LastModifiedDate
		,	LastModifiedBy
		,	InsertDate
		,	TaggingType
		,	TargetDangerLevel1
		,	IsAppliedDangerLevel1
		,	TWGroupBettingRate
		,	TWTicketRejectRate
		,	TWBetCount
		,	TWDesktopUsageRate,Remark,IsDirect,TVSRequestID
		,	IsFromTVS
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromImperva
		,	IsParlay
		,	SportType
		,	IssueTypeID
        ,	PerformanceTime
        ,	First5TWGBTicketCount
	)
    SELECT 	ID  					
		,	CustID  				
		,	CTSCustID  				
		,	SportGroupID  			
		,	CategoryID  			
		,	TurnoverRM  			
		,	WinlossRM  				
		,	BetCount  				
		,	ActiveDays  			
		,	RobotCounter  		
		,	ProbationPeriodWinloss  
		,	TargetCC  				
		,	SourceTypeID  			
		,	FromCategoryID  		
		,	ToCategoryID  			
		,	IsAppliedCC  			
		,	IsDataChanged  			
		,	ActionType  			
		,	IsAuto  				
		,	LastModifiedDate  		
		,	LastModifiedBy  		
		,	InsertDate  			
		,	TaggingType  			
		,	TargetDangerLevel1  	
		,	IsAppliedDangerLevel1  	
		,	TWGroupBettingRate  	
		,	TWTicketRejectRate  	
		,	TWBetCount  			
		,	TWDesktopUsageRate  
        ,	Remark 			
		,	IsDirect
		,	TVSRequestID
		,	IsFromTVS 				 
		,	IsFromTW 				
		,	IsFromCTS 				
		,	IsFromAI 	
		,	IsFromImperva
		,	IsParlay
		,	SportType
		,	IssueTypeID
        ,	PerformanceTime
        ,	First5TWGBTicketCount
	FROM CTS_DataCenter.CTSCustomerClassification_History
    WHERE ID BETWEEN lv_LastID AND lv_NextLastID
		AND IsDataChanged = 1
        AND InsertDate < lv_DateValid;    
    
    IF EXISTS (SELECT 1 FROM Temp_History) THEN
		# Keep the max pointer
		SELECT MAX(ID)
		INTO lv_LastIDValid
		FROM Temp_History;
    
		ALTER TABLE Temp_History ADD INDEX IX_Temp_History_InsertDateLastModifiedDate (`InsertDate`, `LastModifiedDate`);
		
        # Find custs who have the log ahead --> all logs at this phase should be removed
		INSERT INTO Temp_CustDataShouldBeRemoved(CustID)
		WITH cte_CurrentCust (CustID) AS
		(
			SELECT DISTINCT CustID
			FROM Temp_History
		)
		SELECT DISTINCT c.CustID
		FROM cte_CurrentCust AS c
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON c.CustID = h.CustID
		WHERE h.ID > lv_LastIDValid
			AND h.IsDataChanged = 1;
        
        # find latest log to keep (not be removed)
        INSERT INTO Temp_HistoryShouldNotBeRemoved(ID)
        WITH cte_CustLogOrdered (CustID, ID, row_num) AS
		(
			SELECT 	t.CustID
				, 	t.ID
                , 	ROW_NUMBER() OVER(PARTITION BY t.CustID ORDER BY t.InsertDate DESC, t.LastModifiedDate DESC) AS row_num  
			FROM Temp_History AS t
				LEFT JOIN Temp_CustDataShouldBeRemoved AS r ON t.CustID = r.CustID
			WHERE r.CustID IS NULL
		)
        SELECT ID
        FROM cte_CustLogOrdered
        WHERE row_num = 1;
    
		DELETE  
		FROM Temp_History AS h
		WHERE EXISTS (	SELECT 1 
						FROM Temp_HistoryShouldNotBeRemoved AS k 
						WHERE k.ID = h.ID);		
        
        # take back the old log for the new active ones
        INSERT INTO Temp_History(
				ID
			,	CustID
			,	CTSCustID
			,	SportGroupID
			,	CategoryID,TurnoverRM 
			,	WinlossRM
			,	BetCount
			,	ActiveDays
			,	RobotCounter
			,	ProbationPeriodWinloss
			,	TargetCC
			,	SourceTypeID
			,	FromCategoryID
			,	ToCategoryID
			,	IsAppliedCC
			,	IsDataChanged
			,	ActionType
			,	IsAuto
			,	LastModifiedDate
			,	LastModifiedBy
			,	InsertDate
			,	TaggingType
			,	TargetDangerLevel1
			,	IsAppliedDangerLevel1
			,	TWGroupBettingRate
			,	TWTicketRejectRate
			,	TWBetCount
			,	TWDesktopUsageRate,Remark,IsDirect,TVSRequestID
			,	IsFromTVS
			,	IsFromTW
			,	IsFromCTS
			,	IsFromAI
			,	IsFromImperva
			,	IsParlay
			,	SportType
			,	IssueTypeID
            ,	PerformanceTime
            ,	First5TWGBTicketCount
		)
		SELECT 	ID  					
			,	h.CustID  				
			,	CTSCustID  				
			,	SportGroupID  			
			,	CategoryID  			
			,	TurnoverRM  			
			,	WinlossRM  				
			,	BetCount  				
			,	ActiveDays  			
			,	RobotCounter  		
			,	ProbationPeriodWinloss  
			,	TargetCC  				
			,	SourceTypeID  			
			,	FromCategoryID  		
			,	ToCategoryID  			
			,	IsAppliedCC  			
			,	IsDataChanged  			
			,	ActionType  			
			,	IsAuto  				
			,	LastModifiedDate  		
			,	LastModifiedBy  		
			,	InsertDate  			
			,	TaggingType  			
			,	TargetDangerLevel1  	
			,	IsAppliedDangerLevel1  	
			,	TWGroupBettingRate  	
			,	TWTicketRejectRate  	
			,	TWBetCount  			
			,	TWDesktopUsageRate  
			,	Remark 			
			,	IsDirect
			,	TVSRequestID
			,	IsFromTVS 				 
			,	IsFromTW 				
			,	IsFromCTS 				
			,	IsFromAI 	
			,	IsFromImperva
			,	IsParlay
			,	SportType
			,	IssueTypeID
            ,	PerformanceTime
            ,	First5TWGBTicketCount
		FROM Temp_CustDataShouldBeRemoved AS k
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON k.CustID = h.CustID
		WHERE h.ID < lv_LastID
			AND h.IsDataChanged = 1
			AND InsertDate <= lv_DateValid;     
            
		DELETE  
		FROM CTS_DataCenter.CTSCustomerClassification_History AS h
		WHERE EXISTS (SELECT 1 
					  FROM Temp_History AS r 
					  WHERE r.ID = h.ID);
    
		SELECT	ID  					
			,	CustID  				
			,	CTSCustID  				
			,	SportGroupID  			
			,	CategoryID  			
			,	TurnoverRM  			
			,	WinlossRM  				
			,	BetCount  				
			,	ActiveDays  			
			,	RobotCounter  		
			,	ProbationPeriodWinloss  
			,	TargetCC  				
			,	SourceTypeID  			
			,	FromCategoryID  		
			,	ToCategoryID  			
			,	IsAppliedCC  			
			,	IsDataChanged  			
			,	ActionType  			
			,	IsAuto  				
			,	LastModifiedDate  		
			,	LastModifiedBy  		
			,	InsertDate  			
			,	TaggingType  			
			,	TargetDangerLevel1  	
			,	IsAppliedDangerLevel1  	
			,	TWGroupBettingRate  	
			,	TWTicketRejectRate  	
			,	TWBetCount  			
			,	TWDesktopUsageRate 
            ,	Remark 	
			,	IsDirect
			,	TVSRequestID
            ,	IsFromTVS 				 
			,	IsFromTW 				
			,	IsFromCTS 				
			,	IsFromAI 	
			,	IsFromImperva
			,	IsParlay
			,	SportType
			,	IssueTypeID
            ,	PerformanceTime
            ,	First5TWGBTicketCount
		FROM Temp_History;
		
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = lv_LastIDValid
		WHERE ParameterID = 35;

		SET op_IsDataExist = 1;
        
        LEAVE sp; 
    END IF;
    
    SELECT ID
	INTO lv_NextIDInvalid
	FROM CTS_DataCenter.CTSCustomerClassification_History 
	WHERE ID BETWEEN lv_LastID AND lv_NextLastID
		AND InsertDate > lv_DateValid 
		AND IsDataChanged = 1
	ORDER BY ID ASC
	LIMIT 1;

	IF lv_NextIDInvalid IS NOT NULL THEN
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = lv_NextIDInvalid
		WHERE ParameterID = 35;

		SET op_IsDataExist = 0;

		LEAVE sp; 
	END IF;
    
    SELECT InsertDate
	INTO lv_NextDate
	FROM CTS_DataCenter.CTSCustomerClassification_History 
	WHERE  ID > lv_NextLastID
	ORDER BY ID ASC
	LIMIT 1;

	UPDATE CTS_DataCenter.SystemParameter
	SET ParameterValue = lv_NextLastID
	WHERE ParameterID = 35; 

	IF lv_NextDate <= lv_DateValid THEN
		SET op_IsDataExist = 1;
	ELSE
		SET op_IsDataExist = 0;
	END IF;

END$$
DELIMITER ;