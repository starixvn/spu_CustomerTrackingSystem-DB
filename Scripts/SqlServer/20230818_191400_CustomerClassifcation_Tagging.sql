/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230815@Jonas.Huynh
    Task:	 	Customer Classification Tagging [Redmine ID: #191400]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. Add new column
ALTER TABLE [dbo].[CustomerClassification]
ADD ScanTaggingType INT DEFAULT(0);
GO

-- #2. Update priority
UPDATE [dbo].[CustomerClassification_Priority]
SET [FunctionName] = 'Scan Tagging Classification',
	[Priority] = 1000
WHERE [GroupId] = 1 
	AND [FunctionId] = 7;