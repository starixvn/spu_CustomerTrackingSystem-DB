/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220328@Long.Luu
Task:	 	Init New Categories for Losing PA [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListName`, `ListNameDisplay`, `ItemName`, `ItemNameDisplay`, `PriorityOrder`, `Status`) 
	VALUES 	(4, 23, 'Classification Source Type', 'Classification Source Type', 'Re-scan Problem Account', 'Re-scan Problem Account', '23', '1');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES (84, 'DailyScan_Normal_BatchSize', 'DailyScan_Normal_BatchSize', 'BIGINT', 500),
	   (85, 'DailyScan_Normal_LastCategoryID', 'DailyScan_Normal_LastCategoryID', 'BIGINT', 0),
	   (86, 'DailyScan_Normal_LastCustID', 'DailyScan_Normal_LastCustID', 'BIGINT', 0),
	   (87, 'DailyScan_PA_BatchSize', 'DailyScan_PA_BatchSize', 'BIGINT', 500),
	   (88, 'DailyScan_PA_LastCategoryID', 'DailyScan_PA_LastCategoryID', 'BIGINT', 0),
	   (89, 'DailyScan_PA_LastCustID', 'DailyScan_PA_LastCustID', 'BIGINT', 0);

ALTER TABLE CTS_DataCenter.CustomerCategory
ADD COLUMN CustomerClass SMALLINT UNSIGNED,
ADD COLUMN CustomerClassException SMALLINT UNSIGNED,
ADD COLUMN RelevantCategoryID SMALLINT UNSIGNED,
ADD COLUMN ABIDangerLevel_Licensee SMALLINT UNSIGNED,
ADD COLUMN ABIDangerLevelException_Licensee SMALLINT UNSIGNED,
ADD COLUMN ABIDangerLevel_Credit SMALLINT UNSIGNED,
ADD COLUMN ABIDangerLevelException_Credit SMALLINT UNSIGNED,
ADD COLUMN IsProbation BIT DEFAULT 0;

UPDATE CTS_DataCenter.CustomerCategory  AS cate
INNER JOIN CTS_DataCenter.CategoryToCustomerClass  AS clss  ON cate.CategoryID = clss.CategoryID
SET 	cate.CustomerClass = clss.CustomerClass
	,	cate.CustomerClassException = clss.CustomerClass;

UPDATE CTS_DataCenter.CustomerCategory
SET CustomerClassException = 132
WHERE CategoryID = 163;

UPDATE CTS_DataCenter.CustomerCategory
SET RelevantCategoryID = CASE WHEN CategoryID = 54 THEN 94
								  WHEN CategoryID = 74 THEN 114
                                  WHEN CategoryID = 154 THEN 134
								  WHEN CategoryID = 94 THEN 54
                                  WHEN CategoryID = 114 THEN 74
								  WHEN CategoryID = 134 THEN 154
                                  
                                  WHEN CategoryID = 60 THEN 100
								  WHEN CategoryID = 80 THEN 120
                                  WHEN CategoryID = 100 THEN 60
								  WHEN CategoryID = 120 THEN 80
                                  
                                  WHEN CategoryID = 55 THEN 95
								  WHEN CategoryID = 75 THEN 115
                                  WHEN CategoryID = 155 THEN 135
								  WHEN CategoryID = 95 THEN 55
                                  WHEN CategoryID = 115 THEN 75
								  WHEN CategoryID = 135 THEN 155
                                  
                                  WHEN CategoryID = 52 THEN 92
								  WHEN CategoryID = 72 THEN 112
                                  WHEN CategoryID = 152 THEN 132
								  WHEN CategoryID = 92 THEN 52
								  WHEN CategoryID = 112 THEN 72
                                  WHEN CategoryID = 132 THEN 152
                                  
                                  WHEN CategoryID = 53 THEN 93
								  WHEN CategoryID = 73 THEN 113
                                  WHEN CategoryID = 153 THEN 133
								  WHEN CategoryID = 93 THEN 53
								  WHEN CategoryID = 113 THEN 73
                                  WHEN CategoryID = 133 THEN 153
                                  
                                  WHEN CategoryID = 62 THEN 102
								  WHEN CategoryID = 82 THEN 122
                                  WHEN CategoryID = 162 THEN 142
								  WHEN CategoryID = 102 THEN 62
								  WHEN CategoryID = 122 THEN 82
                                  WHEN CategoryID = 142 THEN 162
                                  
                                  WHEN CategoryID = 58 THEN 98
								  WHEN CategoryID = 78 THEN 118
                                  WHEN CategoryID = 158 THEN 138
								  WHEN CategoryID = 98 THEN 58
								  WHEN CategoryID = 118 THEN 78
                                  WHEN CategoryID = 138 THEN 158
                                  
                                  WHEN CategoryID = 59 THEN 99
								  WHEN CategoryID = 79 THEN 119
                                  WHEN CategoryID = 159 THEN 139
								  WHEN CategoryID = 99 THEN 59
								  WHEN CategoryID = 119 THEN 79
                                  WHEN CategoryID = 139 THEN 159
                                  ELSE NULL
							  END;
UPDATE CTS_DataCenter.CustomerCategory
SET IsProbation = 1
WHERE CategoryID IN (94,114,134,100,120,95,115,135,92,112,132,93,113,133,102,122,142,98,118,138,99,119,139);

SELECT CategoryID,RelevantCategoryID,CategoryName,CategorySpec,CustomerClassException,IsProbation,ABIDangerLevel_Licensee,ABIDangerLevel_Credit
FROM CustomerCategory;


UPDATE CustomerCategory AS cate
INNER JOIN CategoryToDangerLevel AS abi ON cate.CategoryID = abi.CategoryID
SET cate.ABIDangerLevel_Credit = abi.DangerLevel
WHERE abi.IsLicensee = 0;

UPDATE CustomerCategory AS cate
INNER JOIN CategoryToDangerLevel AS abi ON cate.CategoryID = abi.CategoryID
SET cate.ABIDangerLevel_Licensee = abi.DangerLevel
WHERE abi.IsLicensee = 1;

UPDATE CTS_DataCenter.CustomerCategory
SET     EvidenceID_Licensee = '50'
    ,   EvidenceCode_Licensee = '6.18' 
WHERE (CategoryID = '80');

UPDATE CTS_DataCenter.CustomerCategory
SET     EvidenceID_Licensee = '61', EvidenceCode_Licensee = '6.9'
    ,   EvidenceID_Credit = '51'
    ,   EvidenceCode_Credit = '6.19' 
WHERE (CategoryID = '82');
 

UPDATE CTS_DataCenter.CustomerCategory AS cate
INNER JOIN CTS_DataCenter.CustomerCategory AS rela on cate.RelevantCategoryID = rela.CategoryID
SET cate.ReasonID = rela.ReasonID
	, cate.SourceType = rela.SourceType
    , cate.EvidenceID_Licensee = rela.EvidenceID_Licensee
    , cate.EvidenceCode_Licensee = rela.EvidenceCode_Licensee
    , cate.EvidenceID_Credit = rela.EvidenceID_Credit
    , cate.EvidenceCode_Credit = rela.EvidenceCode_Credit
WHERE cate.IsProbation = 1;

UPDATE CustomerCategory AS pro
INNER JOIN CustomerCategory AS pa ON pa.CategoryID = pro.RelevantCategoryID
SET pro.AFCFraudID = pa.AFCFraudID
WHERE pro.IsProbation = 1; 