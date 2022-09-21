/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
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