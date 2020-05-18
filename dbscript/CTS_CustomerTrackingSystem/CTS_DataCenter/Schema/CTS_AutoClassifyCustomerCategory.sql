/*
Creator: 20200507@LongLuu
Task:	 	CTS_Schema
Server:  	
DBName:		bodb_VR2Model

Revisions: 
		- 20200507@Lex: Upload  	(#133269)
Reviewer:
*/

USE [bodb_VR2Model]
GO

/****** Object:  Table [dbo].[CustomerAccummulatedInfo]    Script Date: 5/7/2020 1:50:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerAccummulatedInfo](
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[TurnoverRM] [money] NULL,
	[WinlossRM] [money] NULL,
	[TurnoverORG] [money] NULL,
	[WinlossORG] [money] NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
	[LastModifiedDate] [date] NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[CustomerClassification]    Script Date: 5/7/2020 1:50:31 PM ******/
CREATE TABLE [dbo].[CustomerClassification](
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[CategoryId] [smallint] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[IsApplied] [bit] NULL DEFAULT ((0)),
	[CreatedTime] [datetime] NULL
) ON [PRIMARY]

GO

