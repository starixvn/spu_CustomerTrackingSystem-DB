/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20201216@Long.Luu
Task:	 	Schema for new request
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	-	[20201216@Long.Luu][147210]: Get all categories of Customer Class
Reviewer:
*/

ALTER TABLE CTS_DataCenter.CustomerCategory
ADD CategoryNameCN NVARCHAR(50) AFTER CategoryName,
ADD CategoryGroup SMALLINT UNSIGNED AFTER ParentID;

ALTER TABLE CTS_DataCenter.CustomerCategory
ADD INDEX IX_CustomerCategory_CategoryGroup (CategoryGroup);
