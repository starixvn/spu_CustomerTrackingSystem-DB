/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20220325@Aries.Nguyen 
	Task:	 	Refactor the Sum data job of transaction statistic [Redmine ID: #170525]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20220325@Aries.Nguyen: Created [Redmine ID: #170525]
	Reviewer:
*/

USE DCS_DataCenter;
ALTER TABLE Transaction07
DROP INDEX IX_Transaction07_CreatedDate,
ADD INDEX IX_Transaction07_CreatedDate_AccountID(CreatedDate,AccountID);


INSERT IGNORE INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(21,"SumTransaction", 'SumTransaction_LastDateScan', 'XXXXXXX', NOW())
	, (22,"SumTransaction", 'SumTransaction_LastAccountID', 0, NOW());