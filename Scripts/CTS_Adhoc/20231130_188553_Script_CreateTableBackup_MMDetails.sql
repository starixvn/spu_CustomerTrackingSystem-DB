/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231130@Victoria.Le
Task:	 	Create New Table Backup
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231130@Victoria.Le: Initial Writing [Redmine ID: #188553]

*/

USE CTS_DataCenter;

CREATE TABLE MatchMonitorDetails_20231129_bk (
		ID 							BIGINT
	,	MatchID 					INT
	,	IsMajorLeague 				TINYINT(1)
	,	LiveIndicator 				TINYINT(1)
	,	BettypeID 					INT
	,	HDP 						DECIMAL(8,4) 
	,	GroupID 					INT
	,	Reason 						TINYINT
	,	ListCustID 					LONGTEXT
	,	ListTransID 				LONGTEXT
	,	EventDate 					DATE 
	,	LiveHomeScore 				INT
	,	LiveAwayScore 				INT
	,	BetID 						BIGINT
	,	ClassifyStatus 				TINYINT 
	,	Betteam 					VARCHAR(10)
	,	HighStakeLicCustList 		LONGTEXT
	,	InsertTime 					DATETIME(3) 
	,	ScoreDiff 					INT 
	,	PRIMARY KEY (ID,EventDate)
);