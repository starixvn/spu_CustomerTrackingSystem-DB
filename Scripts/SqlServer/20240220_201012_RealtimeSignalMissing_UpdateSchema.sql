/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240220@Jonas.Huynh
    Task:	 	HF Incorrect Category - Realtime Signal Missing [Redmine ID: #201012]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

DECLARE	@LastScannedDateTime	VARCHAR(200);
DECLARE	@MinuteTime_StepJump	VARCHAR(200);

SELECT @LastScannedDateTime = [Value]
FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)	
WHERE DataId = 3;

SELECT @MinuteTime_StepJump =[Value]
FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)
WHERE DataId = 4;

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (9, 'Normal Accounts Classification - Realtime Check Changes - Step minute jump for retrieving customer performance', 'INT', @MinuteTime_StepJump);

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (10, 'Normal Accounts Classification - Realtime Check Changes - Get LastScannedTime1', 'DATETIME', @LastScannedDateTime);


INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (11, 'Normal Accounts Classification - Realtime Check Changes - Get LastScannedTime2', 'DATETIME', @LastScannedDateTime);


INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (12, 'Normal Accounts Classification - Realtime Check Changes - Get LastScannedTime3', 'DATETIME', @LastScannedDateTime);


INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (13, 'Normal Accounts Classification - Realtime Check Changes - Get LastScannedTime4', 'DATETIME', @LastScannedDateTime);
GO

DELETE r WITH(ROWLOCK)
FROM [dbo].[CustomerClassification_Parameter] AS r
WHERE r.DataId IN (3, 4);
GO