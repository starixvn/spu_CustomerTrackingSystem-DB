/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230517@Victoria.Le
	Task:	 	TW BI - CTS Classname in EN and Simplified CN
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230517@Victoria.Le: 	Initial - CustomerCategory [Redmine ID: #188388]

*/	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
	
	CREATE TEMPORARY TABLE Temp_CustomerCategory
	(
			CategoryID						SMALLINT	PRIMARY KEY
		,	SabaIntelligent_RiskLevel		VARCHAR(50)
		,	SabaIntelligent_RiskLevel_TCN	VARCHAR(50)
		,	SabaIntelligent_RiskLevel_SCN	VARCHAR(50)
	)
	;
	
	INSERT INTO Temp_CustomerCategory 
	(
			CategoryID						
		,	SabaIntelligent_RiskLevel		
		,	SabaIntelligent_RiskLevel_TCN	
		,	SabaIntelligent_RiskLevel_SCN	
	)
	SELECT 	CategoryID
		,	CASE 	WHEN CategoryID IN (202,205,210,211,212,213,1001) THEN 'Healthy'
					WHEN CategoryID IN (201,234) THEN 'New'
					WHEN CategoryID IN (221,222,223) THEN 'Moderate'
					WHEN CategoryID IN (4,206,231,232,233,251,252,253,254,257,258) THEN 'Suspicious'
					WHEN CategoryID IN (2,3,203,204,261,262,263,264,267,268,271,272,273,274,277,278,1002) THEN 'Dangerous'
					WHEN CategoryID IN (57,61,81,157,161,163,164,179) THEN 'Robot'
					WHEN CategoryID IN (52,53,54,55,56,58,59,60,62,63,72,73,74,75,76,78,79,80,82,92,93,94,95,98,99,100,102,103,112,113,114,115,118,119,120,122,132,133,134,135,138,139,142,152,153,154,155,156,158,159,162,172,173,174,175,176,177,178,180,181,182,183,184,185) THEN 'Problems'
					ELSE NULL
			END AS SabaIntelligent_RiskLevel
		,	CASE 	WHEN CategoryID IN (202,205,210,211,212,213,1001) THEN '健康'
					WHEN CategoryID IN (201,234) THEN '新會員'
					WHEN CategoryID IN (221,222,223) THEN '中等'
					WHEN CategoryID IN (4,206,231,232,233,251,252,253,254,257,258) THEN '可疑'
					WHEN CategoryID IN (2,3,203,204,261,262,263,264,267,268,271,272,273,274,277,278,1002) THEN '危險'
					WHEN CategoryID IN (57,61,81,157,161,163,164,179) THEN '機械'
					WHEN CategoryID IN (52,53,54,55,56,58,59,60,62,63,72,73,74,75,76,78,79,80,82,92,93,94,95,98,99,100,102,103,112,113,114,115,118,119,120,122,132,133,134,135,138,139,142,152,153,154,155,156,158,159,162,172,173,174,175,176,177,178,180,181,182,183,184,185) THEN '問題'
					ELSE NULL
			END AS SabaIntelligent_RiskLevel_TCN
		,	CASE 	WHEN CategoryID IN (202,205,210,211,212,213,1001) THEN '健康'
					WHEN CategoryID IN (201,234) THEN '新会员'
					WHEN CategoryID IN (221,222,223) THEN '中等'
					WHEN CategoryID IN (4,206,231,232,233,251,252,253,254,257,258) THEN '可疑'
					WHEN CategoryID IN (2,3,203,204,261,262,263,264,267,268,271,272,273,274,277,278,1002) THEN '危险'
					WHEN CategoryID IN (57,61,81,157,161,163,164,179) THEN '机械'
					WHEN CategoryID IN (52,53,54,55,56,58,59,60,62,63,72,73,74,75,76,78,79,80,82,92,93,94,95,98,99,100,102,103,112,113,114,115,118,119,120,122,132,133,134,135,138,139,142,152,153,154,155,156,158,159,162,172,173,174,175,176,177,178,180,181,182,183,184,185) THEN '问题'
					ELSE NULL
			END AS SabaIntelligent_RiskLevel_SCN
	FROM CTS_DataCenter.CustomerCategory
	;
	
	UPDATE CTS_DataCenter.CustomerCategory AS cc
		INNER JOIN Temp_CustomerCategory AS tmp ON tmp.CategoryID = cc.CategoryID
	SET 	cc.SabaIntelligent_RiskLevel 		= tmp.SabaIntelligent_RiskLevel
		,	cc.SabaIntelligent_RiskLevel_TCN 	= tmp.SabaIntelligent_RiskLevel_TCN
		,	cc.SabaIntelligent_RiskLevel_SCN	= tmp.SabaIntelligent_RiskLevel_SCN
	;