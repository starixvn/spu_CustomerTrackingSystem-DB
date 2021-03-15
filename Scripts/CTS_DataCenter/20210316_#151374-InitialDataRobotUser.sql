/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210316@Irena.Vo
	Task: 	 151374 - Initial Category & CC & Update Log for Robot User
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210316@Irena.Vo]: Init data: CustomerCategory, CategoryToCustomerClass. Update: StaticList.
*/
USE CTS_DataCenter;

/*  Init CustomerCategory */
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,CreatedDate,IsUsedManually,ScanIntervalInSecond,CategoryNameCN,CategoryGroup)
VALUES	
(61, 'Robot User', 'Robot User', 50, 13, 1, NOW(), 0, 0, NULL, 61);

/* Init CategoryToCustomerClass */
INSERT INTO CTS_DataCenter.CategoryToCustomerClass (CategoryID, CustomerClass) VALUES (61,13);
        
/*  Update StaticList */
UPDATE CTS_DataCenter.StaticList
SET ItemName = 'Update Category and Customer Class', ItemNameDisplay = 'Update Category and Customer Class'
WHERE ListID = 4 AND ItemID = 11;