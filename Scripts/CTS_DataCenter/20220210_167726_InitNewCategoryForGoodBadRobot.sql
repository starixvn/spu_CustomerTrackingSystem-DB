/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220210@Long.Luu
Task:	 	Rearrange Schema & Init new categories for Good/Bad robot and CategoryToDangerLevel
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220210@Long.Luu: Created [Redmine ID: #167726]
Reviewer:
*/

/* Schema */
DROP TABLE CTS_DataCenter.RobotClassification;
CREATE TABLE `RobotClassification` (
  `ID` bigint NOT NULL AUTO_INCREMENT,
  `CustID` bigint unsigned NOT NULL,
  `FromDate` date NOT NULL,
  `ToDate` date DEFAULT NULL,
  `RobotType` tinyint unsigned DEFAULT NULL,
  `Turnover` decimal(20,4) DEFAULT NULL,
  `Winloss` decimal(20,4) DEFAULT NULL,
  `BetCount` int DEFAULT NULL,
  `ActiveDays` tinyint unsigned DEFAULT NULL,
  PRIMARY KEY (`ID`),  
  KEY `IX_RobotClassification_CustIDFromDate` (`CustID`,`FromDate`),
  KEY `IX_RobotClassification_FromDateToDate` (`FromDate`)
) ENGINE=InnoDB;

/* Init data */
INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,CategoryNameCN,CategoryGroup,ReasonID,SourceType,ScanIntervalInSecond) 
VALUES 	(163,'Bad Robot User','Bad Robot User',50,163,1,NOW(),0,'非正常机械玩家',61,163,'AI',0),
		(164,'Good Robot User','Good Robot User',50,164,1,NOW(),0,'正常机械玩家',61,164,'AI',0);

INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (163,0,2,31),(163,1,2,31),(164,0,2,32),(164,1,2,32);

INSERT INTO CTS_DataCenter.CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (163,13),(164,13);