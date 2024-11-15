/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241021@Victoria.Le
	Task :	Create event to check data consistency - customer category
	DB:			
	
	Description: 

	Revisions:	
		- 20241021@Victoria.Le: 	Initial Writing [Redmine ID: #212321]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

DELIMITER |
ALTER EVENT EV_CTS_DC_DataConsistency_CustomerCategory
    ON SCHEDULE
		 EVERY '1 03' DAY_HOUR
    DO
      BEGIN
        DECLARE CONST_GENERAL_RuleID				INT DEFAULT 1;
        DECLARE CONST_BYSPORT_RuleID				INT DEFAULT 2;
		
        DECLARE lv_General_MinCustID				BIGINT DEFAULT 0;
        DECLARE lv_General_BatchSize				BIGINT DEFAULT 0;
        DECLARE lv_General_NextCustID				BIGINT DEFAULT 0;
		DECLARE lv_General_LogID					BIGINT DEFAULT 0;
		DECLARE lv_General_LogInfo					TEXT;
		
        DECLARE lv_BySport_MinCustID				BIGINT DEFAULT 0;
        DECLARE lv_BySport_BatchSize				BIGINT DEFAULT 0;
        DECLARE lv_BySport_NextCustID				BIGINT DEFAULT 0;
		DECLARE lv_BySport_LogID					BIGINT DEFAULT 0;
		DECLARE lv_BySport_LogInfo					TEXT;
		
		DECLARE lv_IsNew							TINYINT(1) DEFAULT 0;
		DECLARE lv_TrackingDate						DATE DEFAULT NOW();
		DECLARE lv_LastExecTime						DATETIME;
		DECLARE lv_LastStatus						VARCHAR(20);
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @errCode = RETURNED_SQLSTATE, @errMsg = MESSAGE_TEXT;
			INSERT INTO DataConsistencyMonitoring_ExecError (StoredProcedureName,EventName,ErrCode,ErrMsg,ErrDate,ErrDateTime)
			SELECT 'CTS_DC_DataConsistency_CustomerCategory_General_Check','EV_CTS_DC_DataConsistency_CustomerCategory',@errCode,@errMsg,NOW(),NOW();
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
			
		END;
        
		SELECT LastExecTime, Status
		INTO lv_LastExecTime, lv_LastStatus
		FROM CTS_DataCenter.SystemEventStatus
		WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
		
		IF (lv_LastStatus = 'Start') THEN
			IF NOT EXISTS (SELECT 1 
							FROM CTS_DataCenter.DataConsistencyMonitoring_ExecError 
							WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory' 
								AND ErrDate = DATE(lv_LastExecTime)) THEN
				INSERT INTO DataConsistencyMonitoring_ExecError (StoredProcedureName,EventName,ErrCode,ErrMsg,ErrDate,ErrDateTime)
				SELECT 'CTS_DC_DataConsistency_CustomerCategory_General_Check','EV_CTS_DC_DataConsistency_CustomerCategory',NULL,'LastStatus:Start',lv_LastExecTime,NOW();
			END IF;
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
			
		END IF;

		IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory' AND Status = 'Stop') THEN
			
			SELECT ParameterValue
			INTO lv_General_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 999;
			
			SELECT ParameterValue
			INTO lv_BySport_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 997;
			
			WHILE ((lv_General_MinCustID = 0 AND lv_General_NextCustID = 0)
					OR (lv_General_MinCustID < lv_General_NextCustID)) DO
				
				IF (lv_General_MinCustID = 0 AND lv_General_NextCustID = 0) THEN
					SET lv_IsNew = 1;
				ELSE 
					SET lv_IsNew = 0;
				END IF;
				
				SELECT ParameterValue
				INTO lv_General_MinCustID
				FROM CTS_DataCenter.SystemParameter
				WHERE ParameterID = 998;
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Start' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
                
				CAll CTS_DataCenter.CTS_DC_DataConsistency_CustomerCategory_General_Check(lv_General_BatchSize,lv_General_MinCustID,lv_General_NextCustID); 
				
				IF ((lv_General_MinCustID < lv_General_NextCustID) OR (lv_General_MinCustID > 0 AND lv_General_NextCustID = 0)) THEN
					
					UPDATE CTS_DataCenter.SystemParameter 
					SET ParameterValue = lv_General_NextCustID
					WHERE ParameterID = 998;
					
					IF (lv_IsNew = 1 AND lv_General_LogID = 0) THEN
						INSERT INTO CTS_DataCenter.DataConsistencyMonitoring_Log(RuleID,LogInfo,MinCustID,MaxCustID,CreatedDate,InsertedTime)
						WITH CTE_General AS (
							SELECT CONST_GENERAL_RuleID AS RuleID,GROUP_CONCAT(temp.CustID) AS LogInfo,lv_General_MinCustID AS MinCustID
								,CASE 	WHEN lv_General_MinCustID < lv_General_NextCustID THEN lv_General_NextCustID
										WHEN lv_General_MinCustID > 0 AND lv_General_NextCustID = 0 THEN lv_General_MinCustID 
										ELSE NULL END AS MaxCustID
								,lv_TrackingDate AS CreatedDate,NOW() AS InsertedTime
							FROM Temp_CustIssue AS temp
						)
						SELECT c.RuleID,c.LogInfo,c.MinCustID,c.MaxCustID,c.CreatedDate,c.InsertedTime
						FROM CTE_General AS c
						WHERE c.LogInfo IS NOT NULL
							AND EXISTS (SELECT 1 FROM DataConsistencyMonitoring AS r WHERE c.RuleID = r.RuleID AND r.IsActive = 1);
						
						SET lv_General_LogID = LAST_INSERT_ID();
					
					ELSEIF (lv_IsNew = 0 AND lv_General_LogID > 0) THEN
						SELECT GROUP_CONCAT(temp.CustID)
						INTO lv_General_LogInfo
						FROM Temp_CustIssue AS temp
						WHERE EXISTS (SELECT 1 FROM DataConsistencyMonitoring WHERE RuleID = CONST_GENERAL_RuleID AND IsActive = 1);
						
						INSERT INTO CTS_DataCenter.DataConsistencyMonitoring_Log(RuleID,LogInfo,MinCustID,MaxCustID,CreatedDate,InsertedTime)
						SELECT CONST_GENERAL_RuleID AS RuleID,GROUP_CONCAT(temp.CustID) AS LogInfo,lv_General_MinCustID AS MinCustID
								,CASE 	WHEN lv_General_MinCustID < lv_General_NextCustID THEN lv_General_NextCustID
										WHEN lv_General_MinCustID > 0 AND lv_General_NextCustID = 0 THEN lv_General_MinCustID 
										ELSE NULL END AS MaxCustID
								,lv_TrackingDate AS CreatedDate,NOW() AS InsertedTime
						FROM Temp_CustIssue AS temp
						WHERE lv_General_LogInfo IS NOT NULL
							AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.DataConsistencyMonitoring_Log AS l WHERE l.ID = lv_General_LogID)
							AND EXISTS (SELECT 1 FROM DataConsistencyMonitoring AS r WHERE c.RuleID = r.RuleID AND r.IsActive = 1);
						
						UPDATE CTS_DataCenter.DataConsistencyMonitoring_Log AS temp
						SET 	temp.MaxCustID = CASE 	WHEN lv_General_MinCustID < lv_General_NextCustID THEN lv_General_NextCustID
														WHEN lv_General_MinCustID > 0 AND lv_General_NextCustID = 0 THEN lv_General_MinCustID 
														ELSE NULL END
							,	temp.LogInfo = CONCAT(temp.LogInfo,",",lv_General_LogInfo)
							,	temp.LastModifiedDate = NOW()
						WHERE temp.ID =  lv_General_LogID AND lv_General_LogInfo IS NOT NULL;

					END IF;
					
				END IF;
				
			END WHILE;
			
			SET lv_IsNew = 0;
			
			-- BySport
			WHILE ((lv_BySport_MinCustID = 0 AND lv_BySport_NextCustID = 0)
					OR (lv_BySport_MinCustID < lv_BySport_NextCustID)) DO
				
				IF (lv_BySport_MinCustID = 0 AND lv_BySport_NextCustID = 0) THEN
					SET lv_IsNew = 1;
				ELSE 
					SET lv_IsNew = 0;
				END IF;
				
				SELECT ParameterValue
				INTO lv_BySport_MinCustID
				FROM CTS_DataCenter.SystemParameter
				WHERE ParameterID = 996;
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Start' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory'
					AND Status <> 'Start' ;
				
				CAll CTS_DataCenter.CTS_DC_DataConsistency_CustomerCategory_BySport_Check(lv_BySport_BatchSize,lv_BySport_MinCustID,lv_BySport_NextCustID); 
				
				IF ((lv_BySport_MinCustID < lv_BySport_NextCustID) OR (lv_BySport_MinCustID > 0 AND lv_BySport_NextCustID = 0)) THEN
					
					UPDATE CTS_DataCenter.SystemParameter 
					SET ParameterValue = lv_BySport_NextCustID
					WHERE ParameterID = 996;
					
					IF (lv_IsNew = 1 AND lv_BySport_LogID = 0) THEN
						INSERT INTO CTS_DataCenter.DataConsistencyMonitoring_Log(RuleID,LogInfo,MinCustID,MaxCustID,CreatedDate,InsertedTime)
						WITH CTE_BySport AS (
							SELECT CONST_BySport_RuleID AS RuleID,GROUP_CONCAT(temp.CustID) AS LogInfo,lv_BySport_MinCustID AS MinCustID
								,CASE 	WHEN lv_BySport_MinCustID < lv_BySport_NextCustID THEN lv_BySport_NextCustID
										WHEN lv_BySport_MinCustID > 0 AND lv_BySport_NextCustID = 0 THEN lv_BySport_MinCustID 
										ELSE NULL END AS MaxCustID
								,lv_TrackingDate AS CreatedDate,NOW() AS InsertedTime
							FROM Temp_CustIssue_BySport AS temp
						)
						SELECT c.RuleID,c.LogInfo,c.MinCustID,c.MaxCustID,c.CreatedDate,c.InsertedTime
						FROM CTE_BySport AS c
						WHERE c.LogInfo IS NOT NULL
							AND EXISTS (SELECT 1 FROM DataConsistencyMonitoring AS r WHERE c.RuleID = r.RuleID AND r.IsActive = 1);
						
						SET lv_BySport_LogID = LAST_INSERT_ID();
					
					ELSEIF (lv_IsNew = 0 AND lv_BySport_LogID > 0) THEN
						SELECT GROUP_CONCAT(temp.CustID)
						INTO lv_BySport_LogInfo
						FROM Temp_CustIssue_BySport AS temp
						WHERE EXISTS (SELECT 1 FROM DataConsistencyMonitoring WHERE RuleID = CONST_BySport_RuleID AND IsActive = 1);
						
						INSERT INTO CTS_DataCenter.DataConsistencyMonitoring_Log(RuleID,LogInfo,MinCustID,MaxCustID,CreatedDate,InsertedTime)
						SELECT CONST_BySport_RuleID AS RuleID,GROUP_CONCAT(temp.CustID) AS LogInfo,lv_BySport_MinCustID AS MinCustID
								,CASE 	WHEN lv_BySport_MinCustID < lv_BySport_NextCustID THEN lv_BySport_NextCustID
										WHEN lv_BySport_MinCustID > 0 AND lv_BySport_NextCustID = 0 THEN lv_BySport_MinCustID 
										ELSE NULL END AS MaxCustID
								,lv_TrackingDate AS CreatedDate,NOW() AS InsertedTime
						FROM Temp_CustIssue_BySport AS temp
						WHERE lv_BySport_LogID IS NOT NULL
							AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.DataConsistencyMonitoring_Log AS l WHERE l.ID = lv_BySport_LogID)
							AND EXISTS (SELECT 1 FROM DataConsistencyMonitoring AS r WHERE c.RuleID = r.RuleID AND r.IsActive = 1);
						
						UPDATE CTS_DataCenter.DataConsistencyMonitoring_Log AS temp
						SET 	temp.MaxCustID = CASE 	WHEN lv_BySport_MinCustID < lv_BySport_NextCustID THEN lv_BySport_NextCustID
														WHEN lv_BySport_MinCustID > 0 AND lv_BySport_NextCustID = 0 THEN lv_BySport_MinCustID 
														ELSE NULL END
							,	temp.LogInfo = CONCAT(temp.LogInfo,",",lv_BySport_LogInfo)
							,	temp.LastModifiedDate = NOW()
						WHERE temp.ID =  lv_BySport_LogID AND lv_BySport_LogInfo IS NOT NULL;

					END IF;
					
				END IF;
				
			END WHILE;
			
			IF (lv_General_NextCustID = 0 AND lv_BySport_NextCustID = 0) THEN
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Stop' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
			END IF;
            
		END IF;
 END |

DELIMITER ;