/*<info serverAlias="DBCTS-bodb02,DBCTS-WASAVerse" databaseType="1"></info>*/
/*
Creator: 	20251020@Long.Luu
Task:	 	Extend Sporttype from Tinyint to Smallint [Redmine ID: 242108] 	
DBName:		DB061, DB062
*/

USE bodb02;
GO

DROP TABLE SPU_GroupBettingCustomer;
GO

DROP TABLE SPU_GroupBettingGroupingRule;
GO

DROP TABLE SPU_GroupBettingRule;
GO

DROP TABLE SPU_GroupBettingTicket;
GO

DROP TABLE SPU_GroupBettingTicket_History;
GO

-----------------------------------------------------------
USE WASAVerse;
GO

ALTER TABLE TWGroupBettingGroupingRule
ALTER COLUMN Sporttype SMALLINT NULL;
GO


