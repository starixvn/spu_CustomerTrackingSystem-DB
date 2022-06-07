/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220520@Casey.Huynh
    Task:	 	20220520@Casey.Huynh: Missing ArchiveCust  [Redmine ID: #172561]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

CREATE TABLE `CTSCustomerClassificationOldPA` (
  `CustID` bigint unsigned NOT NULL,
  `CTSCustID` bigint unsigned DEFAULT NULL,
  `SubscriberID` int unsigned DEFAULT NULL,
  `SportGroupID` smallint unsigned NOT NULL,
  `CategoryID` smallint unsigned NOT NULL,
  `Remark` varchar(500),
  `CreatedDate` datetime DEFAULT NULL,
  `CreatedBy` int DEFAULT NULL,
  `LastModifiedDate` datetime DEFAULT NULL,
  `LastModifiedBy` int unsigned DEFAULT NULL,
  `LastScannedDate` date DEFAULT NULL,
  `IsFromTVS` BOOLEAN DEFAULT 0,
  `IsFromTW` BOOLEAN DEFAULT  0,
  `IsFromCTS` BOOLEAN DEFAULT  0,
  `IsDirect` BOOLEAN DEFAULT NULL,
  `InsertTime` DATETIME(3) DEFAULT NULL,
  `TVSRequestID` BIGINT UNSIGNED DEFAULT NULL,
  `IsFromAI` BOOLEAN DEFAULT  0,
  PRIMARY KEY (`CustID`,`SportGroupID`,`CategoryID`),
  KEY `IX_CTSCustomerClassification_TVSRequestID` (`TVSRequestID`)
) ENGINE=InnoDB;

CREATE TABLE `CTSCustomerClassificationQueue` (
   `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `CTSCustID` bigint unsigned DEFAULT NULL,
   `CustID` int unsigned DEFAULT NULL,
   `RoleID` tinyint DEFAULT NULL,
   `SubscriberID` int unsigned DEFAULT NULL,
   `CreatedBy` int unsigned DEFAULT NULL,
   `Remark` varchar(300) COLLATE utf8_unicode_ci DEFAULT NULL,
   `CategoryGroup` int DEFAULT NULL,
   `CategoryID` smallint unsigned DEFAULT NULL,
   `LastDownlineCTSCustID` bigint unsigned DEFAULT NULL,
   `ActionType` tinyint DEFAULT NULL COMMENT '1: INSERT VVIP, 2:Remove VVIP, 3:INSERT PA, 4: UNMARK PA',
   `InsertTime` datetime(3) DEFAULT NULL,
   `IsExceptDirectDownline` tinyint(1) DEFAULT '0',
   `IsFromTVS` tinyint(1) DEFAULT '0',
   `IsFromTW` tinyint(1) DEFAULT '0',
   `IsFromCTS` tinyint(1) DEFAULT '0',
   `TVSRequestID` BIGINT UNSIGNED DEFAULT NULL,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB;


SELECT * FROM CTS_Admin.LogType WHERE ListID = 4 ORDER BY ItemID DESC;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (4,31,'Classification Source Type','Classification Source Type','Problem Account is marked directly','Problem Account is marked directly',31,1,'Problem Account is marked directly',NOW())
	, (4,32,'Classification Source Type','Classification Source Type','Problem Account is affected by Uplines','Problem Account is affected by Uplines',32,1,'Problem Account is affected by Uplines',NOW())
    , (4,33,'Classification Source Type','Classification Source Type','Problem Account is unmarked directly','Problem Account is unmarked directly',33,1,'Problem Account is unmarked directly',NOW())
    , (4,34,'Classification Source Type','Classification Source Type','Unmarking Problem Account is affected by Uplines','Unmarking Problem Account is affected by Uplines',34,1,'Unmarking Problem Account is affected by Uplines',NOW());
	
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup,ReasonID,SourceType,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,ABIDangerLevel_Licensee,ABIDangerLevel_Credit,IsPAProbation,ProblemCaseID,RootTaggingID)
VALUES (63,'Robot User','AI Robot Betting',50,61,1,0,NOW(),'机械用户',61,61,'AI',13,'Robot','機械',13,16,6,0,1,13);
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup,ReasonID,SourceType,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,ABIDangerLevel_Licensee,ABIDangerLevel_Credit,IsPAProbation,ProblemCaseID,RootTaggingID)
VALUES (165,'Bad Robot User','AI Bad Robot Betting',50,165,1,0,NOW(),'非正常机械玩家',61,165,'AI',131,'Robot','機械',132,31,31,0,1,13);
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup,ReasonID,SourceType,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit,IsPAProbation,ProblemCaseID,RootTaggingID)
VALUES (166,'Good Robot User','AI Good Robot Betting',50,166,1,0,NOW(),'正常机械玩家',61,166,'AI',132,'Robot','機械',13,32,16,32,6,0,1,13);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES (94,'RobotBettingService_LastScannedTime','RobotBettingService_LastScannedTime','DATETIME','2022-09-22 08:00:00.000');	


/*********************************************************/
USE CTS_Admin;
INSERT INTO LogType(LogTypeID, LogTypeName, LogTypeDescription)
VALUES	(32,'Mark Problem Acccount','Mark Problem Acccount')
	,	(33,'Unmark Problem Acccount','Unmark Problem Acccount');