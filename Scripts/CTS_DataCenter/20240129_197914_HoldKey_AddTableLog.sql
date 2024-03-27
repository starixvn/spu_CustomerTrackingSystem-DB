/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240102@Jonas.Huynh
	Task:	 	MM Detail - Hold Key
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20240102@Jonas.Huynh: Create Schema [Redmine ID: #197999]
*/

CREATE TABLE IF NOT EXISTS CTS_DataCenter.MatchMonitorHoldKey_ActionLog (
		ID				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
    ,	UserID			INT UNSIGNED NOT NULL
    ,	MatchID			INT NOT NULL
    , 	Status			BOOLEAN
	, 	CreatedDate		DATETIME NOT NULL DEFAULT (NOW())
	, 	INDEX			IX_MatchMonitorHoldKey_ActionLog_MatchID(MatchID)
) ENGINE=INNODB; 

INSERT INTO SPU_Stats.Function(FunctionId,FunctionName,SystemId) VALUES(80,'MatchMonitorDetailHoldKeyUpdate',1);							
INSERT INTO SPU_Stats.Function(FunctionId,FunctionName,SystemId) VALUES(85,'MatchMonitorDetailTicketVoiding',1);							