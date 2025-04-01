/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250327@Casey.Huynh
Task:	 	Customer Classification - TW - Adjust criteria for New_Good_Normal - GB_High Rejected
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250327@Casey.Huynh: Created [Redmine ID #221508]

Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE Customer_FirstTWTaggingCC (	
		CustID			INT PRIMARY KEY	NOT NULL
	,	TWTaggingID 	INT NOT NULL COMMENT 'TWTaggingID IN (ex:7,8)'
	,	CreatedTime 	DATETIME NOT NULL
);

ALTER TABLE CustomerCategorySettings
	ADD IsFirstTWTagging TINYINT NOT NULL DEFAULT 0;

UPDATE CustomerCategorySettings AS s
SET IsFirstTWTagging = 1
WHERE CategoryID IN (SELECT CategoryID FROM CustomerCategory WHERE CustomerClass IN (2303, 2304, 2305, 2403, 2404, 2405));

SET @CURRENTDATE := NOW();

INSERT INTO StaticList (ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, ItemParentItemID, ItemDefaultValue, ItemValue, PriorityOrder, Status, Description, CreatedDate)
VALUES (6,19,'Classification CategoryID','CATEGORYID','CONST_CATEID_GOOD','CONST_CATEID_GOOD',3,40200,40200,NULL,1,NULL,@CURRENTDATE),
(6,19,'Classification CategoryID','CATEGORYID','CONST_CATEID_NORMAL','CONST_CATEID_NORMAL',3,40300,40300,NULL,1,NULL,@CURRENTDATE);