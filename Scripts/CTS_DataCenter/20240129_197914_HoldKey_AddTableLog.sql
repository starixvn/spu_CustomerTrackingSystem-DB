/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240102@Jonas.Huynh
	Task:	 	Enhance Monitoring Job
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20240102@Jonas.Huynh: Create Schema [Redmine ID: #197999]
*/

CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorHoldKey_ActionLog (
		ID				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
    ,	UserID			INT UNSIGNED NOT NULL
    , 	Status			BOOLEAN
	, 	CreatedDate		DATETIME NOT NULL DEFAULT (CURRENT_DATETIME)
	, 	INDEX			IX_MatchMonitorHoldKey_ActionLog_CreatedDate(CreatedDate)
) ENGINE=INNODB; 

INSERT INTO SPU_Stats.Function(FunctionId,FunctionName,SystemId) VALUES(80,'MatchMonitorDetailHoldKeyUpdate',1);							
INSERT INTO SPU_Stats.Function(FunctionId,FunctionName,SystemId) VALUES(85,'MatchMonitorDetailTicketVoiding',1);							