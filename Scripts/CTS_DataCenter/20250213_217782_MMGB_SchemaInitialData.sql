/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250213@Thomas.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250213@Thomas.Nguyen: Created [Redmine ID: #217732]
        - 20250213@Casey.Huynh: Add script [Redmine ID: #217745]
Reviewer:
*/

USE CTS_DataCenter;

/*******************************SCRIPT FOR #217732*********************************/
/*Insert SportBettypeSetting*/
INSERT INTO SportBettypeSetting(FunctionID,SportTypeID,LeagueGroupID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,PriorityOrder,Status)
VALUES (1,2,0,21,'Basketball','1H Moneyline',null,'1H ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,'0',0,9,1);

/*Insert BettypeSetting*/
INSERT INTO BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES (21,1,'Home',2,'1H Moneyline',null,'1H ML',null,'h','h',1)
,(21,2,'Away',2,'1H Moneyline',null,'1H ML',null,'a','a',1);


/*******************************SCRIPT FOR #217745*********************************/
#=======================INITIAL SportBettypeSetting==========================
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,PriorityOrder,Status)
VALUES (1,0,50,501,'Cricket','Match Winner',NULL,'Match Winner','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,1,0,'0',0,9,1)
, (1,0,50,9404,'Cricket','Home Inns Runs',NULL,'Home Inns Runs','{"BetChoiceAway": "o", "BetChoiceHome": "u", "BetChoiceAwayDisplay": "o", "BetChoiceHomeDisplay": "u"}',2,NULL,1,0,'0',0,10,1)
, (1,0,50,9405,'Cricket','Away Inns Runs',NULL,'Away Inns Runs','{"BetChoiceAway": "o", "BetChoiceHome": "u", "BetChoiceAwayDisplay": "o", "BetChoiceHomeDisplay": "u"}',2,NULL,1,0,'0',0,11,1)
;

SELECT s.PriorityOrder, s.*
FROM CTS_DataCenter.SportBettypeSetting s
WHERE BetTypeID IN (20,21,501,9404,9405);

#=======================INITIAL BettypeSetting==========================
INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES	(501,1,'Home',2,'Match Winner',NULL,'Match Winner',NULL,'h','h',1)
,	(501,2,'Away',2,'Match Winner',NULL,'Match Winner',NULL,'a','a',1)
,	(9404,1,'Over',2,'Home Inns Runs',NULL,'Home Inns Runs',NULL,'o','o',1)
,	(9404,2,'Under',2,'Home Inns Runs',NULL,'Home Inns Runs',NULL,'u','u',1)
,	(9405,1,'Over',2,'Away Inns Runs',NULL,'Away Inns Runs',NULL,'o','o',1)
,	(9405,2,'Under',2,'Away Inns Runs',NULL,'Away Inns Runs',NULL,'u','u',1);

SELECT * From BettypeSetting WHERE BetTypeID IN (20,21,501,9404,9405);

#===========REMOVE Staticlist Sport ListID = 17 (no longer using)==============
DELETE del
FROM StaticList AS del
WHERE ListID = 17;

#=================Initial Rule Setting============================================
INSERT INTO MatchMonitorRuleSetting(RuleGroupID,RuleStatus,RuleGroupDesc,Reason,SportType,LeagueGroupID,LeagueType,ReasonName,SportName,TimeStep,TotalStake,CustStake,TotalTicket,HighStake,HighStakeTicketPercent,MinOdds,MaxOdds,OddsSpread,ModifiedDate,Comments)
VALUES	(1, 1,'Group Betting Detect', 0, 50, NULL,2, 'Group Betting', 'Cricket', 180, 300, NULL,NULL, NULL,NULL,NULL, NULL,NULL,NOW(), 'Time Step In Seconds');

SELECT * FROM MatchMonitorRuleSetting;

#==============================SET Betting Order=====================================================
ALTER TABLE BettypeSetting
ADD COLUMN BettypeOrder INT;

DROP TEMPORARY TABLE IF EXISTS  Temp_DisplayOrder;
CREATE TEMPORARY TABLE Temp_DisplayOrder(BettypeNameDisplay VARCHAR(100), BettypeOrder INT);

INSERT INTO Temp_DisplayOrder(BettypeNameDisplay, BettypeOrder)
VALUES('HDP',1000)
,('O/U',2000)
,('ML',3000)
,('1H HDP',4000)
,('1H O/U',5000)
,('1H ML',6000)
,('Quarter X HDP',7000)
,('Quarter X O/U',8000)
,('Quarter X ML',9000)
,('O/E',10000)
,('1H O/E',11000)
,('Correct Score',12000)
,('1H Correct Score',13000)
,('Total Goal',14000)
,('1H Total Goal',15000)
,('1X2',16000)
,('1H 1X2',17000)
,('Match Winner',18000)
,('Home Inns Runs',19000)
,('Away Inns Runs',20000)
,('Map X ML',21000)
,('Map X Round Y ML',22000)
,('Map X Total Gold ML',23000)
,('Map X Total Kills HDP',24000)
,('Map X Total Kills O/U',25000)
,('Map X Total Kills O/E',26000)
,('Map X First Blood',27000)
,('Map X First to Y Kills',28000)
,('Map X Round Y Total Kills O/U',29000)
,('Map X Round Y Total Kills O/E',30000)
,('Map X Round Y First Kill',31000)
,('Map X Round Y Total Kills HDP',32000)
,('Map X First to Y Kills Time(Mins) O/U',33000)
,('Map X First Blood Time(Mins) O/U',34000)
,('Map X Total Kills at 10 Mins HDP',35000)
,('Map X Total Kills at 10 Mins O/U',36000)
,('Map X Total Kills at 20 Mins HDP',37000)
,('Map X Total Kills at 20 Mins O/U',38000)
,('Map X Home Team Total Kills at 10 Mins O/U',39000)
,('Map X Away Team Total Kills at 10 Mins O/U',40000)
,('Map X Home Team Total Kills at 20 Mins O/U',41000)
,('Map X Away Team Total Kills at 20 Mins O/U',42000)
,('Map X Home Team Total Kills O/U',43000)
,('Map X Away Team Total Kills O/U',44000)
,('Map X 1st Kill',45000)
,('Map X 2nd Kill',46000)
,('Map X 3rd Kill',47000)
,('Map X 4th Kill',48000)
,('Map X 5th Kill',49000)
,('Map X 6th Kill',50000)
,('Map X 7th Kill',51000)
,('Map X 8th Kill',52000)
,('Map X 9th Kill',53000)
,('Map X 10th Kill',54000)
,('Map X 15th Kill',55000)
,('Map X 20th Kill',56000)
,('Map X Will Storm Dragon Be Killed Yes/No',57000)
,('Map X Will Elder Dragon Be Killed Yes/No',58000);

UPDATE BettypeSetting AS b
	INNER JOIN Temp_DisplayOrder t ON b.BettypeNameDisplay = t.BettypeNameDisplay
SET b.BettypeOrder = t.BettypeOrder;

SELECT DISTINCT bettypeID, BettypeNameDisplay, BettypeOrder
FROM BettypeSetting AS b 
ORDER BY BettypeOrder;

ALTER TABLE SportBettypeSetting
DROP COLUMN  PriorityOrder
;
