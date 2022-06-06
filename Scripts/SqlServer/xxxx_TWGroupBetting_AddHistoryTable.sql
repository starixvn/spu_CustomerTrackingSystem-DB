/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	05052022@Harvey.Nguyen
    Task:	 	Add table for ticket data storage  [Redmine ID: ####]
    DBName:		bodb02
*/

USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[SPU_GroupBettingTicket_History](
	[TransId] [bigint] NOT NULL,
	[TransDate] [date] NULL,
 CONSTRAINT [PK_SPU_GroupBettingTicket_History] PRIMARY KEY CLUSTERED 
(
	[TransId] ASC
)) ON [PRIMARY]

GO
CREATE NONCLUSTERED INDEX IX_SPU_GroupBettingTicket_History_TransDate
    ON dbo.[SPU_GroupBettingTicket_History] (TransDate);  
GO