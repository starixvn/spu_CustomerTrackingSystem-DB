/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20200121@Casey.Huynh
	Task: 	Initial New PA Category [Redmine ID: 148908]
	DB: 	 CTS_DataCenter
*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`CustomerCategory`
		(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, CreatedDate, CreatedBy
        , LastModifiedDate, LastModifiedBy, IsUsedManually, ScanIntervalInSecond, CategoryNameCN, CategoryGroup)
VALUES	(231, 'New Member (31)', 'New Member (31)', 200, 1, 1, NOW(), NULL, NULL, NULL, 0, 0, '新会员 (31)', 201)
		, (232, 'New Member (32)', 'New Member (32)', 200, 1, 1, NOW(), NULL, NULL, NULL, 0, 0, '新会员 (32)', 201)
		, (233, 'New Member (33)', 'New Member (33)', 200, 1, 1, NOW(), NULL, NULL, NULL, 0, 0, '新会员 (33)', 201);
        
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass)
VALUES (231, 31)
		, (232, 32)
        , (233, 33);