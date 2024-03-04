/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240130@Victoria.Le
	Task:		Create userlogin on new database
	Server:		DB061 & DB062
	
	Revisions:
			- 20240130@Victoria.Le: Initial Writing - Step 0 - 2[Redmine: #191955]	
*/


USE	WASAVerse;
GO

/* -- Local Account
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='sputeam')
BEGIN
	CREATE USER sputeam FOR LOGIN sputeam;
END;
GO
*/

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='vnSPU')
BEGIN
	CREATE USER vnSPU FOR LOGIN vnSPU;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='bodbSPUNet')
BEGIN
	CREATE USER bodbSPUNet FOR LOGIN bodbSPUNet;
END;
GO