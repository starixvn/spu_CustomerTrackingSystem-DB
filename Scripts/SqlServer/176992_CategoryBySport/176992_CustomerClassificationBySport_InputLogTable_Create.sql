/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

/****** Object:  Table [dbo].[CustomerClassification_BySport_InputLog]    Script Date: 9/22/2022 4:11:01 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport_InputLog]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport_InputLog]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport_InputLog](
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[FunctionId] [smallint] NOT NULL,
	[TurnoverRM] DECIMAL(19, 4) NULL,
	[WinlossRM] DECIMAL(19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
)
GO

CREATE CLUSTERED INDEX [IX_CustomerClassification_BySport_InputLog_CustId_FunctionId] ON [dbo].[CustomerClassification_BySport_InputLog]
(
	[CustId],
	[FunctionId],
	[CreatedDate],
	[SportId]
)

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_RealTime_CheckChanges] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_RealTime_CheckChanges] TO [bodbSPUNet]
GO
