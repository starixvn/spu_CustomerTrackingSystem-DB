/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230223@Jonas.Huynh
    Task:	 	HF check range time to get new placebet info [Redmine ID: #184112]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (8, 'Normal Accounts Classification - Realtime - Step minute jump for retrieving customer performance', 'VARCHAR(20)', 15);
GO