/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20240221@Jonathan.Doan
	Task:	 	Add more columns into FPSClientTransaction_Exception [Redmine ID: #200900]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20240221@Jonathan.Doan: Created [Redmine ID: #200900]
	Reviewer:
*/
USE DCS_DataTrace;

DROP TABLE IF EXISTS FPSScriptException;

CREATE TABLE `FPSScriptException` (
  `ID` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `ScriptVersion` VARCHAR(20) DEFAULT NULL,
  `FunctionName` VARCHAR(100) DEFAULT NULL,
  `Exception` VARCHAR(1000) DEFAULT NULL,
  `UserAgent` VARCHAR(500) DEFAULT NULL,
  `ApiUrl` VARCHAR(250) DEFAULT NULL,
  `HostName` VARCHAR(250) DEFAULT NULL,
  `SessionKey` VARCHAR(200) DEFAULT NULL,
  `OldCookie` VARCHAR(100) DEFAULT NULL,
  `NewCookie` VARCHAR(100) DEFAULT NULL,
  `RealIP` VARCHAR(50) DEFAULT NULL,
  `FakeIP` VARCHAR(50) DEFAULT NULL,
  `CreatedDate` DATE DEFAULT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NULL,
  
  KEY `IX_FPSScriptException_CreatedDate_FunctionName` (`CreatedDate`,`FunctionName`),
  KEY `IX_FPSScriptException_ScriptVersion` (`ScriptVersion`)
) ENGINE=InnoDB;
