/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230315@Victoria.le
	Task:	 	Robot Imperva
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230315@Victoria.le: 	Update Schema - Initial Data [Redmine ID: #184773]

*/

USE CTS_DataCenter;

CREATE TABLE RobotImperva
(
		LogID				BIGINT	
	,	CustID				INT
    ,	Platform			SMALLINT
	,	CreateTime			DATETIME
	,	IsScan				TINYINT DEFAULT 0
    ,	LastModifiedDate	DATETIME DEFAULT NULL

	,	PRIMARY KEY PK_RobotImperva (CustID,Platform)
    ,	INDEX IX_RobotImperva_CreateTime (CreateTime)
	,	INDEX IX_RobotImperva_LogID (LogID)
);

ALTER TABLE CTSCustomerClassification
ADD COLUMN IsFromImpreva BIT(1) DEFAULT 0;

ALTER TABLE CTSCustomerClassificationOldCategory
ADD COLUMN IsFromImpreva BIT(1) DEFAULT 0;

ALTER TABLE CTSCustomerClassification_History
ADD COLUMN IsFromImpreva BIT(1) DEFAULT 0;

ALTER TABLE CTSCustomerClassification_Log
ADD COLUMN IsFromImpreva BIT(1) DEFAULT 0;

-- --------------------------------------------------
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (133, 'LastScannedRobotImperva', 'Keep the last logid of getting Robot Imperva','BIGINT',0);

INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (134, 'RobotBettingService_LastCreateTime', 'Robot Imperva','DATETIME','2022-09-01 00:00:00');
