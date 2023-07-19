/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230719@Long.Luu
	Task : TW Group Betting - Update rule's config/threshold
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230719@Long.Luu: 	TW Group Betting - Update rule's config/threshold[Redmine ID: #191399]
*/

USE [bodb02];

UPDATE r WITH(ROWLOCK, UPDLOCK)
SET r.TicketCountLimit = CASE 
							WHEN g.Sporttype = 1 THEN (r.TicketCountLimit + 1) 
							ELSE (r.TicketCountLimit - 1) 
						END
FROM [dbo].[SPU_GroupBettingRule] AS r
INNER JOIN [dbo].[SPU_GroupBettingGroupingRule] AS g WITH(NOLOCK) 
	ON r.RuleId = g.RuleId;