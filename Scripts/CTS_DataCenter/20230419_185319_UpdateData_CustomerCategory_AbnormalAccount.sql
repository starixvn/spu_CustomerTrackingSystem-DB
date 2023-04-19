/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230419@Victoria.Le
	Task:	 	TVS Abnormal Bet by Sporttype and Abnormal Account
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230419@Victoria.Le: 	Update CategoryID [Redmine ID: #185319]

*/

	USE CTS_DataCenter;

	UPDATE CTS_DataCenter.CustomerCategory
	SET CategoryID = CategoryID + 6
	WHERE CategoryID >= 165 AND CategoryID < 190;

	UPDATE CTS_DataCenter.CustomerCategory
	SET DisplayOrder = 179
	WHERE CategoryID = 179;
	
	SELECT * 
	FROM CTS_DataCenter.CustomerCategory
	where CategoryID >= 165 AND CategoryID < 190;