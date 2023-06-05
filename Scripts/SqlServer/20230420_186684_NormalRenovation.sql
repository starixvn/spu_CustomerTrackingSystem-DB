/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230601@Jonas.Huynh
    Task:	 	Normal Renovation [Redmine ID: #186684]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. Change datatype for col[Priority]
DROP INDEX [IX_CustomerClassification_NormalPool_Priority_CustId] ON [dbo].[CustomerClassification_NormalPool];
GO
ALTER TABLE [dbo].[CustomerClassification_NormalPool] ALTER COLUMN [Priority] SMALLINT;
GO
CREATE NONCLUSTERED INDEX [IX_CustomerClassification_NormalPool_Priority_CustId] ON [dbo].[CustomerClassification_NormalPool]
(
	[Priority]	ASC,
	CustId
)
GO

-- #2. Add new Priorities
--ALTER TABLE [dbo].[CustomerClassification_Priority] ADD CONSTRAINT UC_GroupId UNIQUE (GroupId, FunctionId)
--GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 2, 'Probation', 200)
GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 3, 'Daily', 300)
GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 4, 'Rescan From Manual Action', 10)
GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 5, 'Rescan New Customers', 20)
GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 6, 'Rescan Affected Downline', 30)
GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 7, 'Rescan Unknown Action', 9999)
GO

-- #3. Add Column
ALTER TABLE [dbo].[CustomerClassification_Rule]
ADD IsProbationLastDay BIT DEFAULT(0);
GO

UPDATE [dbo].[CustomerClassification_Rule]
SET IsProbationLastDay = 1
WHERE RuleId IN (74, 85);
