/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
Creator: 	20240707@Victoria.Le
Task:	 	Match Monitoring Staging GB Live
Server:  	Master
DBName:		CTS_Adhoc

Revisions: 
		- 20240707@Victoria.Le: Initial Writing [#000000]
Reviewer:
*/

USE CTS_DataCenter;

SELECT COUNT(1) FROM MatchMonitorStagingGroupBettingLive AS mms;

DELETE mms
FROM MatchMonitorStagingGroupBettingLive AS mms
WHERE mms.MatchID in (87926549,88328859,88328860,88328861,88330018,88330056,88446059,88447340,88462549,88462550,88468181,88586221,88586222)
;

SELECT COUNT(1) FROM MatchMonitorStagingGroupBettingLive AS mms;
