/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230829@Long.Luu
	Task : TW Group Betting - Update Rules' Thresholds
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230829@Long.Luu: 	TW Group Betting - Update Rules' Thresholds [Redmine ID: #192976]
*/

USE [bodb02];

UPDATE [dbo].[SPU_GroupBettingRule] WITH(ROWLOCK, UPDLOCK)
SET RFMLimitPercent = 80, CustClassLimitPercent = 60, BetFromLimitPercent = 80
WHERE RuleId = 2;

UPDATE [dbo].[SPU_GroupBettingRule] WITH(ROWLOCK, UPDLOCK)
SET RFMLimitPercent = 70, CustClassLimitPercent = 60, BetFromLimitPercent = 80
WHERE RuleId = 4;

UPDATE [dbo].[SPU_GroupBettingRule] WITH(ROWLOCK, UPDLOCK)
SET RFMLimitPercent = 70, CustClassLimitPercent = 70, BetFromLimitPercent = 80
WHERE RuleId IN (6,8);

UPDATE [dbo].[SPU_GroupBettingRule] WITH(ROWLOCK, UPDLOCK)
SET TicketCountLimit = 10
WHERE RuleId = 5;

UPDATE [dbo].[SPU_GroupBettingRule] WITH(ROWLOCK, UPDLOCK)
SET TicketCountLimit = 5
WHERE RuleId = 7;