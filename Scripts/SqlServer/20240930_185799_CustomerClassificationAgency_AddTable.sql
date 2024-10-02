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


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency]
GO

CREATE TABLE [dbo].[CustomerClassificationAgency](
	[ID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RowVersion] [timestamp] NOT NULL,
	[CustId] [int] NOT NULL,
	[RoleID] [tinyint] NOT NULL,
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

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_CustIdRoleIDRowVersion] ON [dbo].[CustomerClassificationAgency]
(
	[CustId],
	[RoleID],
	[RowVersion]
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_RowVersion] ON [dbo].[CustomerClassificationAgency]
(
	[RowVersion] ASC
)
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_InputLog]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_InputLog]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassificationAgency_InputLog](
	[CustId] [int] NOT NULL,
	[RoleID] [tinyint] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[FunctionId] [smallint] NULL,
	[IsActive] [bit] NULL,
	[CurrentCategoryId] [smallint] NULL,
	PRIMARY KEY CLUSTERED
	(
		[CustId],
		[RoleID] ASC
	)
) ON [PRIMARY]
GO


CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_InputLog_CustIdFunctionIdRoleID] ON [dbo].[CustomerClassificationAgency_InputLog]
(
	[CustId],
	[FunctionId],
	[RoleID]
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationAgency_InputLog_CreatedDate] ON [dbo].[CustomerClassificationAgency_InputLog]
(
	[CustId],
	[FunctionId],
	[RoleID]
)

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_Rule]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_Rule]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassificationAgency_Rule](
	[RuleId] [int] IDENTITY(1,1) NOT NULL,
	[RuleGroupId] [int] NOT NULL,
	[RoleID] [tinyint] NOT NULL,
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
	[RoleID] ASC,
	[RuleGroupId] ASC ,
	[CurrentCategory]
)

GO
-- NEW
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleID, CategoryId, CategoryName, Prioity, BetCount)
VALUES (1, 2, 140100, 'New', 6, 10);

-- GOOD
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleID, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2)
VALUES (2, 2, 140200, 'Good', 5, 40, 60, 0, 0);

-- NORMAL
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleID, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, WinlossRM)
VALUES (4, 1, 140300, 'Normal', 4, 40, 60, 0, 0, 50);

-- PROBATION
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleID, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate)
VALUES (2, 2, 140400, 'Good', 3, 40, 60);

-- SMART
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleID, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, WinlossRM, IsProbationLastDay)
VALUES (2, 2, 140500, 'Smart', 2, 40, 60, 0, 0, 50, 1);

--RISKY
INSERT INTO [dbo].[CustomerClassificationAgency_Rule] (RuleGroupId, RoleID, CategoryId, CategoryName, Prioity, BetCount, FirstBetDate, Margin, Margin2, IsProbationLastDay)
VALUES (17, 1, 204, 'Risky', 1, 40, 60, 0, 0, 1);
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_Rule] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency] TO [wsv_cts]
GO

GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_InputLog] TO [wsv_cts]
GO