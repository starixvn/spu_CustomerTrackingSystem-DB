USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TW_GroupBettingTicket](
	CustId		INT		NOT NULL,
	TransId		BIGINT	NOT NULL
 CONSTRAINT [PK_GroupBettingTicket] PRIMARY KEY CLUSTERED 
(
	TransId ASC
))
GO

CREATE TABLE [dbo].[TW_GroupBettingCustomer](
	CustId				INT			NOT NULL,
	GBTicketCount		INT			NULL,
	TotalTicketCount	INT			NULL,
	UpdateTime			DATETIME	NULL
 CONSTRAINT [PK_GroupBettingCustomer] PRIMARY KEY CLUSTERED 
(
	CustId ASC
))
GO