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
			- 20220909@Aries.Nguyen:Created  [Redmine ID: #176992] 
            
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
		,	KEY 				IX_Temp_History_CustID (CustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_History_Remove;
    CREATE TEMPORARY TABLE Temp_History_Remove (
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

    INSERT INTO Temp_History(ID,CustID,CTSCustID,SportID,CategoryID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,ActionType,LastModifiedDate,LastModifiedBy,InsertDate )
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
		SELECT MAX(ID)
		INTO lv_LastIDValid
		FROM Temp_History;
        
		INSERT INTO Temp_History_Remove(ID)
		SELECT tmp.ID
		FROM Temp_History AS tmp
		WHERE EXISTS(SELECT 1 
					 FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS his
					 WHERE his.CustID = tmp.CustID
						AND his.ID > tmp.ID);
    
		DELETE  
		FROM Temp_History AS his
		WHERE NOT EXISTS (SELECT 1 
						  FROM Temp_History_Remove AS rm 
						  WHERE rm.ID = his.ID);
	
		DELETE  
		FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS his
		WHERE EXISTS (SELECT 1 
					  FROM Temp_History_Remove AS rm 
					  WHERE rm.ID = his.ID);
    
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