/*
    Creator: 	20231030@Tony.Nguyen
    Task:	 	New CC 2300 - TWGroupBetting Tagging New Member
    DBName:		bodb_VR2Model
	
	Revisions: 
		- 20231030@Tony.Nguyen: Initial Writing [Redmine ID: #195060]

*/

USE [bodb_VR2Model]
GO

DECLARE @ReleasedDateTime VARCHAR(200);
SET @ReleasedDateTime = CONVERT(VARCHAR(200), GETDATE(), 121);

INSERT INTO [dbo].[CustomerClassification_Priority] ([GroupId],[GroupName],[FunctionId],[FunctionName],[Priority])
VALUES(1,'ByFlow',8,'Scan TWGroupBetting Tagging New Member',90);

-- ---------------------------
INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId],[DataDescription],[DataType],[Value]) 
VALUES (7, 'Normal Accounts Classification - TWGroupBetting - Service - Get LastJobScannedTime', 'DATETIME', @ReleasedDateTime);

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId],[DataDescription],[DataType],[Value]) 
VALUES (8, 'Normal Accounts Classification - TWGroupBetting - Job - Get LastModifiedDate', 'DATETIME', @ReleasedDateTime);

