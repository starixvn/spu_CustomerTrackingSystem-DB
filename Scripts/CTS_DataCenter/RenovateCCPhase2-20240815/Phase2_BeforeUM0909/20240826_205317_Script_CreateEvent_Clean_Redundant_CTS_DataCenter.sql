/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240826@Victoria.Le
	Task :	Create event to clean data
	DB:			
	
	Description: 

	Revisions:	
		- 20240826@Victoria.Le: 	Initial Writing [Redmine ID: #185793]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

DELIMITER |
CREATE EVENT EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant
    ON SCHEDULE
		EVERY 60 SECOND
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
			WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant';
		END;

		IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant' AND Status = 'Stop') THEN
			SELECT ParameterValue
			INTO lv_MinCustID
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 996;
			
			SELECT ParameterValue
			INTO lv_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 995;
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Start' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant';
			
            CAll CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_History_Clean(lv_BatchSize,lv_MinCustID,lv_NextCustID); 
            
			IF lv_MinCustID < lv_NextCustID THEN
				UPDATE CTS_DataCenter.SystemParameter 
				SET ParameterValue = lv_NextCustID
				WHERE ParameterID = 996;
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Stop' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant';
			
			END IF;
			
			IF lv_MinCustID = lv_NextCustID THEN
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Done' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant';
			
			END IF;
 
		END IF;

 END |

DELIMITER ;