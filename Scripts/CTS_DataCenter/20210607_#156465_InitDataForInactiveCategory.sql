/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210607@Long.Luu
Task:	 	Init data for Inactive Categories [Redmine ID: #156465]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(1001, 'Normal Member Inactive', 'Normal Member Inactive', 200, 99, 1, NOW(), 0, 0, '不活跃正常会员', 202)
,(1002, 'Pro Punter Inactive', 'Pro Punter Inactive', 200, 99, 1, NOW(), 0, 0, '不活跃精明玩家', 206);

INSERT INTO CTS_DataCenter.CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (1001,1001),(1002,1002);
/*
update CTS_DataCenter.CustomerCategory set CategoryNameCN = '不活跃正常会员' where CategoryID = 1001;
update CTS_DataCenter.CustomerCategory set CategoryNameCN = '不活跃精明玩家' where CategoryID = 1002;
*/