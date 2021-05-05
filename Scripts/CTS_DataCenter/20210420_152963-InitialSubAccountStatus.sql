/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210420@Irena.Vo
Task:	 	Initial Sub Account status [Redmine ID: 152963] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT IGNORE INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,Status,Description,CreatedDate)
VALUES(1,0,'Account Status','Account Status','N/A','N/A',1,'Profile Status Item',NOW()); 

UPDATE CTS_DataCenter.StaticList
SET PriorityOrder = 1, ListNameDisplay = 'Account Status'
WHERE ListID = 1 AND ItemID IN (1, 11);

UPDATE CTS_DataCenter.StaticList
SET PriorityOrder = 2, ListNameDisplay = 'Account Status'
WHERE ListID = 1 AND ItemID IN (2,12,3,13,4,14);

UPDATE CTS_DataCenter.StaticList
SET PriorityOrder = 3, ListNameDisplay = 'Account Status'
WHERE ListID = 1 AND ItemID NOT IN (1,11,2,12,3,13,4,14);