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
DROP TABLE SportBettypeSetting;
CREATE TABLE SportBettypeSetting(
		FunctionID				TINYINT	
	,	SportTypeID				SMALLINT NOT NULL
    ,	BetTypeID				INT NOT NULL
	,	SportName					VARCHAR(50) NOT NULL
    ,	BetTypeName					VARCHAR(128) NOT NULL
    ,	BetTypeNameDetailsX			VARCHAR(100)			# IF NOT NULL then show Details(Ex:show Details for Baskateball Quater 1..., Quater 2...
    ,	BettypeNameDisplay			VARCHAR(150) NOT NULL
    ,	BetChoiceType				TINYINT NOT NULL		# 1: Two choices, 0: ELSE
    ,	BetChoiceHome				VARCHAR(10)				# {"Home":"b", "Away":"a"}
    ,	BetChoiceAway				VARCHAR(10)
    ,	BetIDPattern				VARCHAR(20)
	,	IsMMDetection				BOOLEAN NOT NULL
    ,	IsDefaultSelected			BOOLEAN NOT NULL		# IF NOT NULL then show Details(Ex:show Details for Baskateball Quater 1..., Quater 2...
    ,	PriorityOrder				INT 
    ,	Status						TINYINT NOT NULL		# 1: Active, 0: Inactive
	
    ,	PRIMARY KEY PK_SportBettypeSetting(FunctionID,SportTypeID,BetTypeID)
);

INSERT INTO SportBettypeSetting(FunctionID,SportTypeID,BetTypeID,BetChoiceType,IsMMDetection,IsDefaultSelected,SportName,BettypeName,BettypeNameDisplay,BetChoiceHome,BetChoiceAway,BetIDPattern,BetTypeNameDetailsX,PriorityOrder,Status)
Values(1,1,1,1,1,1,'Soccer','Handicap','HDP','h','a',null,null,1,1)
,(1,1,3,1,1,1,'Soccer','Over/Under','O/U','h','a',null,null,2,1)
,(1,1,7,1,1,1,'Soccer','1H Handicap','1H HDP','h','a',null,null,3,1)
,(1,1,8,1,1,1,'Soccer','1H Over/Under','1H O/U','h','a',null,null,4,1)
,(1,1,2,1,0,0,'Soccer','Odd/Even','O/E','h','a',null,null,25,1)
,(1,1,12,1,0,0,'Soccer','1H Odd/Even','1H O/E','h','a',null,null,26,1)
,(1,1,413,0,0,0,'Soccer','Correct Score (AOS)','Correct Score',null,null,null,null,27,1)
,(1,1,414,0,0,0,'Soccer','1H Correct Score (AOS)','1H Correct Score',null,null,null,null,28,1)
,(1,1,6,0,0,0,'Soccer','Total Goal','Total Goal',null,null,null,null,29,1)
,(1,1,126,0,0,0,'Soccer','1H Total Goal','1H Total Goal',null,null,null,null,30,1)
,(1,1,5,0,0,0,'Soccer','FT.1X2','FT.1X2',null,null,null,null,31,1)
,(1,1,15,0,0,0,'Soccer','1H 1X2','1H 1X2',null,null,null,null,32,1)
,(1,2,1,1,1,0,'Basketball','Handicap','HDP','h','a',null,null,5,1)
,(1,2,3,1,1,0,'Basketball','Over/Under','O/U','h','a',null,null,6,1)
,(1,2,7,1,1,0,'Basketball','1H Handicap','1H HDP','h','a',null,null,7,1)
,(1,2,8,1,1,0,'Basketball','1H Over/Under','1H O/U','h','a',null,null,8,1)
,(1,2,20,1,1,0,'Basketball','Moneyline','ML','h','a',null,null,9,1)
,(1,2,609,1,1,0,'Basketball','Quarter X Handicap','Quarter X HDP','h','a','80X','1,2,3,4',10,1)
,(1,2,610,1,1,0,'Basketball','Quarter X Over/Under','Quarter X O/U','h','a','80X','1,2,3,4',14,1)
,(1,2,612,1,1,0,'Basketball','Quarter X Moneyline','Quarter X ML','h','a','80X','1,2,3,4',18,1)
,(1,43,1,1,1,0,'E-Sports','Handicap','HDP','h','a',null,null,22,1)
,(1,43,3,1,1,0,'E-Sports','Over/Under','O/U','h','a',null,null,23,1)
,(1,43,20,1,1,0,'E-Sports','Moneyline','ML','h','a',null,null,24,1)
,(1,43,9001,1,1,0,'E-Sports','Map X Moneyline','Map X ML','h','a','80X',null,33,1)
,(1,43,9068,1,1,0,'E-Sports','Map X Round Y Moneyline','Map X Round Y ML','h','a','80XYY',null,34,1)
,(1,43,9115,1,1,0,'E-Sports','Map X Total Gold Moneyline','Map X Total Gold ML','h','a','80X',null,35,1)
,(1,43,9002,1,1,0,'E-Sports','Map X Total Kills Handicap','Map X Total Kills HDP','h','a','80X',null,36,1)
,(1,43,9003,1,1,0,'E-Sports','Map X Total Kills Over/Under','Map X Total Kills O/U','o','u','80X',null,37,1)
,(1,43,9005,1,1,0,'E-Sports','Map X Total Kills Odd/Even','Map X Total Kills O/E','o','e','80X',null,38,1)
,(1,43,9006,1,1,0,'E-Sports','Map X First Blood','Map X First Blood','h','a','80X',null,39,1)
,(1,43,9007,1,1,0,'E-Sports','Map X First to Y Kills','Map X First to Y Kills','h','a','80XYY',null,40,1)
,(1,43,9070,1,1,0,'E-Sports','Map X Round Y Total Kills Over/Under','Map X Round Y Total Kills O/U','o','u','80XYY',null,41,1)
,(1,43,9071,1,1,0,'E-Sports','Map X Round Y Total Kills Odd/Even','Map X Round Y Total Kills O/E','o','e','80XYY',null,42,1)
,(1,43,9072,1,1,0,'E-Sports','Map X Round Y First Kill','Map X Round Y First Kill','h','a','80XYY',null,43,1)
,(1,43,9077,1,1,0,'E-Sports','Map X Round Y Total Kills Handicap','Map X Round Y Total Kills HDP','h','a','80XYY',null,44,1)
,(1,43,9089,1,1,0,'E-Sports','Map X First to Y Kills Time(Mins) Over/Under','Map X First to Y Kills Time(Mins) O/U','o','u','80XYY',null,45,1)
,(1,43,9090,1,1,0,'E-Sports','Map X First Blood Time(Mins) Over/Under','Map X First Blood Time(Mins) O/U','o','u','80X',null,46,1)
,(1,43,9091,1,1,0,'E-Sports','Map X Total Kills at 10 Mins Handicap','Map X Total Kills at 10 Mins HDP','h','a','80X',null,47,1)
,(1,43,9092,1,1,0,'E-Sports','Map X Total Kills at 10 Mins Over/Under','Map X Total Kills at 10 Mins O/U','o','u','80X',null,48,1)
,(1,43,9093,1,1,0,'E-Sports','Map X Total Kills at 20 Mins Handicap','Map X Total Kills at 20 Mins HDP','h','a','80X',null,49,1)
,(1,43,9094,1,1,0,'E-Sports','Map X Total Kills at 20 Mins Over/Under','Map X Total Kills at 20 Mins O/U','o','u','80X',null,50,1)
,(1,43,9095,1,1,0,'E-Sports','Map X Home Team Total Kills at 10 Mins Over/Under','Map X Home Team Total Kills at 10 Mins O/U','o','u','80X',null,51,1)
,(1,43,9096,1,1,0,'E-Sports','Map X Away Team Total Kills at 10 Mins Over/Under','Map X Away Team Total Kills at 10 Mins O/U','o','u','80X',null,52,1)
,(1,43,9097,1,1,0,'E-Sports','Map X Home Team Total Kills at 20 Mins Over/Under','Map X Home Team Total Kills at 20 Mins O/U','o','u','80X',null,53,1)
,(1,43,9098,1,1,0,'E-Sports','Map X Away Team Total Kills at 20 Mins Over/Under','Map X Away Team Total Kills at 20 Mins O/U','o','u','80X',null,54,1)
,(1,43,9099,1,1,0,'E-Sports','Map X Home Team Total Kills Over/Under','Map X Home Team Total Kills O/U','o','u','80X',null,55,1)
,(1,43,9100,1,1,0,'E-Sports','Map X Away Team Total Kills Over/Under','Map X Away Team Total Kills O/U','o','u','80X',null,56,1)
,(1,43,9101,1,1,0,'E-Sports','Map X 1st Kill','Map X 1st Kill','h','a','80X',null,57,1)
,(1,43,9102,1,1,0,'E-Sports','Map X 2nd Kill','Map X 2nd Kill','h','a','80X',null,58,1)
,(1,43,9103,1,1,0,'E-Sports','Map X 3rd Kill','Map X 3rd Kill','h','a','80X',null,59,1)
,(1,43,9104,1,1,0,'E-Sports','Map X 4th Kill','Map X 4th Kill','h','a','80X',null,60,1)
,(1,43,9105,1,1,0,'E-Sports','Map X 5th Kill','Map X 5th Kill','h','a','80X',null,61,1)
,(1,43,9106,1,1,0,'E-Sports','Map X 6th Kill','Map X 6th Kill','h','a','80X',null,62,1)
,(1,43,9107,1,1,0,'E-Sports','Map X 7th Kill','Map X 7th Kill','h','a','80X',null,63,1)
,(1,43,9108,1,1,0,'E-Sports','Map X 8th Kill','Map X 8th Kill','h','a','80X',null,64,1)
,(1,43,9109,1,1,0,'E-Sports','Map X 9th Kill','Map X 9th Kill','h','a','80X',null,65,1)
,(1,43,9110,1,1,0,'E-Sports','Map X 10th Kill','Map X 10th Kill','h','a','80X',null,66,1)
,(1,43,9111,1,1,0,'E-Sports','Map X 15th Kill','Map X 15th Kill','h','a','80X',null,67,1)
,(1,43,9112,1,1,0,'E-Sports','Map X 20th Kill','Map X 20th Kill','h','a','80X',null,68,1)
,(1,43,9124,1,1,0,'E-Sports','Map X Will Storm Dragon Be Killed Yes/No','Map X Will Storm Dragon Be Killed Yes/No','y','n','80X',null,69,1)
,(1,43,9132,1,1,0,'E-Sports','Map X Will Elder Dragon Be Killed Yes/No','Map X Will Elder Dragon Be Killed Yes/No','y','n','80X',null,70,1);

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
