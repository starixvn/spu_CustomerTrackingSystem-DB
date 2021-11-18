/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211110@Casey.Huynh
Task:	 	System Fomular Bet Monitor
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20211110@Casey.Huynh: Created [Redmine ID: #164148]
Reviewer:

*/
USE CTS_DataCenter;

CREATE TABLE TWProblemDetectionMonitor(
		CustID		INT UNSIGNED
	,	UserName	VARCHAR(50)
	,	RoleID		TINYINT
    ,	ReasonID	TINYINT
    ,	PreventActionID	TINYINT
    ,	Comment		VARCHAR(300)
    ,	VoidTime	VARCHAR(50)
    ,	LimitAmount DECIMAL(20,4)
    ,	UserID		INT
    ,	IP			VARCHAR(15)    
	,	CreatedDate	DATETIME
    ,	InsertTime	DATETIME(4)
    
	,	PRIMARY KEY PK_TWProblemDetectionMonitor_CustID(CustID)
    ,	INDEX IX_TWProblemDetectionMonitor_CreatedDate(CreatedDate)
) ENGINE=InnoDB;

/*****************************/
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(62, 'Scan TWProblemDetection', 'Batch Size', 'INT', '500')
	,	(63, 'Scan TWProblemDetection', 'LastCustID', 'INT UNSINGEG', '0');