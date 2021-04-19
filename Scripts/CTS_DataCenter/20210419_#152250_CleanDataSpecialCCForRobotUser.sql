/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210419@Irena.Vo
	Task: Clean data Special CC for Robot User [Redmine ID: #152250] 
	DB: CTS_DataCenter
*/
-- Clean Data Special CC for Robot User
DELETE sp
FROM CTS_DataCenter.SpecialCustomerClass AS sp
WHERE sp.CustomerClass = 13 AND sp.CreatedBy = 10278938;  