/*<info serverAlias="DBVR2-bodb_VR2Model" executers="DBCTS-WASAVerse" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20241001@Jonas.Huynh
    Task:	 	Customer Classification Agency [Redmine ID: #185799]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- #1. ADD TABLE CustomerClassificationAgency
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency]
CREATE TABLE [dbo].[CustomerClassificationAgency](
	[ID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RowVersion] [timestamp] NOT NULL,
	[CustId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[CurrentCategoryId] [int] NULL,
	[CategoryId] [int] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[TurnoverRM] [decimal](19, 4) NULL,
	[WinlossRM] [decimal](19, 4) NULL,
	[TurnoverORG] [decimal](19, 4) NULL,
	[WinlossORG] [decimal](19, 4) NULL,
	[BetCount] [int] NULL,
	[FirstBetDate] [datetime] NULL,
	[LastXDaysTurnoverRM] [decimal](19, 4) NULL,
	[LastXDaysWinlossRM] [decimal](19, 4) NULL,
	[LastXDaysBetCount] [int] NULL,
	[LastYDaysTurnoverRM] [decimal](19, 4) NULL,
	[LastYDaysWinlossRM] [decimal](19, 4) NULL,
	[LastYDaysBetCount] [int] NULL,
	[LastXYDaysWinlossRatio] [smallint] NULL,
	[PerformanceTime] [datetime] NULL
)
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_CustIdRoleIdRowVersion] ON [dbo].[CustomerClassificationAgency]
(
	[CustId],
	[RoleId],
	[RowVersion]
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_RowVersion] ON [dbo].[CustomerClassificationAgency]
(
	[RowVersion] ASC
)
GO

-- #2. ADD TABLE CustomerClassificationAgency_NormalPool
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_NormalPool]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_NormalPool]
CREATE TABLE [dbo].[CustomerClassificationAgency_NormalPool](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustId] [int] NOT NULL,
	[RoleId] [tinyint] NULL,
	[Priority] [smallint] NULL,
	[FunctionId] [smallint] NOT NULL,
	[CreatedTime] [datetime] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) ON [PRIMARY]
GO

-- #3. ADD TABLE CustomerClassificationAgency_InputLog
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_InputLog]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_InputLog]
CREATE TABLE [dbo].[CustomerClassificationAgency_InputLog](
	[CustId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[FunctionId] [smallint] NULL,
	[IsActive] [bit] NULL,
	[CurrentCategoryId] [smallint] NULL,
	PRIMARY KEY CLUSTERED
	(
		[CustId],
		[RoleId] ASC
	)
) ON [PRIMARY]
GO


CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_InputLog_CustIdFunctionIdRoleId] ON [dbo].[CustomerClassificationAgency_InputLog]
(
	[CustId],
	[FunctionId],
	[RoleId]
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_InputLog_CreatedDate] ON [dbo].[CustomerClassificationAgency_InputLog]
(
	[CreatedDate]
)
GO

-- #4. ADD TABLE CustomerClassificationAgency_InputLog
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_Priority]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_Priority]
CREATE TABLE [dbo].[CustomerClassificationAgency_Priority](
	[GroupId] [bigint] NOT NULL,
	[GroupName] [nvarchar](10) NOT NULL,
	[FunctionId] [int] NOT NULL,
	[FunctionName] [nvarchar](50) NOT NULL,
	[Priority] [smallint] NOT NULL
	PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[FunctionId]
	)
) ON [PRIMARY]
GO

INSERT INTO [dbo].[CustomerClassificationAgency_Priority] (GroupId, GroupName, FunctionId, FunctionName, Priority)
VALUES (1, 'ByFlow', 1, 'Realtime', 100);

INSERT INTO [dbo].[CustomerClassificationAgency_Priority] (GroupId, GroupName, FunctionId, FunctionName, Priority)
VALUES (1, 'ByFlow', 2, 'Daily', 200);

-- #5. ADD TABLE CustomerClassificationAgency_RealtimeChanges
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_RealtimeChanges]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_RealtimeChanges]
CREATE TABLE [dbo].[CustomerClassificationAgency_RealtimeChanges](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[CustId] [int] NOT NULL,
	[CreatedTime] [datetime] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) ON [PRIMARY]
GO

-- #6. ADD TABLE CustomerClassificationAgency_Log
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_Log]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_Log]
CREATE TABLE [dbo].[CustomerClassificationAgency_Log](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[FunctionId] [smallint] NOT NULL,
	[CreatedTime] [datetime] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) ON [PRIMARY]
GO

-- #7. ADD TABLE CustomerClassificationAgency_LatestActiveDay
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_LatestActiveDay]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_LatestActiveDay]
CREATE TABLE [dbo].[CustomerClassificationAgency_LatestActiveDay](
	[CustId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[LastTransDate] [date] NOT NULL,
	[LastTransTime] [datetime] NOT NULL,
	[CreatedTime] [datetime] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC,
		[RoleId]
	)
) ON [PRIMARY]
GO

-- #9. ADD TABLE CustomerClassificationAgency_Rule
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_Rule]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_Rule]
CREATE TABLE [dbo].[CustomerClassificationAgency_Rule](
	[RuleId] [int] IDENTITY(1,1) NOT NULL,
	[RuleGroupId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[CategoryId] [int] NOT NULL,
	[CategoryName] [varchar](50) NOT NULL,
	[Prioity] [smallint] NOT NULL,
	[CurrentCategory] [int] NULL,
	[IsSpecialSite] [bit] NULL,
	[IsDeposit] [bit] NULL,
	[BetCount] [bigint] NULL,
	[FirstBetDate] [smallint] NULL,
	[Margin] [decimal](19, 4) NULL,
	[Margin2] [decimal](19, 4) NULL,
	[WinlossRM] [decimal](19, 4) NULL,
	[WinlossRM2] [decimal](19, 4) NULL,
	[TurnoverRM] [decimal](19, 4) NULL
	PRIMARY KEY NONCLUSTERED
	(
		[RuleId] ASC
	)
) ON [PRIMARY]

CREATE CLUSTERED INDEX [IX_CustomerClassificationAgency_Rule_RoleID_RuleGroupId_CusrrentCategory] ON [dbo].[CustomerClassificationAgency_Rule]
(
	[RoleId] ASC,
	[RuleGroupId] ASC ,
	[CurrentCategory]
)

GO
-- NEW
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount)
VALUES (1, 2, 140100, 'New', 6, 40);

-- GOOD
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2)
VALUES (100, 2, 140200, 'Good', 5, 40, 60, 0, 0);

-- NORMAL
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, WinlossRM)
VALUES (200, 2, 140300, 'Normal', 4, 40, 60, 0, 0, 50);

-- EARLY STAGE PROBATION
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate)
VALUES (300, 2, 140800, 'Early Stage Probation', 3, 40, 60);

-- SMART
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, WinlossRM)
VALUES (400, 2, 140500, 'Smart', 2, 40, 60, 0, 0, 50);

--RISKY
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2)
VALUES (500, 2, 140600, 'Risky', 1, 40, 60, 0, 0);
GO

-- #10. INITIALIZE TABLE CustomerClassification_Parameter
INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (1000, 'Normal Customer Classification Agency - General - Lastest Scan Rowversion', 'ROWVERSION', CONVERT(VARCHAR(200), 0));

-- #11. GRANT PERMISSION
GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_Rule] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_InputLog] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_Log] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_LatestActiveDay] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_RealtimeChanges] TO [wsv_cts]
GO