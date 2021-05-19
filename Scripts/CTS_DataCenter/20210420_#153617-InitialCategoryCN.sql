/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210420@Irena.Vo
	Task: 	 Initial Category CN [Redmine ID: #153617]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210420@Irena.Vo]: Init data: CustomerCategory
*/
USE CTS_DataCenter;
/*  Init CustomerCategory */
UPDATE CTS_DataCenter.CustomerCategory 
SET CategoryNameCN = '非正常'
WHERE CategoryGroup = 51;