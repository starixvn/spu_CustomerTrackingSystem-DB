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

GRANT EXECUTE ON [dbo].[CustomerClassification_BySport_BetCount] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_BetCount] TO [bodbSPUNet]
GO