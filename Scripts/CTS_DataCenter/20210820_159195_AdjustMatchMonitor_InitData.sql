/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20210820@Long.Luu
Task:	 	Adjust Match Monitor
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
		- 20210820@Long.Luu: Created [#159195]
        - 20210823@Casey.Huynh: Seperate scan for Live and NonLive [Redmine ID: 159195]
Reviewer:
*/
USE CTS_DataCenter;

DELETE sys 
FROM CTS_DataCenter.SystemParameter AS sys
WHERE ParameterID IN (20,29);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(20,'MatchMonitor_StagingInsert_LiveLastTransID','MatchMonitor_StagingInsert_LiveLastTransID','BIGINT UNSIGNED','0')
	, (29,'MatchMonitor_StagingInsert_NonliveLastTransID','MatchMonitor_StagingInsert_NonliveLastTransID','BIGINT UNSIGNED','0')
	, (42,'MatchMonitor_RuleProcess_LiveLastTransID','MatchMonitor_RuleProcess_LiveLastTransID','BIGINT UNSIGNED','0')
	, (43,'MatchMonitor_RuleProcess_NonliveLastTransID','MatchMonitor_RuleProcess_NonliveLastTransID','BIGINT UNSIGNED','0');

UPDATE CTS_DataCenter.SystemParameter 
SET ParameterValue = 112942394982
WHERE ParameterID IN (20,29);

TRUNCATE TABLE CTS_DataCenter.MatchMonitorStagingLive;
TRUNCATE TABLE CTS_DataCenter.MatchMonitorStagingNonLive;
TRUNCATE TABLE CTS_DataCenter.MatchMonitorDetails;
TRUNCATE TABLE CTS_DataCenter.MatchMonitor;

/*


DROP TABLE CTS_DataCenter.MatchMonitorStaging;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitorStagingLive;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorStagingLive(
		TransID			BIGINT UNSIGNED
	, 	TransDate		DATETIME(3)
    ,	MatchID			BIGINT UNSIGNED
    ,   TotalScore		SMALLINT UNSIGNED
    ,	BettypeID		INT UNSIGNED
    , 	CustID			BIGINT UNSIGNED
    ,	Stake			DECIMAL(20,4)        
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    , 	EventDate		DATE
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED      
    ,	GroupID			INT UNSIGNED DEFAULT 0
    ,	InsertTime		DATETIME(3)
    
	, 	PRIMARY KEY		PK_MatchMonitorStagingLive_TransID(TransID)
	, 	INDEX			IX_MatchMonitorStagingLive_Group(MatchID, TotalScore, BettypeID, GroupID)
    ,	INDEX			IX_MatchMonitorStagingLive_TransDate(TransDate)
) ENGINE=INNODB;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitorStagingNonLive;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorStagingNonLive(
		TransID			BIGINT UNSIGNED
	, 	TransDate		DATETIME(3)
    ,	MatchID			BIGINT UNSIGNED
    ,   TotalScore		SMALLINT UNSIGNED
    ,	BettypeID		INT UNSIGNED
    , 	CustID			BIGINT UNSIGNED
    ,	Stake			DECIMAL(20,4)        
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    , 	EventDate		DATE
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED      
    ,	GroupID			INT UNSIGNED DEFAULT 0
    ,	InsertTime		DATETIME(3)
    
	, 	PRIMARY KEY		PK_MatchMonitorStagingLive_TransID(TransID)
	, 	INDEX			IX_MatchMonitorStagingLive_Group(MatchID, TotalScore, BettypeID, GroupID)
    ,	INDEX			IX_MatchMonitorStagingLive_TransDate(TransDate)
) ENGINE=INNODB;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitorDetails;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorDetails(
		ID				BIGINT UNSIGNED AUTO_INCREMENT	
	,	MatchID			BIGINT UNSIGNED NOT NULL
    ,	LiveIndicator	BOOLEAN	NOT NULL 
    ,	TotalScore		SMALLINT UNSIGNED NOT NULL 
    , 	BettypeID		INT UNSIGNED NOT NULL    
    ,	GroupID			BIGINT UNSIGNED NOT NULL     
    , 	IsHedging		BOOLEAN NOT NULL 
    ,	ListCustID		LONGTEXT
    , 	ListTransID		LONGTEXT
    , 	EventDate		DATE NOT NULL
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
	, 	PRIMARY KEY		PK_MatchMonitorDetails_ID(ID)
	,	UNIQUE KEY		UK_MatchMonitorDetails_EventDateBettypeMatchID(MatchID,LiveIndicator,TotalScore,BettypeID,GroupID)
	, 	INDEX			IX_MatchMonitorDetails_GroupIDIsHedging(GroupID,IsHedging)
    ,	INDEX			IX_MatchMonitorDetails_MatchID_BettypeID(MatchID,BettypeID)
) ENGINE=INNODB;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitor;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitor (
		ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	, 	EventDate		DATE NOT NULL
	, 	BettypeID		INT UNSIGNED NOT NULL
    ,	MatchID			BIGINT UNSIGNED NOT NULL
    ,	LiveIndicator	BOOLEAN NOT NULL
    , 	IsHedging		BOOLEAN  NOT NULL    
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED    
    , 	IsVerified		BOOLEAN DEFAULT 0
	, 	VerifiedDate	DATETIME
    ,	VerifiedBy		INT UNSIGNED
    ,	UNIQUE INDEX	IX_MatchMonitor_EventDateBettypeMatchIDIsHedging(EventDate, BettypeID, MatchID, LiveIndicator, IsHedging)
	, 	INDEX			IX_MatchMonitor_IsVerified(IsVerified)
    ,	INDEX			IX_MatchMonitor_MatchID_BettypeID(MatchID,BettypeID)
) ENGINE=INNODB AUTO_INCREMENT=1;


#####################CTS_DataCenter.SportGroup

UPDATE CTS_DataCenter.SystemParameter
SET ParameterName = 'MatchMonitor_LastScannedLiveTransID', ParameterDesc = 'Match Monitor - Last Scanned Live TransID'
WHERE ParameterID = 20;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(29,'MatchMonitor_LastScannedNonliveTransID','Match Monitor - Last Scanned Nonlive TransID','BIGINT UNSIGNED','0');

#=================
*/
#SELECT *  FROM CTS_DataCenter.SystemParameter WHERE ParameterID IN (20,29);