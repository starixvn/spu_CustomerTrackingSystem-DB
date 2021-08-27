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

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitorStagingLive;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorStagingLive(
		TransID			BIGINT UNSIGNED
	, 	TransDate		DATETIME(3)
    ,	MatchID			BIGINT UNSIGNED
    ,	LiveIndicator	BOOLEAN
    ,	BettypeID		INT UNSIGNED
    , 	EventDate		DATE
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED    
	, 	CustID			BIGINT UNSIGNED
    ,	Stake			DECIMAL(20,4)
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    ,	TotalScore		SMALLINT UNSIGNED
    ,	GroupID			BIGINT UNSIGNED
    ,	OriginGroupID	BIGINT UNSIGNED
    ,	InsertTime		DATETIME(3)
	, 	PRIMARY KEY		PK_MatchMonitorStaging_TransID(TransID)
	, 	INDEX			IX_MatchMonitorStaging_OriginGroupIDMatchInfo(OriginGroupID,MatchID,LiveIndicator,TotalScore,BettypeID)
    , 	INDEX			IX_MatchMonitorStaging_CustID(CustID)
    ,	INDEX			IX_MatchMonitorStaging_GroupID(GroupID)
) ENGINE=INNODB;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitorStagingNonLive;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorStagingNonLive(
		TransID			BIGINT UNSIGNED
	, 	TransDate		DATETIME(3)
    ,	MatchID			BIGINT UNSIGNED
    ,	LiveIndicator	BOOLEAN
    ,	BettypeID		INT UNSIGNED
    , 	EventDate		DATE
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED    
	, 	CustID			BIGINT UNSIGNED
    ,	Stake			DECIMAL(20,4)
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    ,	TotalScore		SMALLINT UNSIGNED
    ,	GroupID			BIGINT UNSIGNED
    ,	OriginGroupID	BIGINT UNSIGNED
    ,	InsertTime		DATETIME(3)
	, 	PRIMARY KEY		PK_MatchMonitorStaging_TransID(TransID)
	, 	INDEX			IX_MatchMonitorStaging_OriginGroupIDMatchInfo(OriginGroupID,MatchID,LiveIndicator,TotalScore,BettypeID)
    , 	INDEX			IX_MatchMonitorStaging_CustID(CustID)
    ,	INDEX			IX_MatchMonitorStaging_GroupID(GroupID)
) ENGINE=INNODB;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitorDetails;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorDetails(
		ID				BIGINT UNSIGNED AUTO_INCREMENT
	,	MatchID			BIGINT UNSIGNED
    ,	LiveIndicator	BIT
	, 	BettypeID		INT UNSIGNED
    , 	EventDate		DATE
    ,	GroupID			BIGINT UNSIGNED
    ,	TotalScore		SMALLINT UNSIGNED
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    ,	ListCustID		LONGTEXT
    , 	ListTransID		LONGTEXT   
    , 	IsHedging		BIT DEFAULT 0
    ,	LastModifiedTime DATETIME(3)	
	, 	PRIMARY KEY		PK_MatchMonitorDetails_ID(ID)
	,	INDEX			IX_MatchMonitorDetails_EventDateBettypeMatchID(EventDate,BettypeID,MatchID,LiveIndicator)
	, 	INDEX			IX_MatchMonitorDetails_GroupIDIsHedging(GroupID,IsHedging)
    ,	INDEX			IX_MatchMonitorDetails_MatchID_BettypeID(MatchID,BettypeID)
) ENGINE=INNODB;

DROP TABLE IF EXISTS CTS_DataCenter.MatchMonitor;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitor (
		ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    ,	MatchID			BIGINT UNSIGNED
	, 	BettypeID		INT UNSIGNED
    ,	LiveIndicator	BOOLEAN
    , 	EventDate		DATE
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED
    , 	IsHedging		BIT DEFAULT 0
    , 	IsVerified		BIT DEFAULT 0
	, 	VerifiedDate	DATETIME
    ,	VerifiedBy		INT UNSIGNED
    ,	LastModifiedTime DATETIME(3)	
    ,	UNIQUE INDEX	IX_MatchMonitor_EventDateBettypeMatchIDIsHedging(EventDate,BettypeID,MatchID,IsHedging)
	, 	INDEX			IX_MatchMonitor_IsVerified(IsVerified)
    ,	INDEX			IX_MatchMonitor_MatchID_BettypeID(MatchID,BettypeID)
) ENGINE=INNODB AUTO_INCREMENT=1;

#####################CTS_DataCenter.SportGroup
UPDATE CTS_DataCenter.SystemParameter
SET ParameterName = 'MatchMonitor_LastScannedLiveTransID', ParameterDesc = 'Match Monitor - Last Scanned Live TransID'
WHERE ParameterID = 20;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(29,'MatchMonitor_LastScannedNonliveTransID','Match Monitor - Last Scanned Nonlive TransID','BIGINT UNSIGNED','0');


