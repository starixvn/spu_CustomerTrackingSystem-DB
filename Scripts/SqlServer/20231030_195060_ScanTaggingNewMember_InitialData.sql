/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20231030@Tony.Nguyen
    Task:	 	New CC 2300 - TWGroupBetting Tagging New Member
    DBName:		bodb_VR2Model
	
	Revisions: 
		- 20231030@Tony.Nguyen: Initial Writing [Redmine ID: #195060]

*/

USE [bodb_VR2Model]
GO

INSERT INTO [dbo].[CustomerClassification_Priority] ([GroupId],[GroupName],[FunctionId],[FunctionName],[Priority])
VALUES(1,'ByFlow',8,'Scan TWGroupBetting Tagging New Member',90);

-- ---------------------------
INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId],[DataDescription],[DataType],[Value]) 
VALUES (7, 'Normal Accounts Classification - TWGroupBetting - Service - Get LastJobScannedTime', 'DATETIME', '2023-10-01 00:00:00.000');

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId],[DataDescription],[DataType],[Value]) 
VALUES (8, 'Normal Accounts Classification - TWGroupBetting - Job - Get LastModifiedDate', 'DATETIME', '2023-10-01 00:00:00.000');

