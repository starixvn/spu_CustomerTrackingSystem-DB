/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230403@Victoria.Le
	Task:	 	TVS Abnormal Bet by Sporttype and Abnormal Account
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230403@Victoria.Le: 	Initial Data - CustomerCategory [Redmine ID: #185319]

*/

	USE CTS_DataCenter;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
	
	CREATE TEMPORARY TABLE Temp_CustomerCategory AS
	SELECT * FROM CTS_DataCenter.CustomerCategory
	WHERE ReasonID BETWEEN 27 AND 39
		AND CategorySpec NOT LIKE '%(Evidence%'
	;
	
	SELECT * FROM Temp_CustomerCategory;
	
	UPDATE Temp_CustomerCategory
	SET   CategorySpec = CONCAT(CategorySpec, " - Abnormal Account, IssueType:13")
		, ReasonID = CASE 	WHEN CategoryID = 51 THEN 3900 -- Abnormal
							WHEN CategoryID = 52 THEN 10000 -- Group Betting
							WHEN CategoryID = 53 THEN 10100 -- Hedging
							WHEN CategoryID = 54 THEN 10200 -- Arbitrage
							WHEN CategoryID = 55 THEN 10300 -- Fixed Game
							WHEN CategoryID = 56 THEN 10400 -- AB Bet
							WHEN CategoryID = 61 THEN 10500 -- Robot User
							WHEN CategoryID = 58 THEN 10600 -- Irrigation Bet
							WHEN CategoryID = 59 THEN 10700 -- System Formula Bet
							WHEN CategoryID = 92 THEN 10000 -- Group Betting (Probation)
							WHEN CategoryID = 93 THEN 10100 -- Hedging (Probation)
							WHEN CategoryID = 94 THEN 10200 -- Arbitrage (Probation)
							WHEN CategoryID = 95 THEN 10300 -- Fixed Game (Probation)
							WHEN CategoryID = 98 THEN 10600 -- Irrigation Bet (Probation)
							WHEN CategoryID = 99 THEN 10700 -- System Formula Bet (Probation)
					 END
		, CategoryID = CASE WHEN CategoryID = 51 THEN 165 -- Abnormal
							WHEN CategoryID = 52 THEN 166 -- Group Betting
							WHEN CategoryID = 53 THEN 167 -- Hedging
							WHEN CategoryID = 54 THEN 168 -- Arbitrage
							WHEN CategoryID = 55 THEN 169 -- Fixed Game
							WHEN CategoryID = 56 THEN 170 -- AB Bet
							WHEN CategoryID = 61 THEN 173 -- Robot User
							WHEN CategoryID = 58 THEN 171 -- Irrigation Bet
							WHEN CategoryID = 59 THEN 172 -- System Formula Bet
							WHEN CategoryID = 92 THEN 174 -- Group Betting (Probation)
							WHEN CategoryID = 93 THEN 175 -- Hedging (Probation)
							WHEN CategoryID = 94 THEN 176 -- Arbitrage (Probation)
							WHEN CategoryID = 95 THEN 177 -- Fixed Game (Probation)
							WHEN CategoryID = 98 THEN 178 -- Irrigation Bet (Probation)
							WHEN CategoryID = 99 THEN 179 -- System Formula Bet (Probation)
					 END
	;

	INSERT INTO CTS_DataCenter.CustomerCategory (CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, TaggingID, TaggingType, ReasonID, SourceType, AFCFraudID, EvidenceID_Licensee, EvidenceCode_Licensee, EvidenceID_Credit, EvidenceCode_Credit, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, RelevantCategoryID, ABIDangerLevel_Licensee, ABIDangerLevelException_Licensee, ABIDangerLevel_Credit, ABIDangerLevelException_Credit, IsProbation, ProblemCaseID, IsHedgingReasonMM, RootTaggingID, IsPAProbation, DangerLevelType, Priority, IsDangerProbation, SabaSportType, OldCustomerClass)
	SELECT CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, IsUsedManually, NOW(), CreatedBy, LastModifiedDate, LastModifiedBy, ScanIntervalInSecond, CategoryNameCN, CategoryGroup, TaggingID, TaggingType, ReasonID, SourceType, AFCFraudID, EvidenceID_Licensee, EvidenceCode_Licensee, EvidenceID_Credit, EvidenceCode_Credit, CustomerClass, CustomerClassName, CustomerClassNameCN, CustomerClassException, RelevantCategoryID, ABIDangerLevel_Licensee, ABIDangerLevelException_Licensee, ABIDangerLevel_Credit, ABIDangerLevelException_Credit, IsProbation, ProblemCaseID, IsHedgingReasonMM, RootTaggingID, IsPAProbation, DangerLevelType, Priority, IsDangerProbation, SabaSportType, OldCustomerClass
	FROM Temp_CustomerCategory;
	
	SELECT * 
	FROM CTS_DataCenter.CustomerCategory
	WHERE ReasonID BETWEEN 3900 AND 10700;
	
	SELECT * 
	FROM CTS_DataCenter.CustomerCategory
	WHERE CategoryID BETWEEN 165 AND 179;