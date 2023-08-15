/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230803@Jonas.Huynh
	Task:	 	Customer Classification With Tagging (20xx, 21xx, 22xx, 23xx, 24xx)
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230803@Jonas.Huynh: Create Schema [Redmine ID: #191400]

*/

ALTER TABLE CTS_DataCenter.CustomerCategory
ADD COLUMN ScanTaggingIntervalInSecond	BIGINT DEFAULT NULL;

UPDATE CTS_DataCenter.CustomerCategory AS cc
SET cc.ScanTaggingIntervalInSecond = 86400
WHERE cc.CategoryGroup IN (201, 202, 203, 204, 205, 206) 
	AND cc.CategoryID NOT IN (234, 254, 264, 274)
    AND IsActive = 1
	AND IsUsedManually = 0;
    
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) VALUES
(143, 'Scan_NormalTagging_BatchSize', 'Scan_NormalTagging_BatchSize', 'BIGINT', 5000);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) VALUES
(144, 'Scan_NormalTagging_LastCategoryID', 'Scan_NormalTagging_LastCategoryID', 'BIGINT', 201);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) VALUES
(145, 'Scan_NormalTagging_LastCustID', 'Scan_NormalTagging_LastCustID', 'BIGINT', 0);