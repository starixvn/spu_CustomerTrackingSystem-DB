/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210726@Long.Luu
Task:	 	Init data for TW suggested Categories [Redmine ID: #155956]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT IGNORE INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(257, 'Probation (57)', 'Probation (57)', 200, 99, 1, NOW(), 0, 0, '观察期会员 (57)', 206)
,(258, 'Probation (58)', 'Probation (58)', 200, 99, 1, NOW(), 0, 0, '观察期会员 (58)', 206)
,(267, 'Smart Punter (67)', 'Smart Punter (67)', 200, 99, 1, NOW(), 0, 0, '精明玩家 (67)', 203)
,(268, 'Smart Punter (68)', 'Smart Punter (68)', 200, 99, 1, NOW(), 0, 0, '精明玩家 (68)', 203)
,(277, 'High Risk (77)', 'High Risk (77)', 200, 99, 1, NOW(), 0, 0, '高危玩家 (77)', 204)
,(278, 'High Risk (78)', 'High Risk (78)', 200, 99, 1, NOW(), 0, 0, '高危玩家 (78)', 204);

INSERT IGNORE INTO CTS_DataCenter.CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (257,57),(258,58),(267,67),(268,68),(277,77),(278,78);

INSERT IGNORE INTO CTS_DataCenter.StaticList(CategoryID,CustomerClass)
VALUES (257,57),(258,58),(267,67),(268,68),(277,77),(278,78);

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD TWGroupBettingRate DECIMAL(10,4); 
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD TWTicketRejectRate DECIMAL(10,4); 
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD TWDesktopUsageRate DECIMAL(10,4); 
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD TWBetCount BIGINT; 

INSERT IGNORE INTO `CTS_DataCenter`.`StaticList`
(`ListID`, `ItemID`, `ListName`, `ListNameDisplay`, `ItemName`, `ItemNameDisplay`, `PriorityOrder`, `Status`, `Description`, `CreatedDate`)
VALUES
(9, 2, 'Tagging Type', 'Tagging Type', 'Tagging By TW', 'Tagging By TW', 2, 1, 'Tagging By TW: Group betting & Reject', '2021-07-27 05:45:34');

INSERT IGNORE INTO CTS_DataCenter.TaggingToCategory (CategoryID, TaggingID, TaggingType, CategoryGroup)
VALUES 
(257, 7, 2, 206),
(258, 8, 2, 206),
(267, 7, 2, 203),
(268, 8, 2, 203),
(277, 7, 2, 204),
(278, 8, 2, 204);