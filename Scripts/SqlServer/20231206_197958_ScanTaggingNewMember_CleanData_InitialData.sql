/*
    Creator: 	20231206@Victoria.Le
    Task:	 	New CC 2300 - TWGroupBetting Tagging New Member - Update cutoff date - truncate table CustomerClassification_ScannedNewCust
    DBName:		bodb_VR2Model
	
	Revisions: 
		- 20231206@Victoria.Le: Initial Writing [Redmine ID: #197958]

*/

USE [bodb_VR2Model]
GO

DECLARE @ReleasedDateTime VARCHAR(200);
SET @ReleasedDateTime = CONVERT(VARCHAR(200), '2023-12-07 00:00:00.00', 121);

UPDATE dbo.CustomerClassification_Parameter WITH(ROWLOCK, UPDLOCK)
SET [Value] = CONVERT(VARCHAR(200), '2023-12-07 00:00:00.00', 121)
WHERE DataId IN (7,8);

-- -----------------------------------------------------------------------------------
-- should backup data before truncate this table?

TRUNCATE TABLE CustomerClassification_ScannedNewCust;