/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250815@Thomas.Nguyen
	Task: Schema
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

DROP TABLE IF EXISTS [dbo].[Adhoc_HF235881_CustNeedToUpdateABI];
CREATE TABLE [dbo].[Adhoc_HF235881_CustNeedToUpdateABI](
		CustID INT NOT NULL PRIMARY KEY
    ,   danger2 TINYINT NOT NULL
);

GO
BULK INSERT Adhoc_HF235881_CustNeedToUpdateABI
FROM 'C:\Users\patrick.pham\Downloads\235881_ListCustcorrectABI.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);