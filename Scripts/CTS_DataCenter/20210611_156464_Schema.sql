/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210611@Casey.Huynh
Task:	 	Schema Member Profile Check List [Redmine ID: 156464] 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
	-	[20210611@Casey.Huynh][156464]: Create
Reviewer:
*/
USE CTS_DataCenter;
#DROP  Table ProblemCaseMonitor;
CREATE TABLE ProblemCaseMonitor(
		CreatedDate	DATETIME	
    ,	ProblemCaseID	SMALLINT
    , 	CustID		BIGINT UNSIGNED
	,	CustSubID	BIGINT UNSIGNED
    ,	InsertTime	DATETIME(3)
	, 	PRIMARY KEY	PK_ProblemAccountMonitor(CreatedDate,ProblemCaseID,CustID,CustSubID)
    ,	INDEX IX_ProblemCaseMonitor_CustIDProblemCaseID(CustID,ProblemCaseID)
) ENGINE=INNODB;

INSERT IGNORE INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,Status,Description,CreatedDate, PriorityOrder)
VALUES	(12,1,'Problem Case','Problem Case','Robot','Robot',1,NULL,NOW(),1)
	,	(12,2,'Problem Case','Problem Case','Hedging','Hedging',0,NULL,NOW(),2)
    ,	(12,3,'Problem Case','Problem Case','GroupBetting','Group Betting',0,NULL,NOW(),3)
    ,	(12,4,'Problem Case','Problem Case','SuspiciousAssociation','Suspicious Association',1,NULL,NOW(),4)
    ,	(12,5,'Problem Case','Problem Case','TimeInterval','Time Interval',0,NULL,NOW(),5)
    ,	(12,6,'Problem Case','Problem Case','CotinuesBetting','Cotinues Betting',0,NULL,NOW(),6)
    ,	(12,7,'Problem Case','Problem Case','Odds Favors','Odds Favors',0,NULL,NOW(),7)
    ,	(12,8,'Problem Case','Problem Case','HighOddsBettor','High Odds Bettor',0,NULL,NOW(),8)
	,	(12,9,'Problem Case','Problem Case','ProPuntor','Pro Puntor',1,NULL,NOW(),9);
    