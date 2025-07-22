/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250722@Winfred.pham
Task:	 	Update MatchMonitor Saba Soccer
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250722@Winfred.pham: Update MatchMonitor Saba Soccer [Redmine ID: #229875]

Reviewer:
*/
UPDATE CTS_DataCenter.MatchMonitor AS mm 
SET mm.ClassifyStatus = 1 
WHERE mm.SportType = 1 AND mm.LeagueGroupID = 42 AND mm.KickOffTime < '2025-07-21 23:20:00';

