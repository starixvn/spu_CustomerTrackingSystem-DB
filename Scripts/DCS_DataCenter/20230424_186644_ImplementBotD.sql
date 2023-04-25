/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230424@Jonathan.Doan
	Task:	 	Implement BotD [Redmine ID: #186644]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20230424@Jonathan.Doan: Created [Redmine ID: #186644]
	Reviewer:
*/
USE DCS_DataCenter;

DROP TABLE IF EXISTS DCS_DataCenter.BotKind;

CREATE TABLE `BotKind` (
  `ID` INT UNSIGNED NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.BotKind(ID, Name, CreatedDate)
VALUES	(2, 'awesomium', NOW())
	,	(3, 'cef', NOW())
	,	(4, 'cefsharp', NOW())
	,	(5, 'coachjs', NOW())
	,	(6, 'electron', NOW())
	,	(7, 'fminer', NOW())
	,	(8, 'geb', NOW())
	,	(9, 'nightmarejs', NOW())
	,	(10, 'phantomas', NOW())
	,	(11, 'phantomjs', NOW())
	,	(12, 'rhino', NOW())
	,	(13, 'selenium', NOW())
	,	(14, 'sequentum', NOW())
	,	(15, 'slimerjs', NOW())
	,	(16, 'webdriverio', NOW())
	,	(17, 'webdriver', NOW())
	,	(18, 'headless_chrome', NOW())
	,	(19, 'unknown', NOW())
;


DROP TABLE IF EXISTS DCS_DataCenter.BotDetection;

CREATE TABLE `BotDetection` (
  `Value` BIT(20) NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`Value`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.BotDetection(Value, Name, CreatedDate)
VALUES 	(1,'detectAppVersion', NOW())
	,	(2,'detectDocumentAttributes', NOW())
	,	(4,'detectErrorTrace', NOW())
	,	(8,'detectEvalLengthInconsistency', NOW())
	,	(16,'detectFunctionBind', NOW())
	,	(32,'detectLanguagesLengthInconsistency', NOW())
	,	(64,'detectNotificationPermissions', NOW())
	,	(128,'detectPluginsArray', NOW())
	,	(256,'detectPluginsLengthInconsistency', NOW())
	,	(512,'detectProcess', NOW())
	,	(1024,'detectUserAgent', NOW())
	,	(2048,'detectWebDriver', NOW())
	,	(4096,'detectWebGL', NOW())
	,	(8192,'detectWindowExternal', NOW())
	,	(16384,'detectWindowSize', NOW())
	,	(32768,'detectMimeTypesConsistent', NOW())
	,	(65536,'detectProductSub', NOW())
	,	(131072,'detectDistinctiveProperties', NOW())
;

ALTER TABLE `DCS_DataCenter`.`RawTransaction` 
ADD COLUMN `Value` BIT(20) NULL;