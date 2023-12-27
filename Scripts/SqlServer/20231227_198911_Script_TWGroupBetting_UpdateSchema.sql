/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20231227@Victoria.Le
	Task : TW Group Betting - Add new columns
	DB:			
	
	Description: 

	Revisions:	
		- 20231227@Victoria.Le: 	Initial Writing [Redmine ID: #198911]
		
	Param's Explanation (filtered by):

	Example:
*/

	USE [bodb02];

	ALTER TABLE dbo.SPU_GroupBettingTicket_History 
	ADD InsertTime DATETIME DEFAULT GETDATE();