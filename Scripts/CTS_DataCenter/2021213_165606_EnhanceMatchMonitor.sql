/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211213@Casey.Huynh
Task:	 	Enhance MatchMonitor
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211213@Casey.Huynh: Created [Redmine ID: #165606]
Reviewer:
*/
USE CTS_DataCenter;
/*===1. ALTER Tables===========*/
ALTER TABLE MatchMonitorStagingLive
	ADD COLUMN LeagueName VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE MatchMonitorStagingNonLive
	ADD COLUMN LeagueName VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE MatchMonitor
	ADD COLUMN LeagueName VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,	DROP COLUMN VerifiedDate
,	DROP COLUMN VerifiedBy
,	DROP COLUMN IsVerified;

/*===2. CREATE Table===========*/
CREATE TABLE MatchMonitorDetailsVerifiedTrans (
		ID				BIGINT	UNSIGNED AUTO_INCREMENT
	,	MatchID 		BIGINT UNSIGNED
	,	LiveIndicator	TINYINT
	,	BettypeID		INT UNSIGNED
	,	ListTransID		LONGTEXT
	,	VerifiedDate	DATETIME
	,	VerifiedBy		INT
    
    ,	PRIMARY KEY PK_MatchMonitorDetailsVerifiedTrans_ID(ID)
    ,	INDEX IX_MatchMonitorDetailsVerifiedTrans(MatchID,LiveIndicator,BettypeID)
    );
