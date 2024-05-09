/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20240509@Casey.Huynh
    Task:	 	HF Hedging Step Time
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20240509@Casey.Huynh: Created [Redmine ID: #204228]
    Reviewer: Long.Lưu
*/
USE CTS_DataCenter;
#============================
ALTER TABLE MatchMonitorStagingHedgingLive
ADD COLUMN TransDateToSecond BIGINT AFTER TransDate;

ALTER TABLE MatchMonitorStagingHedgingNonLive
ADD COLUMN TransDateToSecond BIGINT AFTER TransDate;