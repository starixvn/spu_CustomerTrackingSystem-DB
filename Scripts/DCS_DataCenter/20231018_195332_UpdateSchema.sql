/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20231018@Jonathan.Doan
	Task:	 	Add field StaticList.GroupID [Redmine ID: #195332]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20231018@Jonathan.Doan: Created [Redmine ID: #194559]
	Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`StaticList` 
ADD COLUMN `GroupID` SMALLINT NULL,
ADD COLUMN `GroupCode` varchar(100) NULL,
ADD COLUMN `GroupName` varchar(200) NULL;

UPDATE DCS_DataCenter.StaticList
SET GroupID = 1,
	GroupCode = 'Human',
	GroupName = 'Human'
WHERE ListID = 1
	AND ItemID = 1;

UPDATE DCS_DataCenter.StaticList
SET GroupID = 2,
	GroupCode = 'InvalidBrowserInfo',
	GroupName = 'Invalid Browser Info'
WHERE ListID = 1
	AND ItemID BETWEEN 2 AND 8;

UPDATE DCS_DataCenter.StaticList
SET GroupID = 3,
	GroupCode = 'Bot',
	GroupName = 'Bot'
WHERE ListID = 1
	AND ItemID > 8;


INSERT INTO DCS_DataCenter.StaticList (ListID, ItemID, ListCode, ListName, ItemCode, ItemName, Status, Description, CreatedDate) 
VALUES ('2', '1', 'MissingTransactionType', 'MissingTransactionType', 1, 'Missing Login Transaction', '1', 'Missing Login Transaction', CURRENT_TIMESTAMP()),
('2', '2', 'MissingTransactionType', 'MissingTransactionType', 2, 'Missing Bet Transaction', '1', 'Missing Bet Transaction', CURRENT_TIMESTAMP());
