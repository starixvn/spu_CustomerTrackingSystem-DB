/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240820@Casey.Huynh
Task:	 	Match Monitor Group Betting Parlay
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240820@Casey.Huynh: Created [Redmine ID: #207397]
Reviewer:
*/
USE CTS_DataCenter;

#===================1. SCHEMA=================================
DROP TABLE IF EXISTS MatchMonitorParlayStagingGroupBettingLive;
CREATE TABLE MatchMonitorParlayStagingGroupBettingLive(
		SequenceID	 		BIGINT UNSIGNED NOT NULL
	,	TransID				BIGINT UNSIGNED NOT NULL
    ,	Refno				BIGINT UNSIGNED NOT NULL
	,	TransIDm			BIGINT UNSIGNED NOT NULL	COMMENT 'bettransm.transId'
    ,	TransDate 			DATETIME(3) NOT NULL
	,	TransDateToSecond	BIGINT NOT NULL
	,	MatchID  			INT NOT NULL
	,	SportType  			INT NOT NULL
	,	ScoreDiff  			INT NOT NULL
	,	BettypeID  			INT NOT NULL
	,	BetID  				BIGINT NOT NULL
	,	Betteam  			VARCHAR(10) NOT NULL 
	,	CustID  			BIGINT UNSIGNED NOT NULL
    ,	CTSCustID			BIGINT UNSIGNED NOT NULL
	,	GroupID 			INT DEFAULT '0'
	,	LiveHomeScore		INT
	,	LiveAwayScore		INT
	,	EventDate 			DATE
	,	KickOffTime			DATETIME
	,	EventStatus			VARCHAR(50) 
	,	HomeID 				INT
	,	AwayID 				INT
	,	LeagueID			INT
    ,	LeagueName 			VARCHAR(500)
	,	InsertTime 			DATETIME(3)	 
	,	PRIMARY KEY(SequenceID,TransIDm)
	,	INDEX IX_MMParlayStagingGroupBettingLive_TransDateToSecond(TransDateToSecond)
	,	INDEX IX_MMParlayStagingGroupBettingLive_RuleGroup(MatchID,ScoreDiff,BettypeID,BetID,Betteam,GroupID)
) ENGINE=InnoDB;

DROP  TABLE IF EXISTS MatchMonitorParlayStagingGroupBettingNonLive;
CREATE TABLE MatchMonitorParlayStagingGroupBettingNonLive(
		SequenceID	 		BIGINT UNSIGNED NOT NULL
	,	TransID				BIGINT UNSIGNED NOT NULL
    ,	Refno				BIGINT UNSIGNED NOT NULL
	,	TransIDm			BIGINT UNSIGNED NOT NULL	COMMENT 'bettransm.transId'
    ,	TransDate 			DATETIME(3) NOT NULL
	,	TransDateToSecond	BIGINT NOT NULL
	,	MatchID  			INT NOT NULL
	,	SportType  			INT NOT NULL
	,	ScoreDiff  			INT NOT NULL
	,	BettypeID  			INT NOT NULL
	,	BetID  				BIGINT NOT NULL
	,	Betteam  			VARCHAR(10) NOT NULL 
	,	CustID  			BIGINT UNSIGNED NOT NULL
    ,	CTSCustID			BIGINT UNSIGNED NOT NULL
	,	GroupID 			INT DEFAULT '0'
	,	LiveHomeScore		INT
	,	LiveAwayScore		INT
	,	EventDate 			DATE
	,	KickOffTime			DATETIME
	,	EventStatus			VARCHAR(50) 
	,	HomeID 				INT
	,	AwayID 				INT
	,	LeagueID			INT
    ,	LeagueName 			VARCHAR(500)
	,	InsertTime 			DATETIME(3)	 
	,	PRIMARY KEY(SequenceID,TransIDm)
	,	INDEX IX_MMParlayStagingGroupBettingNonLive_TransDateToSecond(TransDateToSecond)
	,	INDEX IX_MMParlayStagingGroupBettingNonLive_RuleGroup(MatchID,ScoreDiff,BettypeID,BetID,Betteam,GroupID)
) ENGINE=InnoDB;

ALTER TABLE MatchMonitor
ADD COLUMN TicketType SMALLINT DEFAULT 1;#COMMENT '1:Single Ticket, 2: Parlay';

ALTER TABLE MatchMonitorDetails
	ADD COLUMN ListTransIDm LONGTEXT AFTER ListTransID
,   ADD COLUMN ListRefno LONGTEXT AFTER ListTransID
,	ADD COLUMN TicketType SMALLINT DEFAULT 1;

ALTER TABLE MatchMonitorDetailsVerifiedTrans
	ADD COLUMN TicketType SMALLINT DEFAULT 1;

#==========Enhance SportBettype Setting================================
	DROP TABLE BettypeSetting;
	CREATE TABLE BettypeSetting (
			BetTypeID INT NOT NULL
		,	BetteamOrder TINYINT NOT NULL 
		,	BetteamName	VARCHAR(10) NOT NULL DEFAULT ''	
		,	BetChoiceType TINYINT NOT NULL
		,	BetTypeName VARCHAR(128) NOT NULL
        ,	BetTypeNameDetailsX VARCHAR(100)
		,	BetTypeNameDisplay VARCHAR(128) NULL	
		,	BetIDPattern varchar(20) NULL
		,	BetTeamDB VARCHAR(10) NULL 
		,	BetteamShortName VARCHAR(10) NULL
		,	Status tinyint	
	  
		,	PRIMARY KEY (BetTypeID, BetteamOrder)
	);

	INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder, BetteamName, BetTypeNameDetailsX, BetChoiceType,BetTypeName,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
	SELECT DISTINCT BetTypeID, 0, '' AS BetteamName, BetTypeNameDetailsX, BetChoiceType,BetTypeName,BetTypeNameDisplay,BetIDPattern
		,NULL AS BetTeamDB, NULL AS BetteamShortName, 1 AS Status
	FROM CTS_DataCenter.SportBettypeSetting
	WHERE BetChoiceType = 1;

	INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetTypeNameDetailsX,BetChoiceType,BetTypeName,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
	SELECT DISTINCT BetTypeID
	, 1 AS BetteamOrder
	,'Temp1' AS BetteamName, BetTypeNameDetailsX, BetChoiceType,BetTypeName,BetTypeNameDisplay,BetIDPattern
	, REPLACE(json_extract(BetChoicePattern, '$.BetChoiceHome'),'"','') AS BetTeamDB
	, REPLACE(json_extract(BetChoicePattern, '$.BetChoiceHomeDisplay'),'"','') BetteamShortName, 1 AS Status
	FROM CTS_DataCenter.SportBettypeSetting 
	WHERE BetChoiceType = 2;

	INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetTypeNameDetailsX,BetChoiceType,BetTypeName,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
	SELECT DISTINCT BetTypeID
	, 2 AS BetteamOrder
	,'Temp2' AS BetteamName,BetTypeNameDetailsX, BetChoiceType,BetTypeName,BetTypeNameDisplay,BetIDPattern
	, REPLACE(json_extract(BetChoicePattern, '$.BetChoiceAway'),'"','') AS BetTeamDB
	, REPLACE(json_extract(BetChoicePattern, '$.BetChoiceAwayDisplay'),'"','') BetteamShortName, 1 AS Status
	FROM CTS_DataCenter.SportBettypeSetting 
	WHERE BetChoiceType = 2;

	UPDATE BettypeSetting
	SET BetteamName = (CASE WHEN BetteamShortName = 'a' THEN 'Away'						
							WHEN BetteamShortName = 'h' THEN 'Home'						
							WHEN BetteamShortName = 'o' AND BettypeName LIKE '%Odd/%' THEN 'Odd'
							WHEN BetteamShortName = 'e' THEN 'Even'
							WHEN BetteamShortName = 'o' AND BettypeName LIKE '%Over/%' THEN 'Over'                       
							WHEN BetteamShortName = 'u' THEN 'Under'
							WHEN BetteamShortName = 'y' THEN 'Yes'
							WHEN BetteamShortName = 'n' THEN 'No'
							ELSE '' END)
		, BetteamDB = CASE WHEN BetteamDB = '' THEN NULL ELSE BetteamDB END 
		, BetteamShortName = CASE WHEN BetteamShortName = '' THEN NULL ELSE BetteamShortName END 
	;
	#----------------------------
	ALTER TABLE SportBettypeSetting
		ADD COLUMN IsMMParlayDetection	TINYINT(1) NOT NULL DEFAULT 0 AFTER IsMMDetection;
	#,	DROP COLUMN BetTypeName 
	#,	DROP COLUMN BettypeNameDistplay
	#,	DROP COLUMN BetChoicePattern
	#,	DROP COLUMN BetChoiceType
	#,	DROP COLUMN BetIDPattern;

	UPDATE CTS_DataCenter.SportBettypeSetting
	SET IsMMParlayDetection = 1
		, MMReason = CONCAT(MMReason, ',5')
	WHERE FunctionID = 1
		AND LeagueGroupID = 0
		AND SportTypeID = 1
		AND BettypeID IN(1,3,7,8);

	UPDATE CTS_DataCenter.SportBettypeSetting
	SET IsMMParlayDetection = 1
		, MMReason = CONCAT(MMReason, ',5')
	WHERE FunctionID = 1
		AND LeagueGroupID = 0
		AND SportTypeID = 2
		AND BettypeID IN(1,3,7,8,20, 609, 610, 612);
        
SELECT * FROM CTS_DataCenter.BettypeSetting;

#=============================INITIAL===========================================================
SELECT * FROM StaticList WHERE ListID = 16;

UPDATE StaticList
SET ListNameDisplay = 'Detect By System'
	, PriorityOrder =  NULL
WHERE ListID = 16 AND ItemID < 100;

UPDATE StaticList
SET ListNameDisplay = 'Detect By AI'
	, PriorityOrder =  NULL #remove PriorityOrder due to Web ordered by Alphabet
WHERE ListID = 16 
	AND ItemID = 100;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES( 16,200,'Match Monitor Reason','Detect By System Parlay','Group Betting Parlay','GB(P)',5,0,NULL,NULL,1,NULL,NOW());

SELECT * FROM StaticList WHERE ListID = 16;

#------------------------------------------------------------------------------------------------------
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(171,'MatchMonitorParlay_StagingLive_LastSequenceID','MatchMonitorParlay_StagingLive_LastSequenceID','BIGINT UNSIGNED','0')
, (172,'MatchMonitorParlay_StagingNonLive_LastSequenceID','MatchMonitorParlay_StagingNonLive_LastSequenceID','BIGINT UNSIGNED','0')
, (173,'MatchMonitorParlay_GB_Live_LastSequenceID','MatchMonitorParlay_GB_Live_LastSequenceID','BIGINT UNSIGNED','0')
, (174,'MatchMonitorParlay_GB_NonLive_LastSequenceID','MatchMonitorParlay_GB_NonLive_LastSequenceID','BIGINT UNSIGNED','0');

SELECT * FROM CTS_DataCenter.SystemParameter WHERe ParameterID IN (171,172,173,174);

#------------------------------------------------------------------------------------------------------
SELECT * FROM MatchMonitorRuleSetting;

INSERT INTO `CTS_DataCenter`.`MatchMonitorRuleSetting` (RuleGroupID, RuleStatus, RuleGroupDesc, Reason, SportType, LeagueGroupID, LeagueType, ReasonName, SportName, TimeStep, TotalStake, CustStake, TotalTicket, HighStake, HighStakeTicketPercent, MinOdds, MaxOdds, OddsSpread, ModifiedDate, Comments)
VALUES(7, 1, 'Group Betting Parlay Detect', 5, 0, NULL, 2, 'Group Betting Parlay', NULL, 180, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NULL);

SELECT * FROM MatchMonitorRuleSetting;