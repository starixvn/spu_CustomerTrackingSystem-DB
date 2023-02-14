/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_History_Archive`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_History_Archive`(
    	OUT	op_IsDataExist		SMALLINT
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*
		Created:	20220909@Aries.Nguyen	
		Task :		Clean-up Classification BySport History are not used. Only take 30 lastest days.
		DB:			CTS_DataCenter
		Original:
		
		Revisions:	
			- 20220909@Aries.Nguyen:	Created  [Redmine ID: #176992] 
			- 20230210@Long.Luu: 		Fix Customer Classification Log [Redmine ID: #183279] 
            
		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_History_Archive(@IsDataExist);
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
			ID 					BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	CustID 				BIGINT UNSIGNED 
		,	CTSCustID 			BIGINT UNSIGNED 
		,	SportID 			SMALLINT UNSIGNED 
		,	CategoryID 			SMALLINT UNSIGNED 
		,	TurnoverRM 			DECIMAL(20 , 4 ) 
		,	WinlossRM 			DECIMAL(20 , 4 )
		,	BetCount 			BIGINT 
		,	ActiveDays 			INT
		,	TargetCC 			SMALLINT
		,	ActionType 			TINYINT 
		,	LastModifiedDate 	DATETIME 
		,	LastModifiedBy 		INT UNSIGNED 
		,	InsertDate 			DATETIME 
		,	KEY 				IX_Temp_History_CustIDSportID (CustID, SportID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustDataShouldBeRemoved;
    CREATE TEMPORARY TABLE Temp_CustDataShouldBeRemoved (
			CustID  			BIGINT UNSIGNED
		,	SportID				SMALLINT UNSIGNED
        ,	PRIMARY KEY (CustID, SportID)
    ); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_HistoryShouldNotBeRemoved;
    CREATE TEMPORARY TABLE Temp_HistoryShouldNotBeRemoved (
			ID  BIGINT UNSIGNED PRIMARY KEY
    );                   
	
    SELECT ParameterValue
	INTO lv_BatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 117; 
    
    SELECT ParameterValue
	INTO lv_LastID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 118; 
    
	SELECT ParameterValue
	INTO lv_TakeDay
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 119;
	
    SET	lv_DateValid = DATE_SUB(CURRENT_DATE(), INTERVAL lv_TakeDay DAY);

	SELECT MAX(tbl.ID)
    INTO lv_NextLastID
    FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_BySport_History
		  WHERE ID > lv_LastID
		  ORDER BY ID ASC
		  LIMIT lv_BatchSize) AS tbl;
	
	IF lv_NextLastID IS NULL THEN
		SET op_IsDataExist = 0;
		LEAVE sp; 
	END IF;

    INSERT INTO Temp_History(ID,CustID,CTSCustID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate,LastModifiedBy,InsertDate)
    SELECT 	ID 					
		,	CustID 				
		,	CTSCustID 			
		,	SportID 			
		,	CategoryID 			
		,	TurnoverRM 			
		,	WinlossRM 			
		,	BetCount 			
		,	ActiveDays 			
		,	TargetCC 				
		,	ActionType 			
		,	LastModifiedDate 	
		,	LastModifiedBy 		
		,	InsertDate 				 
	FROM CTS_DataCenter.CTSCustomerClassification_BySport_History
    WHERE ID BETWEEN lv_LastID AND lv_NextLastID
        AND InsertDate <= lv_DateValid;
    
    IF EXISTS (SELECT 1 FROM Temp_History) THEN
		# Keep the max pointer
		SELECT MAX(ID)
		INTO lv_LastIDValid
		FROM Temp_History;
        
		ALTER TABLE Temp_History ADD INDEX IX_Temp_History_LastModifiedDate (`LastModifiedDate`);
        
        # Find custs who have the log ahead --> all logs at this phase should be removed
		INSERT INTO Temp_CustDataShouldBeRemoved(CustID, SportID)
		WITH cte_CurrentCust (CustID, SportID) AS
		(
			SELECT DISTINCT CustID, SportID
			FROM Temp_History
		)
		SELECT DISTINCT c.CustID, c.SportID
		FROM cte_CurrentCust AS c
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON c.CustID = h.CustID AND c.SportID = h.SportID
		WHERE h.ID > lv_NextLastID;
        
        # find latest log to keep (not be removed)
        INSERT INTO Temp_HistoryShouldNotBeRemoved(ID)
        WITH cte_CustLogOrdered (CustID, SportID, ID, row_num) AS
		(
			SELECT 	t.CustID
				,	t.SportID
				, 	t.ID
                , 	ROW_NUMBER() OVER(PARTITION BY t.CustID, t.SportID ORDER BY t.LastModifiedDate DESC) AS row_num  
			FROM Temp_History AS t
				LEFT JOIN Temp_CustDataShouldBeRemoved AS r ON t.CustID = r.CustID AND t.SportID = r.SportID
			WHERE r.CustID IS NULL
				AND r.SportID IS NULL
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
        INSERT INTO Temp_History(ID,CustID,CTSCustID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate,LastModifiedBy,InsertDate )
		SELECT 	h.ID 					
			,	h.CustID 				
			,	h.CTSCustID 			
			,	h.SportID 			
			,	h.CategoryID 			
			,	h.TurnoverRM 			
			,	h.WinlossRM 			
			,	h.BetCount 			
			,	h.ActiveDays 			
			,	h.TargetCC 				
			,	h.ActionType 			
			,	h.LastModifiedDate 	
			,	h.LastModifiedBy 		
			,	h.InsertDate 				 		 
		FROM Temp_CustDataShouldBeRemoved AS k
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON k.CustID = h.CustID AND k.SportID = h.SportID
		WHERE h.ID < lv_LastID
			AND h.InsertDate <= lv_DateValid;    
	
		DELETE  
		FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS h
		WHERE EXISTS (SELECT 1 
					  FROM Temp_History AS r 
					  WHERE r.ID = h.ID);
    
		 SELECT ID 					
			,	CustID 				
			,	CTSCustID 			
			,	SportID 			
			,	CategoryID 			
			,	TurnoverRM 			
			,	WinlossRM 			
			,	BetCount 			
			,	ActiveDays 			
			,	TargetCC 				
			,	ActionType 			
			,	LastModifiedDate 	
			,	LastModifiedBy 		
			,	InsertDate 		
		FROM Temp_History;
		
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = lv_LastIDValid
		WHERE ParameterID = 118;

		SET op_IsDataExist = 1;
        
        LEAVE sp; 
    END IF;
    
    SELECT ID
	INTO lv_NextIDInvalid
	FROM CTS_DataCenter.CTSCustomerClassification_BySport_History 
	WHERE ID BETWEEN lv_LastID AND lv_NextLastID
		AND InsertDate > lv_DateValid 
	ORDER BY ID ASC
	LIMIT 1;

	IF lv_NextIDInvalid IS NOT NULL THEN
		UPDATE CTS_DataCenter.SystemParameter
		SET ParameterValue = lv_NextIDInvalid
		WHERE ParameterID = 118;

		SET op_IsDataExist = 0;

		LEAVE sp; 
	END IF;
    
    SELECT InsertDate
	INTO lv_NextDate
	FROM CTS_DataCenter.CTSCustomerClassification_BySport_History 
	WHERE  ID > lv_NextLastID
	ORDER BY ID ASC
	LIMIT 1;

	UPDATE CTS_DataCenter.SystemParameter
	SET ParameterValue = lv_NextLastID
	WHERE ParameterID = 118; 

	IF lv_NextDate <= lv_DateValid THEN
		SET op_IsDataExist = 1;
	ELSE
		SET op_IsDataExist = 0;
	END IF;

END$$
DELIMITER ;