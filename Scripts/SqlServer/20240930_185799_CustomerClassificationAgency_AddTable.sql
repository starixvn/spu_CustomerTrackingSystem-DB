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
CREATE TABLE [dbo].[CustomerClassificationAgency](
	[ID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RowVersion] [timestamp] NOT NULL,
	[CustId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[CurrentCategoryId] [int] NULL,
	[CategoryId] [int] NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[TurnoverRM] [decimal](19, 4) NULL,
	[WinlossRM] [decimal](19, 4) NULL,
	[TurnoverORG] [decimal](19, 4) NULL,
	[WinlossORG] [decimal](19, 4) NULL,
	[BetCount] [bigint] NULL,
	[FirstBetDate] [datetime] NULL,
	[LastXDaysTurnoverRM] [decimal](19, 4) NULL,
	[LastXDaysWinlossRM] [decimal](19, 4) NULL,
	[LastXDaysBetCount] [decimal](19, 4) NULL,
	[LastYDaysTurnoverRM] [decimal](19, 4) NULL,
	[LastYDaysWinlossRM] [decimal](19, 4) NULL,
	[LastYDaysBetCount] [decimal](19, 4) NULL,
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
CREATE TABLE [dbo].[CustomerClassificationAgency_NormalPool](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustId] [int] NOT NULL,
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
	[CustId],
	[FunctionId],
	[RoleId]
)
GO

-- #4. ADD TABLE CustomerClassificationAgency_InputLog
CREATE TABLE [dbo].[CustomerClassificationAgency_Priority](
	[GroupId] [bigint] NOT NULL,
	[GroupName] [nvarchar](10) NOT NULL,
	[FunctionId] [int] NOT NULL,
	[FunctionName] [nvarchar](50) NOT NULL,
	[Priority] [smallint] NOT NULL
) ON [PRIMARY]
GO

-- #5. ADD TABLE CustomerClassificationAgency_RealtimeChanges
CREATE TABLE [dbo].[CustomerClassificationAgency_RealtimeChanges](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustId] [int] NOT NULL,
	[CreatedTime] [datetime] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
) ON [PRIMARY]
GO

-- #6. ADD TABLE CustomerClassificationAgency_Log
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

-- #8. ADD TABLE CustomerClassificationAgency_Rule
CREATE TABLE [dbo].[CustomerClassificationAgency_Rule](
	[RuleId] [int] IDENTITY(1,1) NOT NULL,
	[RuleGroupId] [int] NOT NULL,
	[RoleId] [tinyint] NOT NULL,
	[CategoryId] [int] NULL,
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
	[TurnoverRM] [decimal](19, 4) NULL,
	[IsProbationLastDay] [bit] NULL,
	PRIMARY KEY NONCLUSTERED
	(
		[RuleId] ASC
	)
) ON [PRIMARY]

CREATE CLUSTERED INDEX [IX_CustomerClassificationAgency_Rule_RoleID_RuleGroupId_CurrentCategory] ON [dbo].[CustomerClassificationAgency_Rule]
(
	[RoleId] ASC,
	[RuleGroupId] ASC ,
	[CurrentCategory]
)

GO
-- NEW
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount)
VALUES (1, 2, 140100, 'New', 6, 10);

-- GOOD
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2)
VALUES (2, 2, 140200, 'Good', 5, 40, 60, 0, 0);

-- NORMAL
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, WinlossRM)
VALUES (4, 1, 140300, 'Normal', 4, 40, 60, 0, 0, 50);

-- PROBATION
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate)
VALUES (2, 2, 140400, 'Good', 3, 40, 60);

-- SMART
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, WinlossRM, IsProbationLastDay)
VALUES (2, 2, 140500, 'Smart', 2, 40, 60, 0, 0, 50, 1);

--RISKY
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleId, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, IsProbationLastDay)
VALUES (17, 1, 204, 'Risky', 1, 40, 60, 0, 0, 1);
GO

-- #9. INITIALIZE TABLE CustomerClassification_Parameter
INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (1000, 'Normal Customer Classification Agency - General - Lastest Scan Rowversion', 'ROWVERSION', CONVERT(VARCHAR(200), 0));

-- #10. GRANT PERMISSION
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