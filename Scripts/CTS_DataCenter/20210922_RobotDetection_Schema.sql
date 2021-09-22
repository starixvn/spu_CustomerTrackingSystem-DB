/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210922@Long.Luu
Task:	 	Schema for Robot Detection
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	-	[20210701@Long.Luu][0000]: Schema for Robot Classification
Reviewer:
*/

CREATE TABLE `RobotDetection` (
  `CustID` bigint unsigned NOT NULL,
  `PeriodRangeType` smallint unsigned DEFAULT NULL,
  `LatestPeriodRangeType` smallint unsigned DEFAULT NULL,
  `CreatedDate` date DEFAULT NULL,
  `LastModifiedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`CustID`),
  KEY `IX_RobotDetection_CreatedDate` (`CreatedDate`)
) ENGINE=InnoDB;


/*
INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (13,0,'Robot Classification','Robot Classification Type','Observed Robot','Observed Robot',1,1,'Observed - Unknown Robot',NOW());
INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (13,1,'Robot Classification','Robot Classification Type','Good Robot','Good Robot',1,1,'Good - Losing Robot',NOW());
INSERT INTO CTS_DataCenter.StaticList(ListID, ItemID, ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (13,2,'Robot Classification','Robot Classification Type','Bad Robot','Bad Robot',1,1,'Bad - Winning Robot',NOW());
*/

