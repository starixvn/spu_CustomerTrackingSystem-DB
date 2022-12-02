/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20221115@Casey.Huynh
Task:	 	Match Monitor Irrigation
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202211213@Casey.Huynh: Created [Redmine ID: #179499]
Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE MatchMonitorStagingIrrigationNonLive (
  SequenceID BIGINT unsigned NOT NULL,
  TransID BIGINT unsigned NOT NULL,
  TransDate DateTIME(3) DEFAULT NULL,
  MatchID INT DEFAULT NULL,
  SportType INT DEFAULT NULL,
  ScoreDiff INT DEFAULT NULL,
  BettypeID INT DEFAULT NULL,
  BetID BIGINT DEFAULT NULL,
  Betteam VARCHAR(10) DEFAULT NULL,
  CustID BIGINT unsigned DEFAULT NULL,
  Stake DECIMAL(20,4) DEFAULT NULL,
  Odds	DECIMAL(10,4) DEFAULT NULL,
  GroupID INT DEFAULT '0',
  LiveHomeScore INT DEFAULT NULL,
  LiveAwayScore INT DEFAULT NULL,
  EventDate Date DEFAULT NULL,
  KickOffTime DateTIME DEFAULT NULL,
  EventStatus VARCHAR(50) DEFAULT NULL,
  HomeID INT DEFAULT NULL,
  AwayID INT DEFAULT NULL,
  LeagueID INT DEFAULT NULL,
  InsertTime DateTIME(3) DEFAULT NULL,
  LeagueName VARCHAR(500) DEFAULT NULL,
  PRIMARY KEY (SequenceID),
  INDEX IX_MatchMonitorStagingIrrigationNonLive_GroupID (MatchID,ScoreDiff,BettypeID,BetID,CustID)
  , INDEX IX_MatchMonitorStagingIrrigationNonLive_TransID(TransID)
) ENGINE=InnoDB;

ALTER TABLE MatchMonitorRuleSetting
ADD COLUMN OddsSpread DECIMAL(4,2) AFTER HighStake;

INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, SportType, ReasonName, SportName, TimeStep, TotalStake, HighStake, OddsSpread, ModifiedDate, Comments)
VALUES (4, 'Irrigation Detect', 58 , 1, 'Irrigation', 'Soccer', 180, 1000, NULL, 28, CURRENT_TIMESTAMP(), NULL);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(124,'MatchMonitorIrrigation_Rule_BatchSize','MatchMonitorIrrigation_Rule_BatchSize','INT','5000')
	,	(125,'MatchMonitorIrrigation_RuleNonLive_LastSequenceID','MatchMonitorIrrigation_RuleNonLive_LastSequenceID','BIGINT UNSIGNED','0');
    
ALTER TABLE MatchMonitorDetails
	ADD COLUMN ScoreDiff INT
, 	ADD UNIQUE KEY `UK_MatchMonitorDetails_RuleGroup` (`MatchID`,`LiveIndicator`,`ScoreDiff`,`BettypeID`,`BetID`,`Betteam`,`GroupID`,`EventDate`);
