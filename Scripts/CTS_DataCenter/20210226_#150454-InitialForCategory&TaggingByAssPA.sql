/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210226@Irena.Vo
	Task: 	 150454 - Initial Category & Tagging By Association With PA [Redmine ID: #150454]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210226@Irena.Vo]: Init data: LogType, StaticList, CustomerCategory, CategoryToCustomerClass, TaggingToCategory.
*/
USE CTS_Admin;
/* Init LogType */
INSERT INTO CTS_Admin.LogType(LogTypeName,LogTypeDescription) 
VALUES 
('Unmark Tagging By Association With PA', 'Unmark Tagging By Association With PA for Normal Category'),
('Mark Tagging By Association With PA', 'Mark Tagging By Association With PA for Normal Category');

USE CTS_DataCenter;
/*  Init StaticList */
INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES 
(9,0,'Tagging Type','Tagging Type','No Tagging By Association With PA','No Tagging By Association With PA',0,1,'No Tagging By Association With PA',NOW()),
(9,1,'Tagging Type','Tagging Type','Tagging By Association with PA','Tagging By Association With PA',1,1,'Tagging By Association With PA',NOW());

/*  Init CustomerCategory */
-- Update VVIP
DELETE FROM CTS_DataCenter.CustomerCategory WHERE CategoryID = 213;
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(210, 'VVIP', 'VVIP', 200, 10, 1, NOW(), 1, 0, NULL, 210);
-- VIP
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(211, 'VIP (111)', 'VIP (111)', 200, 5, 1, NOW(), 0, 604800, 'VIP (111)', 205)
,(212, 'VIP (112)', 'VIP (112)', 200, 5, 1, NOW(), 0, 604800, 'VIP (112)', 205)
,(213, 'VIP (113)', 'VIP (113)', 200, 5, 1, NOW(), 0, 604800, 'VIP (113)', 205);
-- Normal
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(221, 'Normal Account (121)', 'Normal Account (121)', 200, 2, 1, NOW(), 0, 1209600, '普通会员(121)', 202)
,(222, 'Normal Account (122)', 'Normal Account (122)', 200, 2, 1, NOW(), 0, 1209600, '普通会员(122)', 202)
,(223, 'Normal Account (123)', 'Normal Account (123)', 200, 2, 1, NOW(), 0, 1209600, '普通会员(123)', 202);
-- Probation
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(251, 'Probation (51)', 'Probation (51)', 200, 6, 1, NOW(), 0, 1209600, '观察期会员 (51)', 206)
,(252, 'Probation (52)', 'Probation (52)', 200, 6, 1, NOW(), 0, 1209600, '观察期会员 (52)', 206)
,(253, 'Probation (53)', 'Probation (53)', 200, 6, 1, NOW(), 0, 1209600, '观察期会员 (53)', 206);
-- Smart Punter
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(261, 'Smart Punter (61)', 'Smart Punter (61)', 200, 3, 1, NOW(), 0, 1209600, '精明玩家 (61)', 203)
,(262, 'Smart Punter (62)', 'Smart Punter (62)', 200, 3, 1, NOW(), 0, 1209600, '精明玩家 (62)', 203)
,(263, 'Smart Punter (63)', 'Smart Punter (63)', 200, 3, 1, NOW(), 0, 1209600, '精明玩家 (63)', 203);
-- High Risk Punter
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(271, 'High Risk (71)', 'High Risk (71)', 200, 4, 1, NOW(), 0, 1209600, '高危玩家 (71)', 204)
,(272, 'High Risk (72)', 'High Risk (72)', 200, 4, 1, NOW(), 0, 1209600, '高危玩家 (72)', 204)
,(273, 'High Risk (73)', 'High Risk (73)', 200, 4, 1, NOW(), 0, 1209600, '高危玩家 (73)', 204);

/* Init CategoryToCustomerClass */
-- Update VVIP
DELETE FROM CTS_DataCenter.CategoryToCustomerClass WHERE CategoryID = 213;
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (210, 100);
-- VIP   
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (211, 111), (212, 112), (213, 113);
-- Normal Account   
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (221, 121), (222, 122), (223, 123);
-- Probation  
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (251, 51), (252, 52), (253, 53);
-- Smart Punter 
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (261, 61), (262, 62), (263, 63);
-- High Risk Punter 
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (271, 71), (272, 72), (273, 73);
        
/* Init TaggingToCategory */        
USE CTS_DataCenter;
INSERT INTO TaggingToCategory(CategoryID, TaggingID, TaggingType, CategoryGroup)
VALUES	(205, 0, 0, 205) 
        , (211, 8, 1, 205)
        , (212, 10, 1, 205)
        , (213, 13, 1, 205)
        , (202, 0, 0, 202)
        , (221, 8, 1, 202)
        , (222, 10, 1, 202)
        , (223, 13, 1, 202)
        , (201, 0, 0, 201)
        , (231, 8, 1, 201)
        , (232, 10, 1, 201)
        , (233, 13, 1, 201)
        , (206, 0, 0, 206)
        , (251, 8, 1, 206)
        , (252, 10, 1, 206)
        , (253, 13, 1, 206)
        , (203, 0, 0, 203)
        , (261, 8, 1, 203)
        , (262, 10, 1, 203)
        , (263, 13, 1, 203)
        , (204, 0, 0, 204)
        , (271, 8, 1, 204)
        , (272, 10, 1, 204)
        , (273, 13, 1, 204);        
        