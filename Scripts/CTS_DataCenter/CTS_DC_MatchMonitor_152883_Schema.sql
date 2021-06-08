/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20210525@Long.Luu
Task:	 	Match Monitoring
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20210525@Long.Luu: Created [#152883]
Reviewer:
*/
DROP TABLE CTS_DataCenter.MatchMonitor;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitor (
		ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    ,	MatchID			BIGINT UNSIGNED
	, 	BettypeID		INT UNSIGNED
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
    ,	UNIQUE INDEX	IX_MatchMonitor_EventDateBettypeMatchID(EventDate,BettypeID,MatchID)
	, 	INDEX			IX_MatchMonitor_IsVerified(IsVerified)
) ENGINE=INNODB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorDetails (
		MatchID			BIGINT UNSIGNED
	, 	BettypeID		INT UNSIGNED
    , 	EventDate		DATE
    ,	LiveIndicator	BIT
    ,	GroupID			BIGINT UNSIGNED
    ,	TotalScore		SMALLINT UNSIGNED
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    ,	ListCustID		VARCHAR(2000)
    , 	ListTransID		VARCHAR(2000)   
    , 	IsHedging		BIT DEFAULT 0
	, 	PRIMARY KEY		PK_MatchMonitorDetails_EventDateBettypeMatchID(EventDate,BettypeID,MatchID,LiveIndicator)
	, 	INDEX			IX_MatchMonitorDetails_GroupIDIsHedging(GroupID,IsHedging)
) ENGINE=INNODB;

DROP TABLE CTS_DataCenter.MatchMonitorStaging;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorStaging (
		TransID			BIGINT UNSIGNED
	, 	TransDate		DATETIME(3)
    ,	MatchID			BIGINT UNSIGNED
    , 	EventDate		DATE
    , 	KickOffTime		DATETIME
    ,	EventStatus		VARCHAR(50)
    ,	HomeID			INT UNSIGNED
	, 	AwayID			INT UNSIGNED
    ,	LeagueID		INT UNSIGNED
    ,	BettypeID		INT UNSIGNED
    ,	LiveIndicator	BIT
	, 	CustID			BIGINT UNSIGNED
    ,	Stake			DECIMAL(20,4)
    ,	LiveHomeScore	SMALLINT UNSIGNED
    ,	LiveAwayScore	SMALLINT UNSIGNED
    ,	TotalScore		SMALLINT UNSIGNED
    ,	GroupID			BIGINT UNSIGNED
    ,	OriginGroupID	BIGINT UNSIGNED
	, 	PRIMARY KEY		PK_MatchMonitorStaging_TransIDMatchIDBettypeID(TransID)
	, 	INDEX			IX_MatchMonitorStaging_GroupID(GroupID)
    , 	INDEX			IX_MatchMonitorStaging_OriginGroupID(OriginGroupID)
) ENGINE=INNODB;

