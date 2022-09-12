/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

UPDATE [dbo].[CustomerClassification_Parameter]
SET [DataDescription] = 'Normal Accounts Classification By Sport - Realtime - Get datetime for picking up the latest customer changes',[Value] = GETDATE()
WHERE DataId = 1;
GO

UPDATE [dbo].[CustomerClassification_Parameter]
SET [DataDescription] = 'Normal Accounts Classification By Sport - Realtime - Backup time for finish Realtime callback.',[Value] = GETDATE()
WHERE DataId = 2;
GO