/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport_BetCount]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport_BetCount]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport_BetCount](
	[CustId] [int] NOT NULL,
	[SportId] [smallint] NOT NULL,
	[BetCount] [int] NULL,
	[LastScannedDate] [datetime] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC,
		[SportId] ASC
	)
)
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_BetCount] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_BetCount] TO [bodbSPUNet]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport_LatestChanged]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport_LatestChanged]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport_LatestChanged](
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[TurnoverRM] DECIMAL(19, 4) NULL,
	[WinlossRM] DECIMAL(19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
	[LastModifiedDate] [date] NULL,
	[Margin] DECIMAL(19, 4) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC,
		[SportId]
	)
)
GO

GRANT CONTROL ON [dbo].[CustomerClassification_BySport_LatestChanged] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_LatestChanged] TO [bodbSPUNet]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport](
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[CategoryId] [smallint] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[IsApplied] [bit] NULL DEFAULT ((0)),
	[CreatedTime] [datetime] NULL,
	[TurnoverRM] DECIMAL(19, 4) NULL,
	[WinlossRM] DECIMAL(19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL
)
GO

CREATE CLUSTERED INDEX [CIX_CustomerClassification_BySport_IsApplied] ON [dbo].[CustomerClassification_BySport]
(
	[IsApplied] ASC
)

CREATE NONCLUSTERED INDEX [CIX_CCustomerClassification_BySport_CreatedDate] ON [dbo].[CustomerClassification_BySport]
(
	[CreatedDate] ASC
)
GO

CREATE NONCLUSTERED INDEX [CIX_CustomerClassification_BySport_CustIdSportIdCategoryId] ON [dbo].[CustomerClassification_BySport]
(
	[CustId] ASC,
	[SportId] ASC,
	[CategoryId] ASC
)

GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport] TO [bodbSPUNet]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport_InputLog]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport_InputLog]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport_InputLog](
    [ID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[FunctionId] [smallint] NOT NULL,
	[TurnoverRM] DECIMAL(19, 4) NULL,
	[WinlossRM] DECIMAL(19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
	[CurrentCategoryId]	SMALLINT NULL
)
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_InputLog_CustId_FunctionId] ON [dbo].[CustomerClassification_BySport_InputLog]
(
	[CustId],
	[FunctionId],
	[CreatedDate],
	[SportId]
)


GRANT SELECT ON [dbo].[CustomerClassification_BySport_InputLog] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_InputLog] TO [bodbSPUNet]
GO



UPDATE [dbo].[CustomerClassification_Parameter]
SET [DataDescription] = 'Normal Accounts Classification By Sport - Realtime - Get datetime for picking up the latest customer changes',[Value] = GETDATE()
WHERE DataId = 1;
GO

UPDATE [dbo].[CustomerClassification_Parameter]
SET [DataDescription] = 'Normal Accounts Classification By Sport - Realtime - Backup time for finish Realtime callback.',[Value] = GETDATE()
WHERE DataId = 2;
GO



IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport_Rule]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport_Rule]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport_Rule](
	[RuleId] [int] NOT NULL IDENTITY(1,1),
	[RuleGroupId] [int] NOT NULL,
	[SportId] [int]	NOT NULL,
	[CategoryId] [smallint]	NOT NULL,
	[CategoryName] varchar(50) NOT NULL,
	[Prioity] [smallint] NOT NULL,
	[CurrentCategory] [smallint] NULL,
	[IsSpecialSite]	BIT DEFAULT NULL,
	[IsDeposit]	BIT DEFAULT NULL,
	[BetCount] [bigint] NULL,	
	[BetCount2] [bigint] NULL,	
	[Margin] DECIMAL(19, 4) NULL,
	[Margin2] DECIMAL(19, 4) NULL,
	[WinlossRM] DECIMAL(19, 4) NULL,
	[WinlossRM2] DECIMAL(19, 4) NULL,
	[TurnoverRM] DECIMAL(19, 4) NULL,
	[ActiveDays] [int] NULL,
	[Operator_BetCount] varchar(5) NULL,
	[Operator_BetCount2] varchar(5) NULL,
	[Operator_Margin] varchar(5) NULL,
	[Operator_Margin2] varchar(5) NULL,
	[Operator_Turnover] varchar(5) NULL,
	[Operator_ActiveDate] varchar(5) NULL,
	[Operator_Winloss] varchar(5) NULL,
	[Operator_Winloss2] varchar(5) NULL
	PRIMARY KEY NONCLUSTERED
	(
		[RuleId] ASC
	)
) ON [PRIMARY]

CREATE CLUSTERED INDEX [IX_CustomerClassification_BySport_Rule_SportId_RuleGroupId_CurrentCategory] ON [dbo].[CustomerClassification_BySport_Rule]
(
	[SportId] ASC,
	[RuleGroupId] ASC ,
	[CurrentCategory]
)

GO
-- NEW
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Operator_BetCount) 
VALUES (1, 1, 201, 'New', 6, 0, 10, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Operator_BetCount) 
VALUES (1, 2, 201, 'New', 6, 0, 10, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Operator_BetCount) 
VALUES (1, 43, 201, 'New', 6, 0, 20, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Operator_BetCount) 
VALUES (1, 99, 201, 'New', 6, 0, 20, '<');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss)
VALUES (2, 1, 201, 'New', 6, 1, 10, '>=', 0, '<', -5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (2, 2, 201, 'New', 6, 1, 10, '>=', 0, '<', -5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss)
VALUES (2, 43, 201, 'New', 6, 1, 20, '>=', 0, '<', -5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (2, 99, 201, 'New', 6, 1, 20, '>=', 0, '<', -5000, '>');

-- GOOD
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (3, 1, 205, 'Good', 5, 300, '>', -2, '<', 150000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (3, 2, 205, 'Good', 5, 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (3, 43, 205, 'Good', 5, 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (3, 99, 205, 'Good', 5, 200, '>', -2, '<', 75000, '>', 8, '>=');

-- NORMAL
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (4, 1, 202, 'Normal', 4, 0, 10, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (4, 2, 202, 'Normal', 4, 0, 10, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (4, 43, 202, 'Normal', 4,0, 20, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (4, 99, 202, 'Normal', 4, 0, 20, '>=', -2, '<=',  0, '<');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, BetCount2, Operator_BetCount2, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (5, 1, 202, 'Normal', 4, 0, 10, '>=', 300, '>', -2, '<', 150000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, BetCount2, Operator_BetCount2, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (5, 2, 202, 'Normal', 4, 0, 10, '>=', 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, BetCount2, Operator_BetCount2, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (5, 43, 202, 'Normal', 4, 0, 20, '>=', 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, BetCount2, Operator_BetCount2, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate)
VALUES (5, 99, 202, 'Normal', 4, 0, 20, '>=', 200, '>', -2, '<', 75000, '>', 8, '>=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (6, 1, 202, 'Normal', 4, 1, 10, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (6, 2, 202, 'Normal', 4, 1, 10, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (6, 43, 202, 'Normal', 4, 1, 20, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (6, 99, 202, 'Normal', 4, 1, 20, '>=', 0, '<', -5000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (7, 1, 202, 'Normal', 4, 0, 10, '>=', 0, '>=', 10000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (7, 2, 202, 'Normal', 4, 0, 10, '>=', 0, '>=', 10000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (7, 43, 202, 'Normal', 4, 0, 20, '>=', 0, '>=', 5000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (7, 99, 202, 'Normal', 4, 0, 20, '>=', 0, '>=', 5000, '<');

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (8, 1, 206, 'Probation', 3, 203, 0, '<=', 1, '<=', 20, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (8, 2, 206, 'Probation', 3, 203, 0, '<=', 1, '<=', 10, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (8, 43, 206, 'Probation', 3, 203, 0, '<=', 2, '<=', 30, '>=', 5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (8, 99, 206, 'Probation', 3, 203, 0, '<=', 2, '<=', 30, '>=', 5000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (9, 1, 206, 'Probation', 3, 204, 0, '<=', 1, '<=', 20, '>=', 25000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (9, 2, 206, 'Probation', 3, 204, 0, '<=', 1, '<=', 10, '>=', 15000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (9, 43, 206, 'Probation', 3, 204, 0, '<=', 2, '<=', 30, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (9, 99, 206, 'Probation', 3, 204, 0, '<=', 2, '<=', 30, '>=', 10000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 1, 206, 'Probation', 3, 0, 1, 10, '>=', 0, '>='); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 2, 206, 'Probation', 3, 0, 1, 10, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 43, 206, 'Probation', 3, 0, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 99, 206, 'Probation', 3, 0, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 1, 206, 'Probation', 3, 201, 1, 10, '>=', 0, '>='); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 2, 206, 'Probation', 3, 201, 1, 10, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 43, 206, 'Probation', 3, 201, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 99, 206, 'Probation', 3, 201, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 1, 206, 'Probation', 3, 202, 1, 10, '>=', 0, '>='); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 2, 206, 'Probation', 3, 202, 1, 10, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 43, 206, 'Probation', 3, 202, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 99, 206, 'Probation', 3, 202, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 1, 206, 'Probation', 3, 205, 1, 10, '>=', 0, '>='); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 2, 206, 'Probation', 3, 205, 1, 10, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 43, 206, 'Probation', 3, 205, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 99, 206, 'Probation', 3, 205, 1, 20, '>=', 0, '>=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 1, 206, 'Probation', 3, 0, 0, 10, '>=', 0, '>=', 10000, '>='); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 2, 206, 'Probation', 3, 0, 0, 10, '>=', 0, '>=', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 43, 206, 'Probation', 3, 0, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 99, 206, 'Probation', 3, 0, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 1, 206, 'Probation', 3, 201, 0, 10, '>=', 0, '>=', 10000, '>='); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 2, 206, 'Probation', 3, 201, 0, 10, '>=', 0, '>=', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 43, 206, 'Probation', 3, 201, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 99, 206, 'Probation', 3, 201, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 1, 206, 'Probation', 3, 202, 0, 10, '>=', 0, '>=', 10000, '>='); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 2, 206, 'Probation', 3, 202, 0, 10, '>=', 0, '>=', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 43, 206, 'Probation', 3, 202, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 99, 206, 'Probation', 3, 202, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 1, 206, 'Probation', 3, 205, 0, 10, '>=', 0, '>=', 10000, '>='); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 2, 206, 'Probation', 3, 205, 0, 10, '>=', 0, '>=', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 43, 206, 'Probation', 3, 205, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 99, 206, 'Probation', 3, 205, 0, 20, '>=', 0, '>=', 5000, '>=');


-- SMART
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 1, 203, 'Smart', 2, 0, 0, '<=', 1, '<=', 20, '>=', 25000, '>'); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 2, 203, 'Smart', 2, 0, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 43, 203, 'Smart', 2, 0, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 99, 203, 'Smart', 2, 0, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 1, 203, 'Smart', 2, 201, 0, '<=', 1, '<=', 20, '>=', 25000, '>'); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 2, 203, 'Smart', 2, 201, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 43, 203, 'Smart', 2, 201, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 99, 203, 'Smart', 2, 201, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 1, 203, 'Smart', 2, 202, 0, '<=', 1, '<=', 20, '>=', 25000, '>'); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 2, 203, 'Smart', 2, 202, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 43, 203, 'Smart', 2, 202, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 99, 203, 'Smart', 2, 202, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 1, 203, 'Smart', 2, 205, 0, '<=', 1, '<=', 20, '>=', 25000, '>'); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 2, 203, 'Smart', 2, 205, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 43, 203, 'Smart', 2, 205, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 99, 203, 'Smart', 2, 205, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 1, 203, 'Smart', 2, 206, 0, '<=', 1, '<=', 20, '>=', 25000, '>'); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 2, 203, 'Smart', 2, 206, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 43, 203, 'Smart', 2, 206, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 99, 203, 'Smart', 2, 206, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 1, 203, 'Smart', 2, 204, 0, '<=', 1, '<=', 20, '>=', 25000, '>'); --RISKY

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 2, 203, 'Smart', 2, 204, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 43, 203, 'Smart', 2, 204, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (12, 99, 203, 'Smart', 2, 204, 0, '<=', 2, '<=', 30, '>=', 10000, '>');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 43, 203, 'Smart', 2, 0 , 2, '>', 30, '>=', 10000, '>', 20000, '<=') --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 99, 203, 'Smart', 2, 0, 2, '>', 30, '>=', 10000, '>', 20000, '<='); 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 43, 203, 'Smart', 2, 201, 2, '>', 30, '>=', 10000, '>', 20000, '<='); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 99, 203, 'Smart', 2, 201, 2, '>', 30, '>=', 10000, '>', 20000, '<='); 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 43, 203, 'Smart', 2, 202, 2, '>', 30, '>=', 10000, '>', 20000, '<='); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 99, 203, 'Smart', 2, 202, 2, '>', 30, '>=', 10000, '>', 20000, '<='); 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 43, 203, 'Smart', 2, 205, 2, '>', 30, '>=', 10000, '>', 20000, '<='); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 99, 203, 'Smart', 2, 205, 2, '>', 30, '>=', 10000, '>', 20000, '<='); 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 43, 203, 'Smart', 2, 206, 2, '>', 30, '>=', 10000, '>', 20000, '<='); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (13, 99, 203, 'Smart', 2, 206, 2, '>', 30, '>=', 10000, '>', 20000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2) 
VALUES (14, 1, 203, 'Smart', 2, 204, 1, '>', 20, '>=', 0, '>', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (14, 2, 203, 'Smart', 2, 204, 1, '>', 10, '>=', 0, '>', 10000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)
VALUES (15, 1, 203, 'Smart', 2, 203, 1, '>', 0, '>', 25000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)
VALUES (15, 2, 203, 'Smart', 2, 203, 1, '>', 0, '>', 15000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)
VALUES (15, 43, 203, 'Smart', 2, 203, 2, '>', 0, '>', 20000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)
VALUES (15, 99, 203, 'Smart', 2, 203, 2, '>', 0, '>', 20000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, WinlossRM, Operator_Winloss)   
VALUES (16, 1, 203, 'Smart', 2, 203, 0, '>=', 1, '<=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, WinlossRM, Operator_Winloss)   
VALUES (16, 2, 203, 'Smart', 2, 203, 0, '>=', 1, '<=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, WinlossRM, Operator_Winloss)   
VALUES (16, 43, 203, 'Smart', 2, 203, 0, '>=', 2, '<=', 5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, WinlossRM, Operator_Winloss)   
VALUES (16, 99, 203, 'Smart', 2, 203, 0, '>=', 2, '<=', 5000, '>');

--RISKY
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 204, 'Risky', 1, 0, 1, '>', 20, '>=', 25000, '>'); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 2, 204, 'Risky', 1, 0, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 43, 204, 'Risky', 1, 0, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 99, 204, 'Risky', 1, 0, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 204, 'Risky', 1, 201, 1, '>', 20, '>=', 25000, '>'); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 2, 204, 'Risky', 1, 201, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 43, 204, 'Risky', 1, 201, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 99, 204, 'Risky', 1, 201, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 204, 'Risky', 1, 202, 1, '>', 20, '>=', 25000, '>'); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 2, 204, 'Risky', 1, 202, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 43, 204, 'Risky', 1, 202, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 99, 204, 'Risky', 1, 202, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 204, 'Risky', 1, 205, 1, '>', 20, '>=', 25000, '>'); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 2, 204, 'Risky', 1, 205, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 43, 204, 'Risky', 1, 205, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 99, 204, 'Risky', 1, 205, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 204, 'Risky', 1, 203, 1, '>', 20, '>=', 25000, '>'); --SMART

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 2, 204, 'Risky', 1, 203, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 43, 204, 'Risky', 1, 203, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 99, 204, 'Risky', 1, 203, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 204, 'Risky', 1, 206, 1, '>', 20, '>=', 25000, '>'); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 2, 204, 'Risky', 1, 206, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 43, 204, 'Risky', 1, 206, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (17, 99, 204, 'Risky', 1, 206, 2, '>', 30, '>=', 20000, '>');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (18, 1, 204, 'Risky', 1, 204, 1, '>', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (18, 2, 204, 'Risky', 1, 204, 1, '>', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (18, 43, 204, 'Risky', 1, 204, 2, '>', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (18, 99, 204, 'Risky', 1, 204, 2, '>', 10000, '>');


GRANT EXECUTE ON [dbo].[CustomerClassification_BySport_Rule] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_Rule] TO [bodbSPUNet]
GO