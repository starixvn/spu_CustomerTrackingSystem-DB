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

CREATE TABLE MatchMonitor_AssociationDetection_Monitor
(
		ID					BIGINT AUTO_INCREMENT PRIMARY KEY 
	,	MMDetailsID			BIGINT
	,	LogInfo				LONGTEXT
	,	MMDetailsInsertTime	DATETIME(3)
	,	CreatedDateTime		DATETIME(3)
);

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (141, 'Monitor_MMDetails_BeginDate', 'Monitor_MMDetails_BeginDate','DATETIME','2023-06-14');

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (142, 'Monitor_MMDetails_ID', 'Monitor_MMDetails_ID','BIGINT',0);

-- Event
INSERT INTO SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_CTS_DC_MatchMonitor_Wrapper','Stop', NOW());



