/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220331@Harvey.Nguyen
    Task:	 	Update table schema TW Groupbeting  [Redmine ID: 169334]
    DBName:		bodb02
*/

USE [bodb02]
GO
DROP TABLE dbo.SPU_GroupBettingCustomer;
CREATE TABLE [dbo].[SPU_GroupBettingCustomer](
	CustId						INT			NOT NULL,
	GBTicketCount				INT			NULL,
	TicketCount					INT			NULL,
	ScanDate					DATE		NOT NULL,
	LastModifiedDate			DATETIME	NULL,
	LastCountTotalTicketDate	DATETIME	NULL
 CONSTRAINT [PK_SPU_GroupBettingCustomer] PRIMARY KEY CLUSTERED 
(
	CustId		ASC,
	ScanDate	DESC
))

ALTER TABLE dbo.SPU_GroupBettingTicket
ADD TransDate DATE;