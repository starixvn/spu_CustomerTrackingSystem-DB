/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211110@Casey.Huynh
Task:	 	System Fomular Bet Monitor
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20211110@Casey.Huynh: Created [Redmine ID: #164148]
Reviewer:

*/
USE CTS_DataCenter;

CREATE TABLE SystemFormulaBetMonitor(
		CustID		INT UNSIGNED
	,	CreatedDate	DATETIME
	,	PRIMARY KEY PK_SystemFormularBetMonitor(CustID)
    ,	INDEX IX_SystemFormularBetMonitor_CreatedDate(CreatedDate)
) ENGINE=InnoDB;
