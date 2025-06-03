/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250529@Thomas.Nguyen
	Task: Schema
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

DROP TABLE IF EXISTS [dbo].[Adhoc_HF222541_CustNeedToUpdateABI];
CREATE TABLE [dbo].[Adhoc_HF222541_CustNeedToUpdateABI](
		CustID INT NOT NULL PRIMARY KEY
);

GO
BULK INSERT Adhoc_HF222541_CustNeedToUpdateABI
FROM 'C:\Users\thomas.nguyen\Downloads\222541_ListCustcorrectABI.csv'
WITH (
    ROWTERMINATOR = '\n',
    FIRSTROW = 1
);