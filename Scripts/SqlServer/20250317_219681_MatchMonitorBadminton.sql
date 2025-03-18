/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
    Creator: 	20250317@Casey.Huynh
    Task:	 	Match Monitor[Redmine ID: #219681]
    DBName:		bodb02
*/
USE WASAVerse;

--==================================================================
DROP PROCEDURE IF EXISTS CTS_Rpt_MatchMonitor_GetTicketInfo_xtest;
EXEC sp_rename 'CTS_Rpt_MatchMonitor_GetTicketInfo', 'CTS_MatchMonitor_GetNewTicket';

--==================================================================
DROP PROCEDURE IF EXISTS CTS_MatchMonitor_Details_GetFilter_xtest;
EXEC sp_rename 'CTS_TicketDetails_Info', 'CTS_MatchMonitor_Details_GetFilter';

--==================================================================
DROP PROCEDURE IF EXISTS CTS_MatchMonitor_Details_GetFilter_xtest;
EXEC sp_rename 'CTS_Rpt_MatchMonitor_TicketDetails', 'CTS_MatchMonitor_Details_GetTicket';

