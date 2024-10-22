/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241021@Victoria.Le
	Task :	Identify customers who have incorrect category settings.
	DB:	CTS_DataCenter		
	
	Description: 

	Revisions:	
		- 20241021@Victoria.Le: 	Initial Writing [Redmine ID: #212321]
		
	Param's Explanation (filtered by):

	Example:
*/
USE CTS_DataCenter;

DROP TABLE IF EXISTS DataConsistencyMonitoring;
CREATE TABLE DataConsistencyMonitoring(
		RuleID				INT PRIMARY KEY
	,	RuleMessage			VARCHAR(500)
	,	Description			VARCHAR(500)
	,	IsActive			TINYINT(1) DEFAULT 0
	,	InsertedTime		DATETIME(3)
	,	LastModifiedDate	DATETIME(3)
);

DROP TABLE IF EXISTS DataConsistencyMonitoring_Log;
CREATE TABLE DataConsistencyMonitoring_Log(
		ID					BIGINT AUTO_INCREMENT PRIMARY KEY
	,	RuleID				INT NOT NULL
	,	LogInfo				TEXT
	,	MinCustID			BIGINT
	,	MaxCustID			BIGINT
	,	IsManaged			TINYINT(1) DEFAULT 0
	,	CreatedDate			DATE
	,	InsertedTime		DATETIME(3)
	,	LastModifiedDate	DATETIME(3)
	,	INDEX IX_DataConsistencyMonitoring_Log_CreatedDate (CreatedDate)
);


SET @INSERTEDTIME = NOW();
INSERT INTO DataConsistencyMonitoring (RuleID,RuleMessage,Description,IsActive,InsertedTime,LastModifiedDate)
SELECT 1,'Incorrect customer category settings', 'Identify customers who have incorrect category settings',1,@INSERTEDTIME,@INSERTEDTIME;

INSERT IGNORE INTO SystemEventStatus (EventName,Status,LastExecTime)
SELECT 'EV_CTS_DC_DataConsistency_CustomerCategory','Stop',@INSERTEDTIME;

INSERT INTO SystemParameter (ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES (999,'IncorrectCustomerCategorySettings_Batchsize','Incorrect_Customer_Category_Settings_Batchsize','BIGINT','5000')
, (998,'IncorrectCustomerCategorySettings_CustID','Incorrect_Customer_Category_Settings_Batchsize','INT','0');