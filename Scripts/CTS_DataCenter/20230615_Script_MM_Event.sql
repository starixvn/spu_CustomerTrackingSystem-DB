/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20230614@Victoria.Le
	Task :		
	DB:			
	
	Description: 

	Revisions:	
		- 20230614@Victoria.Le: 	Initial Writing [Redmine ID: #185793]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

DELIMITER |
CREATE EVENT EV_CTS_DC_MatchMonitor_Wrapper
    ON SCHEDULE
		EVERY 1 DAY STARTS '2023-06-15' + INTERVAL '02:00' HOUR_MINUTE
    DO
      BEGIN
        
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_MatchMonitor_Wrapper';
		END;

		IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_CTS_DC_MatchMonitor_Wrapper' AND Status = 'Stop') THEN
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Start' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_MatchMonitor_Wrapper';
			
            CAll CTS_DataCenter.CTS_DC_MatchMonitor_AssociationDetection_Wrapper(); 
            
			UPDATE CTS_DataCenter.SystemEventStatus 
			SET 	Status = 'Stop' 
				,	LastExecTime = NOW()
			WHERE EventName = 'EV_CTS_DC_MatchMonitor_Wrapper';
            
		END IF;

 END |

DELIMITER ;



