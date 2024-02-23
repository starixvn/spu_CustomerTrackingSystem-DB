/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240124@Victoria.Le
	Task :	Update ParameterID = 141 - Monitor_MMDetails_BeginDate and Enable event
	DB:			
	
	Description: 

	Revisions:	
		- 20240124@Victoria.Le: 	Initial Writing [Redmine ID: #192172]
        - 20240223@Victoria.Le: 	Initial Writing [Redmine ID: #201271]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

UPDATE SystemParameter
SET ParameterValue = DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
WHERE ParameterID = 141;

ALTER EVENT EV_CTS_DC_MatchMonitor_Wrapper
	ENABLE;