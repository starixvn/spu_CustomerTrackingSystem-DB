/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
    Creator: 	20250317@Casey.Huynh
    Task:	 	Match Monitor[Redmine ID: #219681]
    DBName:		bodb02
*/
USE WASAVerse;

--===========CTS_Rpt_MatchMonitor_GetTicketInfo Change to  CTS_MatchMonitor_GetNewTicket============
DROP PROCEDURE IF EXISTS CTS_Rpt_MatchMonitor_GetTicketInfo;
DROP PROCEDURE IF EXISTS CTS_Rpt_MatchMonitor_GetTicketInfo_xtest;

--===========CTS_TicketDetails_Info Change to  CTS_MatchMonitor_Details_GetFilter============
DROP PROCEDURE IF EXISTS CTS_TicketDetails_Info;
DROP PROCEDURE IF EXISTS CTS_TicketDetails_Info_xtest;

--===========CTS_Rpt_MatchMonitor_TicketDetails Change to  CTS_MatchMonitor_Details_GetTicket============
DROP PROCEDURE IF EXISTS CTS_Rpt_MatchMonitor_TicketDetails;
DROP PROCEDURE IF EXISTS CTS_Rpt_MatchMonitor_TicketDetails_xtest;

