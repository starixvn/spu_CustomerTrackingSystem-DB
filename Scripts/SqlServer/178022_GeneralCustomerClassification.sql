/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[CustomerClassification_InputLog]
ADD [TurnoverRM] DECIMAL(19, 4) NULL,
	[WinlossRM] DECIMAL(19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
	[CurrentCategoryId]	SMALLINT NULL


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_Rule]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_Rule]
GO

CREATE TABLE [dbo].[CustomerClassification_Rule](
	[RuleId] [int] NOT NULL IDENTITY(1,1),
	[RuleGroupId] [int] NOT NULL,
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
	[ActiveDays] [int] NULL
	PRIMARY KEY NONCLUSTERED
	(
		[RuleId] ASC
	)
) ON [PRIMARY]

CREATE CLUSTERED INDEX [CIX_CustomerClassification_Rule_CurrentCategory_RuleGroupId] ON [dbo].[CustomerClassification_Rule]
(
	[CurrentCategory],
	[RuleGroupId] ASC 
)

GO
-- NEW
INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 201, 'New', 6, 0, 10);


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 0, 1, 10, 0, -5000); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 201, 1, 10, 0, -5000); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 202, 1, 10, 0, -5000); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 205, 1, 10, 0, -5000); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 206, 1, 10, 0, -5000); --PROBATION

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 203, 1, 10, 0, -5000); --SMART

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 204, 1, 10, 0, -5000); --RISKY

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 1001, 1, 10, 0, -5000); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM)
VALUES (2, 201, 'New', 6, 1002, 1, 10, 0, -5000); --SMART INACTIVE

-- GOOD
INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 0, 300, -2, 150000, 8); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 201, 300, -2, 150000, 8); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 202, 300, -2, 150000, 8); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 205, 300, -2, 150000, 8); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 206, 300, -2, 150000, 8); --PROBATION

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 203, 300, -2, 150000, 8); --SMART

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 204, 300, -2, 150000, 8); --RISKY

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 1001, 300, -2, 150000, 8); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, TurnoverRM, ActiveDays) 
VALUES (3, 205, 'Good', 5, 1002, 300, -2, 150000, 8); --SMART INACTIVE


-- NORMAL
INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 0, 0, 10, -2, 0); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 201, 0, 10, -2, 0); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 202, 0, 10, -2, 0); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 205, 0, 10, -2, 0); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 206, 0, 10, -2, 0); --PROBATION

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 203, 0, 10, -2, 0); --SMART

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 204, 0, 10, -2, 0); --RISKY

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 1001, 0, 10, -2, 0); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 202, 'Normal', 4, 1002, 0, 10, -2, 0); --SMART INACTIVE


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 0, 0, 10, 300, -2, 150000, 8); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 201, 0, 10, 300, -2, 150000, 8); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 202, 0, 10, 300, -2, 150000, 8); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 205, 0, 10, 300, -2, 150000, 8); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 206, 0, 10, 300, -2, 150000, 8); --PROBATION

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 203, 0, 10, 300, -2, 150000, 8); --SMART

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 204, 0, 10, 300, -2, 150000, 8); --RISKY

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 1001, 0, 10, 300, -2, 150000, 8); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, BetCount2, Margin, TurnoverRM, ActiveDays) 
VALUES (5, 202, 'Normal', 4, 1002, 0, 10, 300, -2, 150000, 8); --SMART INACTIVE


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 0, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 201, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 202, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 205, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 206, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 203, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 204, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 1001, 1, 10, 0, -5000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsSpecialSite, BetCount, Margin, WinlossRM) 
VALUES (6, 202, 'Normal', 4, 1002, 1, 10, 0, -5000);


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 0, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 201, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 202, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 205, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 206, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 203, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 204, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 1001, 0, 10, 0, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (7, 202, 'Normal', 4, 1002, 0, 10, 0, 10000);


-- PROBATION
INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)
VALUES (8, 206, 'Probation', 3, 203, 20, 0, 1, 10000);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)
VALUES (9, 206, 'Probation', 3, 204, 20, 0, 1, 15000);


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin) 
VALUES (10, 206, 'Probation', 3, 0, 1, 10, 0); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin) 
VALUES (10, 206, 'Probation', 3, 201, 1, 10, 0); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin) 
VALUES (10, 206, 'Probation', 3, 205, 1, 10, 0); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin) 
VALUES (10, 206, 'Probation', 3, 202, 1, 10, 0); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin) 
VALUES (10, 206, 'Probation', 3, 1001, 1, 10, 0); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin) 
VALUES (10, 206, 'Probation', 3, 1002, 1, 10, 0); --SMART INACTIVE


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (11, 206, 'Probation', 3, 0, 0, 10, 0, 10000); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (11, 206, 'Probation', 3, 201, 0, 10, 0, 10000); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (11, 206, 'Probation', 3, 205, 0, 10, 0, 10000); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (11, 206, 'Probation', 3, 202, 0, 10, 0, 10000); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (11, 206, 'Probation', 3, 1001, 0, 10, 0, 10000); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Margin, WinlossRM) 
VALUES (11, 206, 'Probation', 3, 1002, 0, 10, 0, 10000); --SMART INACTIVE


-- SMART
INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 0, 20, 0, 1, 15000); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 201, 20, 0, 1, 15000); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 202, 20, 0, 1, 15000); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 205, 20, 0, 1, 15000); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 206, 20, 0, 1, 15000); --PROBATION

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 204, 20, 0, 1, 15000); --RISKY

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 1001, 20, 0, 1, 15000); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, Margin2, WinlossRM)  
VALUES (12, 203, 'Smart', 2, 1002, 20, 0, 1, 15000); --SMART INACTIVE


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM, WinlossRM2)  
VALUES (13, 203, 'Smart', 2, 204 , 20, 1, 0, 10000)


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, WinlossRM, WinlossRM2) 
VALUES (14, 203, 'Smart', 2, 203, 1, 0, 15000);


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Margin2, WinlossRM) 
VALUES (15, 203, 'Smart', 2, 203, 0, 1, 10000);

--RISKY
INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 0, 20, 1, 15000); --NULL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 201, 20, 1, 15000); --NEW

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 202, 20, 1, 15000); --NORMAL

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 205, 20, 1, 15000); --GOOD

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 206, 20, 1, 15000); --PROBATION

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 203, 20, 1, 15000); --SMART

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 1001, 20, 1, 15000); --NORMAL INACTIVE

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (16, 204, 'Risky', 1, 1002, 20, 1, 15000); --SMART INACTIVE


INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, WinlossRM) 
VALUES (17, 204, 'Risky', 1, 204, 1, 10000);


GRANT SELECT ON [dbo].[CustomerClassification_Rule] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_Rule] TO [bodbSPUNet]
GO