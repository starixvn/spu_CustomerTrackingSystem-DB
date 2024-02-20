/*<info serverAlias="CTSMain-CTS_Log" databaseType="2"></info>*/
/*
	Creator:	20240220@Jonathan.Doan
	Task:	 	Add more columns into FPSClientTransaction_Exception [Redmine ID: #200900]
	Server:  	Master
	DBName:		CTS_Log
    
	Revisions: 
			- 20240220@Jonathan.Doan: Created [Redmine ID: #200900]
	Reviewer:
*/
USE CTS_Log;

DROP TABLE IF EXISTS FPSClientTransaction_Exception;

CREATE TABLE `FPSClientTransaction_Exception` (
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
  `CreatedDate` DATE DEFAULT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NULL,
  
  KEY `IX_FPSClientTransaction_Exception_CreatedDate_FunctionName` (`CreatedDate`,`FunctionName`),
  KEY `IX_FPSClientTransaction_Exception_ScriptVersion` (`ScriptVersion`)
) ENGINE=InnoDB;
