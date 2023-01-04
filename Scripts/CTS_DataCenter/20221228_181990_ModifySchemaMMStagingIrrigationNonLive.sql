/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20221228@Victoria.Le
    Task:	    CTSCustomer: Add columns Hdp, Hdp1, Hdp2 [Redmine ID: #181990]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.MatchMonitorStagingIrrigationNonLive 
ADD COLUMN Hdp 	DECIMAL(8,4) DEFAULT NULL;

ALTER TABLE CTS_DataCenter.MatchMonitorStagingIrrigationNonLive 
DROP INDEX IX_MatchMonitorStagingIrrigationNonLive_GroupID,
ADD INDEX IX_MatchMonitorStagingIrrigationNonLive_GroupID (MatchID,ScoreDiff,BettypeID,BetID,Betteam,Hdp,CustID)