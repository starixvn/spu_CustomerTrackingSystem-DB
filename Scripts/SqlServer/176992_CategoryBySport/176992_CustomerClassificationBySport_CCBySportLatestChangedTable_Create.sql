/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
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
