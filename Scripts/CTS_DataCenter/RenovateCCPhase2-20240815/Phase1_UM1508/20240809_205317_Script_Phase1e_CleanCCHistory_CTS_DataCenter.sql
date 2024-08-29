/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240819@Victoria.Le
	Task :	Initial Data - ParamID 
	DB:			
	
	Description: 

	Revisions:	
		- 20240819@Victoria.Le: 	Initial Writing [Redmine ID: #185793]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (999, 'Clean_Redundant_History', 'Clean_Redundant_History','DATETIME',9999);

/*
SELECT COUNT(1), max(ID), min(ID) FROM CTS_Adhoc.Adhoc_CustIDID;
-- 46539327	1027394619 9999
*/


-- Event
INSERT INTO SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_CTS_DC_Adhoc_Renovate_Phase1_Clean_History','Stop', NOW());