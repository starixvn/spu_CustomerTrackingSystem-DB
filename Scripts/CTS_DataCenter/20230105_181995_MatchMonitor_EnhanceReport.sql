/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230105@Casey.Huynh
Task:	 	Enhance MatchMonitor Report
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230105@Casey.Huynh: Created [Redmine ID: #181995]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE MatchMonitor
	ADD COLUMN InsertDate DATETIME DEFAULT(DATE(InsertTime))
,	ADD INDEX IX_MatchMonitor_InsertDate(InsertDate);

UPDATE StaticList SET ItemNameDisplay = 'GB' WHERE ListID = 16 AND ItemID = 1;
UPDATE StaticList SET ItemNameDisplay = 'HED' WHERE ListID = 16 AND ItemID = 2;
UPDATE StaticList SET ItemNameDisplay = 'ARB' WHERE ListID = 16 AND ItemID = 3;
UPDATE StaticList SET ItemNameDisplay = 'FG' WHERE ListID = 16 AND ItemID = 4;
UPDATE StaticList SET ItemNameDisplay = 'IRR' WHERE ListID = 16 AND ItemID = 5;

