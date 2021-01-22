/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20200121@Casey.Huynh
	Task: 	Initial New PA Category
	DB: 	 CTS_DataCenter
    
    Revisions: 
	- 20200121@Casey.Huynh: Created [148908]
*/
INSERT INTO `CTS_DataCenter`.`CustomerCategory`
		(CategoryID, CategoryName, CategorySpec, CategorySpecCN, ParentID, DisplayOrder, IsActive, CreatedDate, CreatedBy
        , LastModifiedDate, LastModifiedBy, IsUsedManually, ScanIntervalInSecond, CategoryNameCN, CategoryGroup)
VALUES	(231, 'New Member (31)', 'New Member (31)', NULL, 200, 1, 1, NOW(), NULL, NULL, NULL, 0, 0, '新会员 (31)', 201)
		, (232, 'New Member (32)', 'New Member (32)', NULL, 200, 1, 1, NOW(), NULL, NULL, NULL, 0, 0, '新会员 (32)', 201)
		, (233, 'New Member (33)', 'New Member (33)', NULL, 200, 1, 1, NOW(), NULL, NULL, NULL, 0, 0, '新会员 (33)', 201)