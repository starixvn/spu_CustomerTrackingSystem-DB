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
ADD COLUMN `GroupID` SMALLINT NULL;

UPDATE DCS_DataCenter.StaticList
SET GroupID = 1
WHERE ListID = 1
	AND ItemID = 1;

UPDATE DCS_DataCenter.StaticList
SET GroupID = 2
WHERE ListID = 1
	AND ItemID BETWEEN 2 AND 8;

UPDATE DCS_DataCenter.StaticList
SET GroupID = 3
WHERE ListID = 1
	AND ItemID > 8;