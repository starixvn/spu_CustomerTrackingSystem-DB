/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220705@Long.Luu
    Task:	    [CTS] Update robot classification rule [Redmine ID: #174430]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
SET SQL_SAFE_UPDATES = 0;
#ALTER TABLE CTSCustomer	DROP COLUMN IsLicBA;
ALTER TABLE CTSCustomer
		ADD COLUMN IsLicenseeVIP 		TINYINT(1) DEFAULT 0
	,  	ADD COLUMN IsLicenseeBA 		TINYINT(1) DEFAULT 0;
    
ALTER TABLE CustomerCategory
		ADD COLUMN IsDangerProbation 	BIT DEFAULT 0;

ALTER TABLE CTSCustomer
ADD INDEX IX_CTSCustomer_SiteID(SiteID);

DELETE FROM CTS_DataCenter.CustomerCategory WHERE CategoryID < 50;

INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec,DisplayOrder)
VALUES (1, 'Wrapper Category', 'Wrapper Category',1);
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, CreatedDate, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, ReasonID, SourceType, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, IsProbation, IsPAProbation, RootTaggingID, DangerLevelType, Priority)
VALUES (2, 'BA User', 'BA User', 1, 14, 1, 0, NOW(), 0, 'BA 用戶', 2, 14, 'NAP', 14, 'Dangerous', '危險', 14, 0, 0, 14, 0, 90);
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, CreatedDate, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, ReasonID, SourceType, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, RelevantCategoryID, IsProbation, IsPAProbation, RootTaggingID, DangerLevelType, Priority)
VALUES (3, 'VIP (Problem Member)', 'VIP (Problem Member)', 1, 99, 1, 0, NOW(), 0, 'VIP会员（问题会员)', 99, 99, 'NAP', 99, 'Dangerous', '危險', 99, 4, 0, 0, 99, 0, 30);
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, CreatedDate, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, ReasonID, SourceType, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, RelevantCategoryID, IsProbation, IsPAProbation, RootTaggingID, DangerLevelType, Priority)
VALUES (4, 'VIP (Normal Member)', 'VIP (Normal Member)', 1, 101, 1, 0, NOW(), 0, 'VIP会员 (正常会员)', 99, 101, 'NAP', 101, 'Suspicious', '可疑', 101, 3, 1, 1, 99, 0, 31);
   
UPDATE CTS_DataCenter.CustomerCategory
SET Priority = 40
WHERE ParentID = 50;

UPDATE CTS_DataCenter.CustomerCategory
SET Priority = 50
WHERE CategoryID IN (163,164);

UPDATE CTS_DataCenter.CustomerCategory
SET Priority = 60
WHERE CustomerClass IN (57, 58, 67, 68, 77, 78);

UPDATE CTS_DataCenter.CustomerCategory
SET Priority = 80
WHERE CustomerClass IN (111, 112, 113, 121, 122, 123, 31, 32, 33, 51, 52, 53, 61, 62, 63, 71, 72, 73);

UPDATE CTS_DataCenter.CustomerCategory
SET Priority = 100
WHERE CustomerClass IN (1, 2, 3, 5, 6, 7);
        
UPDATE CustomerCategory
SET IsDangerProbation = IsPAProbation;

UPDATE CTS_DataCenter.CustomerCategory
SET IsDangerProbation = 1
WHERE CustomerClass IN (1, 111, 112, 113, 2, 121, 122, 123, 3, 31, 32, 33, 43, 5, 6, 7, 86, 96, 106, 116, 126, 132, 1001, 1002);

UPDATE CTS_DataCenter.CustomerCategory
SET IsDangerProbation = 0
WHERE CustomerClass IN (45, 46, 47, 51, 52, 53, 57, 58, 61, 62, 63, 67, 68, 71, 72, 73, 77, 78, 8, 9, 10, 11, 12, 13, 131, 14);

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (4,38,'Classification Source Type','Classification Source Type','No Reason Details','Not show Details',38,1,'Not show Details',NOW());