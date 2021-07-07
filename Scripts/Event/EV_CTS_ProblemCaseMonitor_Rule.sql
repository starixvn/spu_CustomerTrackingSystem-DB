/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210611@Casey.Huynh
Task:	 	Create Event execute Rule [Redmine ID: 156464] 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
	-	[20210611@Casey.Huynh][156464]: Create
Reviewer:
*/
USE CTS_DataCenter;
DROP EVENT IF EXISTS EV_CTS_ProblemCaseMonitor_Rule;   
DELIMITER $

CREATE DEFINER=`ctsOwner`@`%` EVENT EV_CTS_ProblemCaseMonitor_Rule 
    ON SCHEDULE
      EVERY 60 SECOND
DO

BEGIN
	DECLARE lv_LastExecTime DATETIME;
    DECLARE lv_EventStatus VARCHAR(20);
    DECLARE lv_EventName VARCHAR(50) DEFAULT 'EV_CTS_ProblemCaseMonitor_Rule';
    
    SELECT `Status`, LastExecTime 
    INTO  lv_EventStatus, lv_LastExecTime
    FROM CTS_DataCenter.SystemEventStatus WHERE EventName = lv_EventName;
	
    IF (lv_EventStatus = 'Start' AND TIMESTAMPDIFF(MINUTE, lv_LastExecTime, CURRENT_TIME()) > 30)
    THEN        
		UPDATE CTS_DataCenter.SystemEventStatus
        SET 	`Status` = 'Stop'
			,	LastExecTime	= CURRENT_TIME()
        WHERE EventName = lv_EventName;
    END IF;
    
	IF EXISTS (SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = lv_EventName AND Status = 'Stop')
	THEN		
		UPDATE CTS_DataCenter.SystemEventStatus
        SET 	`Status` = 'Start'
			,	LastExecTime = CURRENT_TIME()
        WHERE EventName = lv_EventName;
        
        CALL CTS_DataCenter.CTS_DC_ProblemCaseMonitor_Rule(100);
        
        UPDATE CTS_DataCenter.SystemEventStatus
        SET 	`Status` = 'Stop'
			,	LastExecTime	= CURRENT_TIME()
        WHERE EventName = lv_EventName;
	END IF;
END $
DELIMITER $