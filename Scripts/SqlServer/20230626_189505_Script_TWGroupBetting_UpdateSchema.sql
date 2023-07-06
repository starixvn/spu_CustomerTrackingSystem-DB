/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230626@Victoria.Le
	Task : TW Group Betting - Add new columns
	DB:			
	
	Description: 

	Revisions:	
		- 20230626@Victoria.Le: 	Initial Writing [Redmine ID: #189505]
		
	Param's Explanation (filtered by):

	Example:
*/

	USE [bodb02];

	ALTER TABLE dbo.SPU_GroupBettingTicket_History ADD
	RulesType	VARCHAR(100) 
,	IsRule1		BIT 
,	IsRule2		BIT 
,	IsRule3		BIT 
;

	ALTER TABLE dbo.SPU_GroupBettingCustomer ADD 
	RejectTicketCount	INT 
,	DesktopTicketCount	INT 
,	ParlayTicketCount	INT 
;
