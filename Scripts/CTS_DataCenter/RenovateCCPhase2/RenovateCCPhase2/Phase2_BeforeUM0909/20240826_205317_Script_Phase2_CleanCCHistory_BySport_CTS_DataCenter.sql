/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240826@Victoria.Le
	Task :	Initial Data - ParamID 
	DB:			
	
	Description: 

	Revisions:	
		- 20240826@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (998, 'Clean_Redundant_BySport_History', 'Clean_Redundant_BySport_History','BIGINT',999)
,	(997, 'Clean_Redundant_BySport_History', 'Clean_Redundant_BySport_History','INT',4000);

/*
SELECT COUNT(1), max(ID), min(ID) FROM CTS_DataCenter.AdhocVic_History_Bysport_DELETE;
-- 455153	42891438	999
-- AROUND 2H TO DONE
*/


-- Event
INSERT INTO SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_BySport_History','Stop', NOW());