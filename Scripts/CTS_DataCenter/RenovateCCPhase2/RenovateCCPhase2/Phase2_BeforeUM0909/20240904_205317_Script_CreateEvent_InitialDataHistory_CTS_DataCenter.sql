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
CREATE EVENT EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory
    ON SCHEDULE
		EVERY 30 SECOND
    DO
      BEGIN
        DECLARE lv_MinHistoryID		BIGINT DEFAULT 0;
        DECLARE lv_BatchSize		BIGINT DEFAULT 0;
        DECLARE lv_NextHistoryID	BIGINT DEFAULT 0;
		
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';
		END;

		IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory' AND Status = 'Stop') THEN
			SELECT ParameterValue
			INTO lv_MinHistoryID
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 777;
			
			SELECT ParameterValue
			INTO lv_BatchSize
			FROM CTS_DataCenter.SystemParameter
			WHERE ParameterID = 776;
			
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Start' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';
			
            CAll CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_BYSPORT(lv_BatchSize,lv_MinHistoryID,lv_NextHistoryID); 
            
			IF lv_MinHistoryID < lv_NextHistoryID THEN
				UPDATE CTS_DataCenter.SystemParameter 
				SET ParameterValue = lv_NextHistoryID
				WHERE ParameterID = 777;
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Stop' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';
			
			END IF;
			
			IF lv_MinHistoryID = lv_NextHistoryID THEN
				
				UPDATE CTS_DataCenter.SystemEventStatus 
				SET 	Status = 'Done' 
					,	LastExecTime = NOW()
				WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';
			
			END IF;
			
			
            
		END IF;

 END |

DELIMITER ;