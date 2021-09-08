/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_History_DataChanged_CleanUp`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_History_DataChanged_CleanUp`(
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
			- 20210901@Aries.Nguyen: Created [RedmineID: #160758]	
            
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
		,	RobotCounter  			DECIMAL(20,4)  
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
		,	PRIMARY KEY (ID)
		,	KEY 					IX_CTSCustomerClassification_History_CustID (CustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_History_Remove;
    CREATE TEMPORARY TABLE Temp_History_Remove (
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

    INSERT INTO Temp_History(ID, CustID, CTSCustID, SportGroupID, CategoryID,TurnoverRM , WinlossRM, BetCount, ActiveDays, RobotCounter, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsAppliedCC, IsDataChanged, ActionType, IsAuto, LastModifiedDate, LastModifiedBy, InsertDate, TaggingType, TargetDangerLevel1, IsAppliedDangerLevel1, TWGroupBettingRate, TWTicketRejectRate, TWBetCount, TWDesktopUsageRate  )
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
	FROM CTS_DataCenter.CTSCustomerClassification_History
    WHERE ID BETWEEN lv_LastID AND lv_NextLastID
		AND IsDataChanged = 1
        AND InsertDate <= lv_DateValid;
    
    IF EXISTS (SELECT 1 FROM Temp_History) THEN
		SELECT MAX(ID)
		INTO lv_LastIDValid
		FROM Temp_History;
        
		INSERT INTO Temp_History_Remove(ID)
		SELECT tmp.ID
		FROM Temp_History AS tmp
		WHERE EXISTS(SELECT 1 
					 FROM CTS_DataCenter.CTSCustomerClassification_History AS his
					 WHERE his.CustID = tmp.CustID
						AND his.IsDataChanged = 1
						AND his.ID > tmp.ID);
    
		DELETE  
		FROM Temp_History AS his
		WHERE NOT EXISTS (SELECT 1 
						  FROM Temp_History_Remove AS rm 
						  WHERE rm.ID = his.ID);
	
		DELETE  
		FROM CTS_DataCenter.CTSCustomerClassification_History AS his
		WHERE EXISTS (SELECT 1 
					  FROM Temp_History_Remove AS rm 
					  WHERE rm.ID = his.ID);
    
		 SELECT ID  					
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