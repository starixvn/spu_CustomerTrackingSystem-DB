/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231226@Casey.Huynh
Task:	 	Danger Monitor
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231226@Casey.Huynh: Created [Redmine ID: #196361]
Reviewer:
*/
USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.SportBettypeSetting(FunctionID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection, MMReason, IsDefaultSelected,PriorityOrder,Status)
VALUES(2,0,1,'','Handicap',null,'HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,'0,1,2,3,58',1,1,1)
,(2,0,2,'','Odd/Even',null,'O/E','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "e", "BetChoiceHomeDisplay": "o"}',2,null,0,null,0,25,1)
,(2,0,3,'','Over/Under',null,'O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,'0,1,2,3,58',1,2,1)
,(2,0,6,'','Total Goal',null,'Total Goal',null,1,null,0,null,0,29,1)
,(2,0,7,'','1H Handicap',null,'1H HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,'0,1,2,3,58',1,3,1)
,(2,0,8,'','1H Over/Under',null,'1H O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,'0,1,2,3,58',1,4,1)
,(2,0,12,'','1H Odd/Even',null,'1H O/E','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "e", "BetChoiceHomeDisplay": "o"}',2,null,0,null,0,26,1)
,(2,0,126,'','1H Total Goal',null,'1H Total Goal',null,1,null,0,null,0,30,1)
,(2,0,413,'','Correct Score (AOS)',null,'Correct Score',null,1,null,0,null,0,27,1)
,(2,0,414,'','1H Correct Score (AOS)',null,'1H Correct Score',null,1,null,0,null,0,28,1)
,(2,0,20,'','Moneyline',null,'ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,'0,3',0,9,1)
,(2,0,609,'','Quarter X Handicap','1,2,3,4','Quarter X HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,'0,3',0,10,1)
,(2,0,610,'','Quarter X Over/Under','1,2,3,4','Quarter X O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,'0,3',0,14,1)
,(2,0,612,'','Quarter X Moneyline','1,2,3,4','Quarter X ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,'0,3',0,18,1)
;

