/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20221107@Casey.Huynh
	Task: Update Data IsTransformed = 0 for Account Not Transform
	DB: CTS_DataCenter
  
	Revisions:
		- 20221107@Casey.Huynh: created  [Redmine ID: #180182]

	Param's Explanation:
*/


USE CTS_Log; 

CREATE TABLE CTSLog (
  ID int NOT NULL AUTO_INCREMENT,
  LogName VARCHAR(150),
  InsertTime DATETIME(4),
  OtherText TEXT,
  JsonString1 json DEFAULT NULL,
  JsonString2 json DEFAULT NULL,
  PRIMARY KEY (Id),
  INDEX IX_CTSLog_LogName(LogName)
) ENGINE=InnoDB;
