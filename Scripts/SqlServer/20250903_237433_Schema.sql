/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250903@Thomas.Nguyen
	Task: Schema
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

DROP TABLE IF EXISTS [dbo].[Adhoc_HF237433_CustNeedToUpdateABI];
CREATE TABLE [dbo].[Adhoc_HF237433_CustNeedToUpdateABI](
		CustID INT NOT NULL PRIMARY KEY
    ,   danger2 TINYINT NOT NULL
);

GO
BULK INSERT Adhoc_HF237433_CustNeedToUpdateABI
FROM 'C:\Users\patrick.pham\Downloads\237433_ListCustcorrectABI.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);