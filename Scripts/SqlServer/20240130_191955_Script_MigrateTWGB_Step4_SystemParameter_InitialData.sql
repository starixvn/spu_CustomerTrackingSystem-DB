/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240130@Victoria.Le
	Task:		Initial Data for SystemParameter - Need to get the latest value of paramid before deploying
	Server:		DB061 & DB062
	
	Revisions:
			- 20240130@Victoria.Le: Initial Writing - Step 4[Redmine: #191955]	
*/


USE	WASAVerse;
GO

INSERT INTO dbo.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) VALUES 
	(1,'TWGroupBetting_LastScanTime','TWGroupBetting_LastScanTransSec','BIGINT','0')
,	(2,'TWGroupBetting_SkipTransCount','TWGroupBetting_SkipTransCount','INT','0')
,	(3,'TWGroupBetting_LastSequenceId','TWGroupBetting_LastSequenceId','BIGINT','0')
,	(4,'TWGroupBetting_CountTotalTicket_BatchSize','TWGroupBetting_CountTotalTicket_BatchSize','INT','0')
,	(5,'TWGroupBetting_CountTotalTicket_LastSequenceId','TWGroupBetting_CountTotalTicket_LastSequenceId','BIGINT','0')
,	(6,'TWGroupBetting_CountTotalTicket_Interruptted','TWGroupBetting_CountTotalTicket_Interruptted','BIT','0')
;