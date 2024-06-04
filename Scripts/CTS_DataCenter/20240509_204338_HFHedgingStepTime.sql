/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20240509@Casey.Huynh
    Task:	 	HF Hedging Step Time
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20240509@Casey.Huynh: Created [Redmine ID: #204338]
    Reviewer: Long.Lưu
*/
USE CTS_DataCenter;
#============================
ALTER TABLE MatchMonitorStagingHedgingLive
ADD COLUMN TransDateToSecond BIGINT AFTER TransDate
, ADD INDEX IX_MatchMonitorStagingHedgingLive_TransDateToSecond(TransDateToSecond)
, DROP INDEX IX_MatchMonitorStagingHedgingLive_TransDate;

ALTER TABLE MatchMonitorStagingHedgingNonLive
ADD COLUMN TransDateToSecond BIGINT AFTER TransDate
, ADD INDEX IX_MatchMonitorStagingHedgingNonLive_TransDateToSecond(TransDateToSecond)
, DROP INDEX IX_MatchMonitorStagingHedgingNonLive_TransDate;