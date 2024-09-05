/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240905@Victoria.Le
	Task :	Create event to clean data
	DB:			
	
	Description: 

	Revisions:	
		- 20240905@Victoria.Le: 	Initial Writing [Redmine ID: #185793]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

DELIMITER |
CREATE EVENT EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData
    ON SCHEDULE
		EVERY 120 SECOND
    DO
      BEGIN
        DECLARE lv_MinCustID		BIGINT DEFAULT 0;
        DECLARE lv_BatchSize		BIGINT DEFAULT 0;
        DECLARE lv_NextCustID		BIGINT DEFAULT 0;
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
		END;

		IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData' AND Status = 'Stop') THEN
			SELECT ParameterValue
			INTO lv_MinCustID
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 775;
			
			SELECT ParameterValue
			INTO lv_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 774;
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Start' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
			
            CAll CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_CorrectData_BackupAndInitial(lv_BatchSize,lv_MinCustID,lv_NextCustID); 
            
			IF lv_MinCustID < lv_NextCustID THEN
				UPDATE CTS_DataCenter.SystemParameter 
				SET ParameterValue = lv_NextCustID
				WHERE ParameterID = 775;
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Stop' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
			
			END IF;
			
			IF lv_MinCustID = lv_NextCustID THEN
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Done' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
			
			END IF;
			
			
            
		END IF;

 END |

DELIMITER ;