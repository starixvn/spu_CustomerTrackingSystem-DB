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
DROP TABLE IF EXISTS DCS_DataCenter.StaticList;

CREATE TABLE `StaticList` (
  `ListID` int NOT NULL,
  `ItemID` smallint NOT NULL,
  `ListCode` varchar(100) DEFAULT NULL,
  `ListName` varchar(200) DEFAULT NULL,
  `ItemCode` varchar(100) DEFAULT NULL,
  `ItemName` varchar(200) DEFAULT NULL,
  `Status` tinyint(1) DEFAULT NULL,
  `Description` varchar(200) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`ListID`,`ItemID`),
  UNIQUE KEY `UX_StaticList_ListCode_ItemCode` (`ListCode`, `ItemCode`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.StaticList(ListID, ListCode, ListName, ItemID, ItemCode, ItemName, Status, CreatedDate) VALUES
(1,'Flagged','Flagged', 1, 'Human', 'Human', 1, NOW())
, (1,'Flagged','Flagged', 2, 'EmptyToken', 'EmptyToken', 1, NOW())
, (1,'Flagged','Flagged', 3, 'InvalidToken', 'InvalidToken', 1, NOW())
, (1,'Flagged','Flagged', 4, 'EmptyAnalysis', 'EmptyAnalysis', 1, NOW())
, (1,'Flagged','Flagged', 5, 'InvalidAnalysis', 'InvalidAnalysis', 1, NOW())
, (1,'Flagged','Flagged', 6, 'EmptyDevice', 'EmptyDevice', 1, NOW())
, (1,'Flagged','Flagged', 7, 'InvalidDevice', 'InvalidDevice', 1, NOW())
, (1,'Flagged','Flagged', 8, 'EmptyUserAgent', 'EmptyUserAgent', 1, NOW())
, (1,'Flagged','Flagged', 9, 'Headless', 'Headless', 1, NOW())
, (1,'Flagged','Flagged', 10, 'awesomium', 'Awesomium', 1, NOW())
, (1,'Flagged','Flagged', 11, 'cef', 'Cef', 1, NOW())
, (1,'Flagged','Flagged', 12, 'cefsharp', 'CefSharp', 1, NOW())
, (1,'Flagged','Flagged', 13, 'coachjs', 'CoachJS', 1, NOW())
, (1,'Flagged','Flagged', 14, 'electron', 'Electron', 1, NOW())
, (1,'Flagged','Flagged', 15, 'fminer', 'FMiner', 1, NOW())
, (1,'Flagged','Flagged', 16, 'geb', 'Geb', 1, NOW())
, (1,'Flagged','Flagged', 17, 'nightmarejs', 'NightmareJS', 1, NOW())
, (1,'Flagged','Flagged', 18, 'phantomas', 'Phantomas', 1, NOW())
, (1,'Flagged','Flagged', 19, 'phantomjs', 'PhantomJS', 1, NOW())
, (1,'Flagged','Flagged', 20, 'rhino', 'Rhino', 1, NOW())
, (1,'Flagged','Flagged', 21, 'selenium', 'Selenium', 1, NOW())
, (1,'Flagged','Flagged', 22, 'sequentum', 'Sequentum', 1, NOW())
, (1,'Flagged','Flagged', 23, 'slimerjs', 'SlimerJS', 1, NOW())
, (1,'Flagged','Flagged', 24, 'webdriverio', 'WebDriverIO', 1, NOW())
, (1,'Flagged','Flagged', 25, 'webdriver', 'WebDriver', 1, NOW())
, (1,'Flagged','Flagged', 26, 'headless_chrome', 'HeadlessChrome', 1, NOW())
, (1,'Flagged','Flagged', 27, 'unknown', 'Unknown', 1, NOW());


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
  UNIQUE KEY `UX_BotComponent_Code` (`Code`)
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