/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_History_Archive`;

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
            - 20230707@Jonas.Huynh:		Renovate normal classification [Redmine ID: #189875]
            - 20240628@Thomas.Nguyen: 	Renovate CC phase 2 [Redmine ID: #205317]
            - 20241017@Victoria.Le:		Keeping the last record incorrectly  [Redmine ID: #212240]
            - 20250115@CaseyHuynh: 		Enhance SystemParameter when Archive Batch (IsDataChanged = 0) [Redmine ID: #216739]

		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_History_Archive(@IsDataExist);
	*/
	DECLARE lv_BatchSize 			INT;
	DECLARE lv_DateValid 			DATETIME;
	DECLARE lv_TakeDay 				INT;
    DECLARE lv_LastArchiveID 		BIGINT UNSIGNED;
	DECLARE lv_MaxArchiveID 		BIGINT UNSIGNED;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ArchiveHistory;
    CREATE TEMPORARY TABLE Temp_ArchiveHistory (
			ID 					BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	CustID 				BIGINT UNSIGNED 
		,	CTSCustID 			BIGINT UNSIGNED
		,	ParentID  			INT UNSIGNED  
		,	SportID 			SMALLINT UNSIGNED 
		,	CategoryID 			INT UNSIGNED 
		,	TurnoverRM 			DECIMAL(20 , 4 ) 
		,	WinlossRM 			DECIMAL(20 , 4 )
		,	BetCount 			BIGINT 
		,	ActiveDays 			INT
		,	TargetCC 			INT
		,	ActionType 			TINYINT 
		,	LastModifiedDate 	DATETIME 
		,	LastModifiedBy 		INT UNSIGNED 
		,	InsertDate 			DATETIME
        ,	PerformanceTime		DATETIME
		,	SourceTypeID	 	SMALLINT UNSIGNED
		,	Remark			 	VARCHAR(500)
		,	KEY 				IX_Temp_ArchiveHistory_CustIDSportID (CustID, SportID)
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
	INTO lv_LastArchiveID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 118; 
    
	SELECT ParameterValue
	INTO lv_TakeDay
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 119;
	
    SET	lv_DateValid = DATE_SUB(CURRENT_DATE(), INTERVAL lv_TakeDay DAY);

	SELECT MAX(tbl.ID)
    INTO lv_MaxArchiveID
    FROM (SELECT ID
		  FROM CTS_DataCenter.CTSCustomerClassification_BySport_History
		  WHERE ID > lv_LastArchiveID
				AND InsertDate < lv_DateValid
		  ORDER BY ID ASC
		  LIMIT lv_BatchSize) AS tbl;
	
    # RETURN SP IF NOT HAVE NEW DATA
	IF lv_MaxArchiveID IS NULL THEN
		SET op_IsDataExist = 0;
		LEAVE sp; 
	END IF;	

    INSERT INTO Temp_ArchiveHistory(ID,CustID,CTSCustID,ParentID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate,LastModifiedBy,InsertDate,PerformanceTime,SourceTypeID,Remark)
    SELECT 	ID 					
		,	CustID 				
		,	CTSCustID 	
		,	ParentID		
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
        ,   PerformanceTime
		,	SourceTypeID
		,	Remark
	FROM CTS_DataCenter.CTSCustomerClassification_BySport_History
    WHERE ID > lv_LastArchiveID AND ID <= lv_MaxArchiveID
		AND IsDataChanged = 1;
    
    IF EXISTS (SELECT 1 FROM Temp_ArchiveHistory) THEN
        
		ALTER TABLE Temp_ArchiveHistory ADD INDEX IX_Temp_ArchiveHistory_InsertDate (`InsertDate`);
        
        # Find custs who have the log ahead --> all logs at this phase should be removed
		INSERT INTO Temp_CustDataShouldBeRemoved(CustID, SportID)
		WITH cte_CurrentCust (CustID, SportID) AS
		(
			SELECT DISTINCT CustID, SportID
			FROM Temp_ArchiveHistory
		)
		SELECT DISTINCT c.CustID, c.SportID
		FROM cte_CurrentCust AS c
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON c.CustID = h.CustID AND c.SportID = h.SportID
		WHERE h.ID > lv_MaxArchiveID
			AND h.InsertDate < DATE(NOW());
        
        # find latest log to keep (not be removed)
        INSERT INTO Temp_HistoryShouldNotBeRemoved(ID)
        WITH cte_CustLogOrdered (CustID, SportID, ID, row_num) AS
		(
			SELECT 	t.CustID
				,	t.SportID
				, 	t.ID
                , 	ROW_NUMBER() OVER(PARTITION BY t.CustID, t.SportID ORDER BY t.InsertDate DESC, t.LastModifiedDate DESC, t.ID DESC) AS row_num  
			FROM Temp_ArchiveHistory AS t
				LEFT JOIN Temp_CustDataShouldBeRemoved AS r ON t.CustID = r.CustID AND t.SportID = r.SportID
			WHERE r.CustID IS NULL
				AND r.SportID IS NULL
		)
        SELECT ID
        FROM cte_CustLogOrdered
        WHERE row_num = 1;
    
		DELETE  
		FROM Temp_ArchiveHistory AS h
		WHERE EXISTS (	SELECT 1 
						FROM Temp_HistoryShouldNotBeRemoved AS k 
						WHERE k.ID = h.ID);		
        
        # take back the old log for the new active ones
        INSERT INTO Temp_ArchiveHistory(ID,CustID,CTSCustID,ParentID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate,LastModifiedBy,InsertDate,PerformanceTime,SourceTypeID,Remark)
		SELECT 	h.ID 					
			,	h.CustID 				
			,	h.CTSCustID 
			,	h.ParentID			
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
            ,	h.PerformanceTime
			,	h.SourceTypeID
			,	h.Remark
		FROM Temp_CustDataShouldBeRemoved AS k
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON k.CustID = h.CustID AND k.SportID = h.SportID
		WHERE h.ID < lv_LastArchiveID
			AND h.InsertDate < lv_DateValid;    
	
		DELETE h 
		FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS h
		WHERE EXISTS (SELECT 1 
					  FROM Temp_ArchiveHistory AS r 
					  WHERE r.ID = h.ID);
    
		 SELECT ID 					
			,	CustID 				
			,	CTSCustID 	
			,	ParentID		
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
            , 	PerformanceTime
			,	SourceTypeID
			,	Remark
		FROM Temp_ArchiveHistory;

    END IF;        
	
    SET op_IsDataExist = 1;
    
	UPDATE CTS_DataCenter.SystemParameter
	SET ParameterValue = lv_MaxArchiveID
	WHERE ParameterID = 118; 

END$$
DELIMITER ;