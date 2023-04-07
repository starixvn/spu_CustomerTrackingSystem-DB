/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	202304068@Jonas.Huynh
    Task:	 	Modify betcount schedule for Normal & Good Member [Redmine ID: #185633]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

ALTER TABLE [dbo].[CustomerClassification]
ADD ID BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY;
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (1, 'Normal Accounts Classification - Get processed MaxID from normal pool', 'BIGINT','0');
GO