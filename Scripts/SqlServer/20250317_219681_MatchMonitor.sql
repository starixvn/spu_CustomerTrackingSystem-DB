/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
    Creator: 	20250317@Casey.Huynh
    Task:	 	Match Monitor[Redmine ID: #219681]
    DBName:		bodb02
*/
USE WASAVerse;

DROP PROCEDURE IF EXISTS CTS_Rpt_MatchMonitor_GetTicketInfo_xtest;

EXEC sp_rename 'CTS_Rpt_MatchMonitor_GetTicketInfo', 'CTS_MatchMonitor_GetNewTicket';

