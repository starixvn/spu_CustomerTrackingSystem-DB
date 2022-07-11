/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220711@Harvey.Nguyen
    Task:	 	Enhance flow and need to clear all data   [Redmine ID: 169334]
    DBName:		DBCTS.bodb02
*/

USE [bodb02]
GO


TRUNCATE TABLE SPU_GroupBettingCustomer

TRUNCATE TABLE SPU_GroupBettingTicket

TRUNCATE TABLE SPU_GroupBettingTicket_History
