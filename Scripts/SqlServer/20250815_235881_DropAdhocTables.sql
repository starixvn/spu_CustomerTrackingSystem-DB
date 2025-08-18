/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250529@Thomas.Nguyen
	Task: DROP Adhoc Table for cleaning ABI
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

DROP TABLE IF EXISTS [dbo].[Adhoc_CustNeedToUpdateABI];
DROP TABLE IF EXISTS [dbo].[Adhoc_HF222541_CustNeedToUpdateABI];
DROP TABLE IF EXISTS [dbo].[Adhoc_HF235881_CustNeedToUpdateABI];
