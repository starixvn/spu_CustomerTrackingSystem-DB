/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202311203@Casey.Huynh
Task:	 	Match Monitor Adjust GB Esport Setting 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202311203@Casey.Huynh: Created [Redmine ID: #196396]
Reviewer:
*/
USE CTS_DataCenter;
CREATE TABLE SportBettypeSetting (
  FunctionID tinyint NOT NULL,
  SportTypeID smallint NOT NULL,
  BetTypeID int NOT NULL,
  SportName varchar(50) NOT NULL,
  BetTypeName varchar(128)  NOT NULL,
  BetTypeNameDetailsX varchar(100) DEFAULT NULL,
  BettypeNameDisplay varchar(150) NOT NULL,
  BetChoicePattern json DEFAULT NULL,
  BetChoiceType tinyint NOT NULL,
  BetIDPattern varchar(20) DEFAULT NULL,
  IsMMDetection tinyint(1) NOT NULL,
  IsDefaultSelected tinyint(1) NOT NULL,
  PriorityOrder int DEFAULT NULL,
  Status tinyint NOT NULL,
  PRIMARY KEY (FunctionID,SportTypeID,BetTypeID)
) ENGINE=InnoDB;

ALTER TABLE CTS_DataCenter.SportBettypeSetting
ADD COLUMN MMReason VARCHAR(200) AFTER IsMMDetection;

SELECT * FROM CTS_DataCenter.SportBettypeSetting;

SELECT * FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst;

UPDATE CTS_DataCenter.SportBettypeSetting
SET MMReason = '0'
WHERE SportTypeID = 1;

INSERT INTO CTS_DataCenter.SportBettypeSetting(FunctionID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsDefaultSelected,PriorityOrder,Status)
VALUES(1,1,1,'Soccer','Handicap',null,'HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,1,1,1)
,(1,1,2,'Soccer','Odd/Even',null,'O/E','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "e", "BetChoiceHomeDisplay": "o"}',2,null,0,0,25,1)
,(1,1,3,'Soccer','Over/Under',null,'O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,1,2,1)
,(1,1,5,'Soccer','FT.1X2',null,'1X2',null,1,null,0,0,31,1)
,(1,1,6,'Soccer','Total Goal',null,'Total Goal',null,1,null,0,0,29,1)
,(1,1,7,'Soccer','1H Handicap',null,'1H HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,1,3,1)
,(1,1,8,'Soccer','1H Over/Under',null,'1H O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,1,4,1)
,(1,1,12,'Soccer','1H Odd/Even',null,'1H O/E','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "e", "BetChoiceHomeDisplay": "o"}',2,null,0,0,26,1)
,(1,1,15,'Soccer','1H 1X2',null,'1H 1X2',null,1,null,0,0,32,1)
,(1,1,126,'Soccer','1H Total Goal',null,'1H Total Goal',null,1,null,0,0,30,1)
,(1,1,413,'Soccer','Correct Score (AOS)',null,'Correct Score',null,1,null,0,0,27,1)
,(1,1,414,'Soccer','1H Correct Score (AOS)',null,'1H Correct Score',null,1,null,0,0,28,1)
,(1,2,1,'Basketball','Handicap',null,'HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,5,1)
,(1,2,3,'Basketball','Over/Under',null,'O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,0,6,1)
,(1,2,7,'Basketball','1H Handicap',null,'1H HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,7,1)
,(1,2,8,'Basketball','1H Over/Under',null,'1H O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,0,8,1)
,(1,2,20,'Basketball','Moneyline',null,'ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,9,1)
,(1,2,609,'Basketball','Quarter X Handicap','1,2,3,4','Quarter X HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,10,1)
,(1,2,610,'Basketball','Quarter X Over/Under','1,2,3,4','Quarter X O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,14,1)
,(1,2,612,'Basketball','Quarter X Moneyline','1,2,3,4','Quarter X ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,18,1)
,(1,43,1,'E-Sports','Handicap',null,'HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,22,1)
,(1,43,3,'E-Sports','Over/Under',null,'O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,null,1,0,23,1)
,(1,43,20,'E-Sports','Moneyline',null,'ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,24,1)
,(1,43,9001,'E-Sports','Map X Moneyline',null,'Map X ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,33,1)
,(1,43,9002,'E-Sports','Map X Total Kills Handicap',null,'Map X Total Kills HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,36,1)
,(1,43,9003,'E-Sports','Map X Total Kills Over/Under',null,'Map X Total Kills O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,37,1)
,(1,43,9005,'E-Sports','Map X Total Kills Odd/Even',null,'Map X Total Kills O/E','{"BetChoiceAway": "e", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "e", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,38,1)
,(1,43,9006,'E-Sports','Map X First Blood',null,'Map X First Blood','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,39,1)
,(1,43,9007,'E-Sports','Map X First to Y Kills',null,'Map X First to Y Kills','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80XYY',1,0,40,1)
,(1,43,9068,'E-Sports','Map X Round Y Moneyline',null,'Map X Round Y ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80XYY',1,0,34,1)
,(1,43,9070,'E-Sports','Map X Round Y Total Kills Over/Under',null,'Map X Round Y Total Kills O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80XYY',1,0,41,1)
,(1,43,9071,'E-Sports','Map X Round Y Total Kills Odd/Even',null,'Map X Round Y Total Kills O/E','{"BetChoiceAway": "e", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "e", "BetChoiceHomeDisplay": "o"}',2,'80XYY',1,0,42,1)
,(1,43,9072,'E-Sports','Map X Round Y First Kill',null,'Map X Round Y First Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80XYY',1,0,43,1)
,(1,43,9077,'E-Sports','Map X Round Y Total Kills Handicap',null,'Map X Round Y Total Kills HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80XYY',1,0,44,1)
,(1,43,9089,'E-Sports','Map X First to Y Kills Time(Mins) Over/Under',null,'Map X First to Y Kills Time(Mins) O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80XYY',1,0,45,1)
,(1,43,9090,'E-Sports','Map X First Blood Time(Mins) Over/Under',null,'Map X First Blood Time(Mins) O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,46,1)
,(1,43,9091,'E-Sports','Map X Total Kills at 10 Mins Handicap',null,'Map X Total Kills at 10 Mins HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,47,1)
,(1,43,9092,'E-Sports','Map X Total Kills at 10 Mins Over/Under',null,'Map X Total Kills at 10 Mins O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,48,1)
,(1,43,9093,'E-Sports','Map X Total Kills at 20 Mins Handicap',null,'Map X Total Kills at 20 Mins HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,49,1)
,(1,43,9094,'E-Sports','Map X Total Kills at 20 Mins Over/Under',null,'Map X Total Kills at 20 Mins O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,50,1)
,(1,43,9095,'E-Sports','Map X Home Team Total Kills at 10 Mins Over/Under',null,'Map X Home Team Total Kills at 10 Mins O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,51,1)
,(1,43,9096,'E-Sports','Map X Away Team Total Kills at 10 Mins Over/Under',null,'Map X Away Team Total Kills at 10 Mins O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,52,1)
,(1,43,9097,'E-Sports','Map X Home Team Total Kills at 20 Mins Over/Under',null,'Map X Home Team Total Kills at 20 Mins O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,53,1)
,(1,43,9098,'E-Sports','Map X Away Team Total Kills at 20 Mins Over/Under',null,'Map X Away Team Total Kills at 20 Mins O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,54,1)
,(1,43,9099,'E-Sports','Map X Home Team Total Kills Over/Under',null,'Map X Home Team Total Kills O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,55,1)
,(1,43,9100,'E-Sports','Map X Away Team Total Kills Over/Under',null,'Map X Away Team Total Kills O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,56,1)
,(1,43,9101,'E-Sports','Map X 1st Kill',null,'Map X 1st Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,57,1)
,(1,43,9102,'E-Sports','Map X 2nd Kill',null,'Map X 2nd Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,58,1)
,(1,43,9103,'E-Sports','Map X 3rd Kill',null,'Map X 3rd Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,59,1)
,(1,43,9104,'E-Sports','Map X 4th Kill',null,'Map X 4th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,60,1)
,(1,43,9105,'E-Sports','Map X 5th Kill',null,'Map X 5th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,61,1)
,(1,43,9106,'E-Sports','Map X 6th Kill',null,'Map X 6th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,62,1)
,(1,43,9107,'E-Sports','Map X 7th Kill',null,'Map X 7th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,63,1)
,(1,43,9108,'E-Sports','Map X 8th Kill',null,'Map X 8th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,64,1)
,(1,43,9109,'E-Sports','Map X 9th Kill',null,'Map X 9th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,65,1)
,(1,43,9110,'E-Sports','Map X 10th Kill',null,'Map X 10th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,66,1)
,(1,43,9111,'E-Sports','Map X 15th Kill',null,'Map X 15th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,67,1)
,(1,43,9112,'E-Sports','Map X 20th Kill',null,'Map X 20th Kill','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,68,1)
,(1,43,9115,'E-Sports','Map X Total Gold Moneyline',null,'Map X Total Gold ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,35,1)
,(1,43,9124,'E-Sports','Map X Will Storm Dragon Be Killed Yes/No',null,'Map X Will Storm Dragon Be Killed Yes/No','{"BetChoiceAway": "n", "BetChoiceHome": "y", "BetChoiceAwayDisplay": "n", "BetChoiceHomeDisplay": "y"}',2,'80X',1,0,69,1)
,(1,43,9132,'E-Sports','Map X Will Elder Dragon Be Killed Yes/No',null,'Map X Will Elder Dragon Be Killed Yes/No','{"BetChoiceAway": "n", "BetChoiceHome": "y", "BetChoiceAwayDisplay": "n", "BetChoiceHomeDisplay": "y"}',2,'80X',1,0,70,1);

SELECT * FROM SportBettypeSetting;
#======================================
SELECT * FROM SportBettypeSetting;
SELECT * FROM MatchMonitorRuleSetting WHERE RuleGroupID = 1 AND SportType = 43;

UPDATE MatchMonitorRuleSetting
SET TotalStake = 300
WHERE RuleGroupID = 1 AND SportType = 43;

/***Script Get Data From MainDB To "SportBettypeSetting"
IF	OBJECT_ID('tempdb..#tmpSupportedSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedSportBettype;
	END;

	CREATE TABLE	#tmpSupportedSportBettype(
			FunctionID				TINYINT
		,	SportType SMALLINT
		,	BetType			SMALLINT
		,	BetChoiceType	BIT
		,	IsDetectMatchMonitor			BIT
		,	IsDefaultSelected				BIT
	);
Insert into #tmpSupportedSportBettype(FunctionID,SportType,BetType,BetChoiceType,IsDetectMatchMonitor,IsDefaultSelected)
Values(1,1,1,1,1,1)
,(1,1,3,1,1,1)
,(1,1,7,1,1,1)
,(1,1,8,1,1,1)
,(1,1,2,1,0,0)
,(1,1,12,1,0,0)
,(1,1,413,0,0,0)
,(1,1,414,0,0,0)
,(1,1,6,0,0,0)
,(1,1,126,0,0,0)
,(1,1,5,0,0,0)
,(1,1,15,0,0,0)
,(1,2,1,1,1,0)
,(1,2,3,1,1,0)
,(1,2,7,1,1,0)
,(1,2,8,1,1,0)
,(1,2,20,1,1,0)
,(1,2,609,1,1,0)
,(1,2,610,1,1,0)
,(1,2,612,1,1,0)
,(1,43,1,1,1,0)
,(1,43,3,1,1,0)
,(1,43,20,1,1,0)
,(1,43,9001,1,1,0)
,(1,43,9068,1,1,0)
,(1,43,9115,1,1,0)
,(1,43,9002,1,1,0)
,(1,43,9003,1,1,0)
,(1,43,9005,1,1,0)
,(1,43,9006,1,1,0)
,(1,43,9007,1,1,0)
,(1,43,9070,1,1,0)
,(1,43,9071,1,1,0)
,(1,43,9072,1,1,0)
,(1,43,9077,1,1,0)
,(1,43,9089,1,1,0)
,(1,43,9090,1,1,0)
,(1,43,9091,1,1,0)
,(1,43,9092,1,1,0)
,(1,43,9093,1,1,0)
,(1,43,9094,1,1,0)
,(1,43,9095,1,1,0)
,(1,43,9096,1,1,0)
,(1,43,9097,1,1,0)
,(1,43,9098,1,1,0)
,(1,43,9099,1,1,0)
,(1,43,9100,1,1,0)
,(1,43,9101,1,1,0)
,(1,43,9102,1,1,0)
,(1,43,9103,1,1,0)
,(1,43,9104,1,1,0)
,(1,43,9105,1,1,0)
,(1,43,9106,1,1,0)
,(1,43,9107,1,1,0)
,(1,43,9108,1,1,0)
,(1,43,9109,1,1,0)
,(1,43,9110,1,1,0)
,(1,43,9111,1,1,0)
,(1,43,9112,1,1,0)
,(1,43,9124,1,1,0)
,(1,43,9132,1,1,0)

SELECT tmp.*, SportName, TypeNamee AS BettypeName
, REPLACE(REPLACE(REPLACE(REPLACE(TypeNamee,'Handicap','HDP'),'Over/Under','O/U'),'Odd/Even','O/E'),'Moneyline','ML') AS BettypeNameDisplay
, CASE WHEN BetChoiceType=1 AND Bettype < 9001 THEN 'h' 
    WHEN BetChoiceType=1 AND  Bettype > = 9001 AND TypeNamee LIKE '%Handicap%' THEN 'h' 
    WHEN BetChoiceType=1 AND Bettype > = 9001 AND TypeNamee LIKE '%Over/Under%' THEN 'o' 
    WHEN BetChoiceType=1 AND Bettype > = 9001 AND TypeNamee LIKE '%Odd/Even%' THEN 'o' 
    WHEN BetChoiceType=1 AND Bettype > = 9001 AND TypeNamee LIKE '%Yes/No%' THEN 'y'
    WHEN BetChoiceType=1 AND  Bettype > = 9001 THEN 'h'       
   
    END AS BetChoiceHome 
, CASE WHEN BetChoiceType=1 AND Bettype < 9001 THEN 'a' 
    WHEN BetChoiceType=1 AND  Bettype > = 9001 AND TypeNamee LIKE '%Handicap%' THEN 'a' 
    WHEN BetChoiceType=1 AND Bettype > = 9001 AND TypeNamee LIKE '%Over/Under%' THEN 'u' 
    WHEN BetChoiceType=1 AND Bettype > = 9001 AND TypeNamee LIKE '%Odd/Even%' THEN 'e' 
    WHEN BetChoiceType=1 AND Bettype > = 9001 AND TypeNamee LIKE '%Yes/No%' THEN 'n'
    WHEN BetChoiceType=1 AND  Bettype > = 9001 THEN 'a' 

    END AS BetChoiceAway 
FROM #tmpSupportedSportBettype AS tmp
LEFT JOIN Bettype AS b WITH(NOLOCK) ON b.TypeID = tmp.Bettype
LEFT JOIN Sports AS s WITH(NOLOCK) ON s.SportType = tmp.SportType
