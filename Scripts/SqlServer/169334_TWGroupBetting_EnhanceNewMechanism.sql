/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220701@Harvey.Nguyen
    Task:	 	Create index for SPU_GroupBettingTicket [Redmine ID: 169334]
    DBName:		bodb02
*/

USE [bodb02]

GO
CREATE NONCLUSTERED INDEX IX_SPU_GroupBettingTicket_TransDate
    ON dbo.[SPU_GroupBettingTicket] (TransDate);  
GO

TRUNCATE TABLE SPU_GroupBettingCustomer;
TRUNCATE TABLE SPU_GroupBettingTicket;
TRUNCATE TABLE SPU_GroupBettingTicket_History;