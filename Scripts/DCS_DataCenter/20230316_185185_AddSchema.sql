/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20230316@Jonathan.Doan
Task:	 	Support return new device login for Alpha
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230316@Jonathan.Doan: Created [#185185]
Reviewer:
*/

CREATE TABLE IF NOT EXISTS DCS_DataCenter.AbnormalTransasction(
		ID					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransID				BIGINT UNSIGNED NOT NULL
	, 	AccountID			BIGINT UNSIGNED NOT NULL
	, 	LoginName			VARCHAR(100) NOT NULL
	, 	TransTime			DATETIME(4) NOT NULL
	, 	UserAgentKey		VARCHAR(32) NOT NULL
	, 	IP					VARCHAR(50) NOT NULL
	,	Status 				TINYINT COMMENT '0: Not Send\n1: Sended'
	, 	CreatedDate			DATETIME
	,	PRIMARY KEY (`Id`)
	,	UNIQUE KEY `UX_AbnormalTransasction_TransID` (`TransID`)
) ENGINE=InnoDB;


INSERT INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction_Transform', 'MaxTransID', '0', NOW());

INSERT INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction_Processed', 'MaxID', '0', NOW());