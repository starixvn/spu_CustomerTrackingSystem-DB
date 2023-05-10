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

DROP TABLE IF EXISTS DCS_DataCenter.Flagged;

CREATE TABLE `Flagged` (
  `ID` INT UNSIGNED NOT NULL,
  `Code` VARCHAR(100) NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `Status` BOOLEAN NOT NULL DEFAULT 1,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`ID`),
  KEY `IX_Flagged_Code` (`Code`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.Flagged(ID, Code, Name, CreatedDate)
VALUES	(1, 'Human', 'Human', NOW())
	, 	(2, 'EmptyToken', 'EmptyToken', NOW())
	, 	(3, 'InvalidToken', 'InvalidToken', NOW())
	, 	(4, 'EmptyAnalysis', 'EmptyAnalysis', NOW())
	, 	(5, 'InvalidAnalysis', 'InvalidAnalysis', NOW())
	, 	(6, 'EmptyDevice', 'EmptyDevice', NOW())
	, 	(7, 'InvalidDevice', 'InvalidDevice', NOW())
	, 	(8, 'EmptyUserAgent', 'EmptyUserAgent', NOW())
	, 	(9, 'Headless', 'Headless', NOW())
	, 	(10, 'awesomium', 'Awesomium', NOW())
	, 	(11, 'cef', 'Cef', NOW())
	, 	(12, 'cefsharp', 'CefSharp', NOW())
	, 	(13, 'coachjs', 'CoachJS', NOW())
	, 	(14, 'electron', 'Electron', NOW())
	, 	(15, 'fminer', 'FMiner', NOW())
	, 	(16, 'geb', 'Geb', NOW())
	, 	(17, 'nightmarejs', 'NightmareJS', NOW())
	, 	(18, 'phantomas', 'Phantomas', NOW())
	, 	(19, 'phantomjs', 'PhantomJS', NOW())
	, 	(20, 'rhino', 'Rhino', NOW())
	, 	(21, 'selenium', 'Selenium', NOW())
	, 	(22, 'sequentum', 'Sequentum', NOW())
	, 	(23, 'slimerjs', 'SlimerJS', NOW())
	, 	(24, 'webdriverio', 'WebDriverIO', NOW())
	, 	(25, 'webdriver', 'WebDriver', NOW())
	, 	(26, 'headless_chrome', 'HeadlessChrome', NOW())
	, 	(27, 'unknown', 'Unknown', NOW())
;

DROP TABLE IF EXISTS DCS_DataCenter.BotDetection;

CREATE TABLE `BotDetection` (
  `Value` BIT(32) NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`Value`),
  KEY `IX_BotDetection_Name` (`Name`)
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
	,	(262144,'detectPlatform', NOW())
	,	(524288,'detectVmFromMemoryScreenDimensions', NOW())
;

DROP TABLE IF EXISTS DCS_DataCenter.BotComponent;

CREATE TABLE `BotComponent` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(100) NOT NULL,
  `Component` LONGTEXT NOT NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `IX_BotComponent_Code` (`Code`)
) ENGINE=InnoDB;

ALTER TABLE `DCS_DataCenter`.`RawTransaction` 
ADD COLUMN `BotDetectionValue` BIT(32) NULL,
ADD COLUMN `BotComponentID` BIGINT UNSIGNED NULL;

ALTER TABLE `DCS_DataCenter`.`Transaction` 
ADD COLUMN `BotDetectionValue` BIT(32) NULL,
ADD COLUMN `BotComponentID` BIGINT UNSIGNED NULL;

ALTER TABLE `DCS_DataCenter`.`ProcessedTransaction` 
ADD COLUMN `BotDetectionValue` BIT(32) NULL,
ADD COLUMN `BotComponentID` BIGINT UNSIGNED NULL;

ALTER TABLE `DCS_DataCenter`.`Transaction07` 
ADD COLUMN `BotDetectionValue` BIT(32) NULL,
ADD COLUMN `BotComponentID` BIGINT UNSIGNED NULL;