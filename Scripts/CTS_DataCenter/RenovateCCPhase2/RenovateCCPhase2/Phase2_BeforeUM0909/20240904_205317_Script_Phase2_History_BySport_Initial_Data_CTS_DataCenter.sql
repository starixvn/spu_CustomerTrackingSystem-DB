/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240904@Victoria.Le
	Task :	Initial Data - ParamID 
	DB:			
	
	Description: 

	Revisions:	
		- 20240904@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

/*
INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (777, 'InitForCCHistory_BySport_RenovateCC_BatchSize', 'InitForCCHistory_BySport_RenovateCC_BatchSize','BIGINT',3000)
,	(776, 'InitForCCHistory_BySport_RenovateCC_NextID2run', 'InitForCCHistory_BySport_RenovateCC_NextID2run','INT',0);

-- Event
INSERT INTO SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory','Stop', NOW());
*/

SELECT * FROM SystemParameter WHERE ParameterID IN (777,776);

DELETE FROM SystemParameter WHERE ParameterID IN (777,776);

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (777, 'InitForCCHistory_BySport_RenovateCC_NextID2run', 'InitForCCHistory_BySport_RenovateCC_NextID2run','BIGINT',0)
,	(776, 'InitForCCHistory_BySport_RenovateCC_BatchSize', 'InitForCCHistory_BySport_RenovateCC_BatchSize','INT',3000);

UPDATE SystemEventStatus SET Status = 'Stop' WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';