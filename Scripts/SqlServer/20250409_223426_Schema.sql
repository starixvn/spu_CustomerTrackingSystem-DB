/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250404@Thomas.Nguyen
	Task: Schema
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

DROP TABLE IF EXISTS [dbo].[Adhoc_CustNeedToUpdateABI];
CREATE TABLE [dbo].[Adhoc_CustNeedToUpdateABI](
		CustID INT NOT NULL PRIMARY KEY
);