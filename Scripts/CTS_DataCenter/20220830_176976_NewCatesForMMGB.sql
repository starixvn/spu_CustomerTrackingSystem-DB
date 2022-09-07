/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202200830@Casey.Huynh
Task:	 	NewCatesForMMGB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220726@Casey.Huynh: Created [Redmine ID: #176976]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE MatchMonitorStagingLive
ADD COLUMN IsLicensee BOOLEAN;

ALTER TABLE MatchMonitorDetails 
ADD COLUMN HighStakeLicCustList LONGTEXT;

# New 2 categories for System Detect Group Betting
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, CreatedDate, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, ReasonID, SourceType, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, RelevantCategoryID, IsDangerProbation, RootTaggingID, DangerLevelType, Priority, ABIDangerLevel_Licensee, ABIDangerLevel_Credit)
VALUES (63, 'System Detect Group Betting', 'System Detect Group Betting', 50, 255, 1, 0, NOW(), 0, '系统侦测群组投注', 63, 63, 'CTS', 3101, 'Problems', '問題',3101, 103, 0, 8, 2, 40, 11, 1);
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, CreatedDate, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, ReasonID, SourceType, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, RelevantCategoryID, IsDangerProbation, RootTaggingID, DangerLevelType, Priority, ABIDangerLevel_Licensee, ABIDangerLevel_Credit)
VALUES (103, 'System Detect Group Betting (Losing)', 'System Detect Group Betting (Losing)', 50, 255, 1, 0, NOW(), 0, '系统侦测群组投注 (输钱)', 103, 103, 'CTS', 3201, 'Problems -', '問題-', 3201, 63, 1, 8, 2, 40, 11, 1);