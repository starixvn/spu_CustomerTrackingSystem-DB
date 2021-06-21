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
DROP EVENT IF EXISTS `EV_CTS_ProblemCaseMonitor_Rule`; 
CREATE DEFINER=`ctsOwner.vn`@`%` 
EVENT `EV_CTS_ProblemCaseMonitor_Rule` ON SCHEDULE EVERY 60 SECOND 
STARTS CURRENT_TIME() ON COMPLETION NOT PRESERVE ENABLE 
DO 
    CALL CTS_DataCenter.CTS_DC_ProblemCaseMonitor_Rule(500);

