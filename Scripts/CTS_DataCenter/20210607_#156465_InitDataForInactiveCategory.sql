/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210607@Long.Luu
Task:	 	Init data for Inactive Categories [Redmine ID: #156465]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT IGNORE INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(1001, 'Normal Member Inactive', 'Normal Member Inactive', 200, 99, 1, NOW(), 0, 0, '不活跃正常会员', 1000)
,(1002, 'Pro Punter Inactive', 'Pro Punter Inactive', 200, 99, 1, NOW(), 0, 0, '不活跃精明玩家', 1000);

INSERT IGNORE INTO CTS_DataCenter.CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (1001,1001),(1002,1002);

INSERT IGNORE INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,Status,Description,CreatedDate)
VALUES	(4,18,'Classification Source Type','Classification Source Type','Inactive account (Normal)','Inactive account',1,'Inactive account (Normal)',NOW())
	,	(4,19,'Classification Source Type','Classification Source Type','Inactive account (Pro Punter)','Inactive account',1,'Inactive account (Pro Punter)',NOW());