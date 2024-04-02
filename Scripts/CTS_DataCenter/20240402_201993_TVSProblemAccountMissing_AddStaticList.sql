/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240402@Jonas.Huynh
	Task:	 	TVS Problem Account Missing - Add StaticList
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20240402@Jonas.Huynh: Create Schema [Redmine ID: #201993]
*/

INSERT INTO `CTS_DataCenter`.`StaticList`(`ListID`,`ItemID`,`ListName`,`ListNameDisplay`,`ItemName`,`ItemNameDisplay`,`ItemValue`,`ItemDefaultValue`,`ItemParentItemID`,`PriorityOrder`,`Status`,`Description`,`CreatedDate`) VALUES
(20,202,'Job Monitoring IssueType','Job Monitoring IssueType','Classification - TVS Problem Account Missing','Classification - TVS Problem Account Missing',null,null,null,null,1,null, NOW());
