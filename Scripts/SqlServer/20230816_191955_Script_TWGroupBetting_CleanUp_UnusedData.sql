/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230816@Victoria.Le
	Task : TW Group Betting - CleanUp Unsed Data
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230816@Victoria.Le: 	Initial Writing [Redmine ID: #191955]
*/

USE [bodb02]

DECLARE @Yesterday DATE = DATEADD(DAY,-1,GETDATE())
	,	@BatchSize INT = 5000 
;
	
WHILE (1=1)
BEGIN
	
	DELETE TOP (@BatchSize) gbt
	FROM dbo.SPU_GroupBettingTicket AS gbt WITH(ROWLOCK)
	WHERE gbt.TransDate < @Yesterday;

	IF @@ROWCOUNT = 0
		BREAK;
		
	WAITFOR DELAY '00:00:00:050'
	
END;