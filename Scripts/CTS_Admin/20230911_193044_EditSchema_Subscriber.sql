/*<info serverAlias="CTSMain-CTS_Admin" databaseType="2"></info>*/
/*
Creator:	20230911@Victoria.Le
Task:	 	ManageSubscriber SubscriberSource
Server:  	Master
DBName:		CTS_Admin

Revisions: 
		- 20230911@Victoria.Le: Initial Writing [Redmine ID: #193044]          

*/

USE CTS_Admin;

ALTER TABLE Subscriber
	ADD SubscriberSourceID TINYINT UNSIGNED COMMENT '0: Others, 1: Direct API, 2: Oddsfeed' AFTER SubscriberType ;


UPDATE CTS_Admin.Subscriber AS sub
SET sub.SubscriberSourceID = CASE 	WHEN sub.SubscriberName IN ('JDYgaming','WGsports') THEN 1 -- Direct API
									WHEN sub.SubscriberName IN ('NextBet','9wickets','YHTY','AGCGlobal','Bet38') THEN 2 -- Oddsfeed
									ELSE 0 -- Others
							 END
;