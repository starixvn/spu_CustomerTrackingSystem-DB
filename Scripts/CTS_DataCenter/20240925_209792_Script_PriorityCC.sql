/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240923@Jonas.Huynh
Task:	 	script updata data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240923@Jonas.Huynh: Created  [RedmineID: #209792]
Reviewer:
*/

USE CTS_DataCenter;

-- #1. Update Table CTS_DataCenter.CustomerCategory
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 580, CustomerClassPriority = 580 WHERE CategoryID = 21200;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 580, CustomerClassPriority = 580 WHERE CategoryID = 26200;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 570, CustomerClassPriority = 570 WHERE CategoryID = 21100;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 570, CustomerClassPriority = 570 WHERE CategoryID = 26100;

UPDATE CTS_DataCenter.CustomerCategory SET ParentID = 20000, CategoryPriority = 530, CustomerClassPriority = 530 WHERE CategoryID = 30100;
UPDATE CTS_DataCenter.CustomerCategory SET ParentID = 20000, CategoryPriority = 530, CustomerClassPriority = 530 WHERE CategoryID = 35100;
UPDATE CTS_DataCenter.CustomerCategory SET ParentID = 20000, CategoryPriority = 500, CustomerClassPriority = 500 WHERE CategoryID = 30200;
UPDATE CTS_DataCenter.CustomerCategory SET ParentID = 20000, CategoryPriority = 500, CustomerClassPriority = 500 WHERE CategoryID = 35200;
UPDATE CTS_DataCenter.CustomerCategory SET ParentID = 20000, CategoryPriority = 450, CustomerClassPriority = 450 WHERE CategoryID = 30300;
UPDATE CTS_DataCenter.CustomerCategory SET ParentID = 20000, CategoryPriority = 450, CustomerClassPriority = 450 WHERE CategoryID = 35300;

UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 745, CustomerClassPriority = 750 WHERE CategoryID = 40605;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 750, CustomerClassPriority = 750 WHERE CategoryID = 40405;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 750, CustomerClassPriority = 750 WHERE CategoryID = 40505;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 595, CustomerClassPriority = 600 WHERE CategoryID = 40604;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 600, CustomerClassPriority = 600 WHERE CategoryID = 40404;
UPDATE CTS_DataCenter.CustomerCategory SET CategoryPriority = 600, CustomerClassPriority = 600 WHERE CategoryID = 40405;

-- #2. Update Table CTS_DataCenter.CustomerCategorySettings
UPDATE CTS_DataCenter.CustomerCategorySettings SET ParentID = 20000, IsParallelParentID = false, IsMultiCateIDSameParentID = true, IsKeepOldCateID = true WHERE CategoryID = 30300;
UPDATE CTS_DataCenter.CustomerCategorySettings SET ParentID = 20000, IsParallelParentID = false, IsMultiCateIDSameParentID = true, IsKeepOldCateID = true WHERE CategoryID = 35300;
UPDATE CTS_DataCenter.CustomerCategorySettings SET ParentID = 20000, IsParallelParentID = false, IsMultiCateIDSameParentID = true, IsKeepOldCateID = true WHERE CategoryID = 30200;
UPDATE CTS_DataCenter.CustomerCategorySettings SET ParentID = 20000, IsParallelParentID = false, IsMultiCateIDSameParentID = true, IsKeepOldCateID = true WHERE CategoryID = 35200;
UPDATE CTS_DataCenter.CustomerCategorySettings SET ParentID = 20000, IsParallelParentID = false, IsMultiCateIDSameParentID = true, IsKeepOldCateID = true WHERE CategoryID = 30100;
UPDATE CTS_DataCenter.CustomerCategorySettings SET ParentID = 20000, IsParallelParentID = false, IsMultiCateIDSameParentID = true, IsKeepOldCateID = true WHERE CategoryID = 35100;
