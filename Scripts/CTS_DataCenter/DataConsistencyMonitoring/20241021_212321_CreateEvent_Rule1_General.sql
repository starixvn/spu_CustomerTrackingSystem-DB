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
CREATE EVENT EV_CTS_DC_DataConsistency_CustomerCategory
    ON SCHEDULE
		 EVERY '1 03' DAY_HOUR
    DO
      BEGIN
        DECLARE CONST_GENERAL_RuleID		INT DEFAULT 1;
        DECLARE CONST_BYSPORT_RuleID		INT DEFAULT 2;
		
        DECLARE lv_MinCustID				BIGINT DEFAULT 0;
        DECLARE lv_BatchSize				BIGINT DEFAULT 0;
        DECLARE lv_NextCustID				BIGINT DEFAULT 0;
		DECLARE lv_IsNew					TINYINT(1) DEFAULT 0;
		DECLARE lv_TrackingDate				DATE DEFAULT NOW();
		DECLARE lv_LogID					BIGINT DEFAULT 0;
		DECLARE lv_LogInfo					TEXT;
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
		END;

		IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory' AND Status = 'Stop') THEN
			
			SELECT ParameterValue
			INTO lv_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 999;
			
			WHILE ((lv_MinCustID = 0 AND lv_NextCustID = 0)
					OR (lv_MinCustID < lv_NextCustID)) DO
				
				IF (lv_MinCustID = 0 AND lv_NextCustID = 0) THEN
					SET lv_IsNew = 1;
				END IF;
				
				SELECT ParameterValue
				INTO lv_MinCustID
				FROM CTS_DataCenter.SystemParameter
				WHERE ParameterID = 998;
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Start' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
                
				CAll CTS_DataCenter.CTS_DC_DataConsistency_CustomerCategory_General_Check(lv_BatchSize,lv_MinCustID,lv_NextCustID); 
				
				IF ((lv_MinCustID < lv_NextCustID) OR (lv_MinCustID > 0 AND lv_NextCustID = 0)) THEN
					
					UPDATE CTS_DataCenter.SystemParameter 
					SET ParameterValue = lv_NextCustID
					WHERE ParameterID = 998;
					
					IF (lv_IsNew = 1 AND lv_LogID = 0) THEN
						INSERT INTO CTS_DataCenter.DataConsistencyMonitoring_Log(RuleID,LogInfo,MinCustID,MaxCustID,CreatedDate,InsertedTime)
						SELECT CONST_GENERAL_RuleID,GROUP_CONCAT(temp.CustID),lv_MinCustID
							,CASE 	WHEN lv_MinCustID < lv_NextCustID THEN lv_NextCustID
									WHEN lv_MinCustID > 0 AND lv_NextCustID = 0 THEN lv_MinCustID 
									ELSE NULL END AS MaxCustID
							,lv_TrackingDate,NOW()
						FROM Temp_CustIssue AS temp
						WHERE EXISTS (SELECT 1 FROM DataConsistencyMonitoring WHERE RuleID = CONST_GENERAL_RuleID AND IsActive = 1);
						
						SET lv_LogID = LAST_INSERT_ID();
					
					ELSEIF (lv_IsNew = 0 AND lv_LogID > 0) THEN
						SELECT GROUP_CONCAT(temp.CustID)
						INTO lv_LogInfo
						FROM Temp_CustIssue AS temp
						WHERE EXISTS (SELECT 1 FROM DataConsistencyMonitoring WHERE RuleID = CONST_GENERAL_RuleID AND IsActive = 1);
						
						UPDATE CTS_DataCenter.DataConsistencyMonitoring_Log AS temp
						SET 	temp.LogInfo = lv_LogInfo
							,	temp.MaxCustID = CASE 	WHEN lv_MinCustID < lv_NextCustID THEN lv_NextCustID
														WHEN lv_MinCustID > 0 AND lv_NextCustID = 0 THEN lv_MinCustID 
														ELSE NULL END
							,	temp.LogInfo = CONCAT(temp.LogInfo,",",lv_LogInfo)
							,	temp.LastModifiedDate = NOW()
						WHERE temp.ID =  lv_LogID;

					END IF;
					
					IF lv_NextCustID = 0 THEN
						UPDATE CTS_DataCenter.SystemEventStatus 
						SET 	Status = 'Stop' 
							,	LastExecTime = NOW()
						WHERE EventName = 'EV_CTS_DC_DataConsistency_CustomerCategory';
					END IF;
				END IF;
				
			END WHILE;
            
		END IF;
 END |

DELIMITER ;