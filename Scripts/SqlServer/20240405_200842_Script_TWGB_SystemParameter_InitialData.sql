/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240405@Victoria.Le
	Task:		Initial Data for SystemParameter - Job clean up data from 2 tables: TWGroupBettingTicket and TWGroupBettingTicket_History
	Server:		DB061 & DB062 
	
	Revisions:
			- 20240405@Victoria.Le: Initial Writing [Redmine: #200842]
*/


USE	WASAVerse;
GO

INSERT INTO dbo.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) VALUES 
	(7,'TWGroupBetting_CleanUp_Flag','TWGroupBetting_Job_CleanUpFlag','SMALLINT','2')
,	(8,'TWGroupBetting_RemainDays_TicketHistory','TWGroupBetting_RemainDays_TicketHistoryTable','SMALLINT','14')
,	(9,'TWGroupBetting_RemainDays_Ticket','TWGroupBetting_RemainDays_TicketTable','SMALLINT','1')
;