/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20240315@Casey.Huynh
    Task:	 	Match Monitor
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20240315@Casey.Huynh: Schema and Innit Data [Redmine ID: #201358]
    Reviewer: Long.Lưu
*/
USE CTS_DataCenter;
/*
CREATE TABLE `Customer_DangerousScore` (
  `ID` bigint NOT NULL AUTO_INCREMENT,
  `CustID` bigint unsigned NOT NULL,
  `IsDeposit` tinyint(1) DEFAULT '0',
  `DangerousScore` decimal(8,4) DEFAULT NULL,
  `CreatedDate` datetime(3) NOT NULL,
  `LastModifiedDate` datetime(3) NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_Customer_DangerousScore_CustID` (`CustID`),
  KEY `IX_Customer_DangerousScore_CustIDCreatedDateLastModifiedDate` (`CustID`,`CreatedDate`,`LastModifiedDate`),
  KEY `IX_Customer_DangerousScore_IsDeposit` (`IsDeposit`)
) ENGINE=InnoDB AUTO_INCREMENT=326859 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

*/
#====UPDATE TABLE================================================================================
ALTER TABLE Customer_DangerousScore
		RENAME COLUMN IsDeposit to IsLicensee
	,	DROP INDEX IX_Customer_DangerousScore_IsDeposit 
    ,	DROP INDEX IX_Customer_DangerousScore_CustIDCreatedDateLastModifiedDate
    ,	ADD INDEX IX_Customer_DangerousScore_IsLicenseeLastModifiedDate(IsLicensee,LastModifiedDate)
	,	ADD COLUMN ClassifiedScore	DECIMAL(8,4)
    ,	ADD COLUMN ClassifiedDate	DATETIME(3)
;

ALTER TABLE CustomerCategory
	ADD COLUMN GroupPriority INT
;

UPDATE CustomerCategory 
SET GroupPriority = 50000 #ParentID*1000
WHERE ParentID = 50
;

SELECT Priority, c.* FROM CustomerCategory c WHERE ParentID = 50 
;
#====Parameter for Classify  New================================================================================
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(153, 'ClassificationNewDangerScoreCredit_LastDate','Customer_DangerousScore.LastModifiedDate', 'DATETIME(3)', '2023-08-23')
	,	(154, 'ClassificationNewDangerScoreCredit_LastCustID','Customer_DangerousScore.CustID', 'INT', '0')
    ,	(155, 'ClassificationNewDangerScoreCredit_BatchSize',NULL, 'INT', '1000')
;
SELECT * FROM SystemParameter WHERE ParameterID IN (153, 154,155)
;
#====Staticlist for Rule================================================================================
INSERT INTO StaticList(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, ItemValue, ItemDefaultValue, ItemParentItemID, PriorityOrder, Status, Description, CreatedDate)
VALUES	(22, 1, 'Classification Danger Score Rule', 'CreditMinScore', 'Credit Min Score','Credit Min Score', 0.45 ,NULL, NULL, NULL, 1, NULL,  NOW())
	,	(22, 2, 'Classification Danger Score Rule', 'CreditMaxScore', 'Credit Max Score', 'Credit Max Score', 0.95, NULL, NULL, NULL, 1, NULL,  NOW())
;
SELECT * FROM StaticList WHERE ListID = 22
;
#====Initial Category(2800, 2801)================================================================================
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate
,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit,IsProbation,ProblemCaseID,IsHedgingReasonMM,RootTaggingID
,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,OldCustomerClass,SabaSportType,SabaIntelligent_RiskLevel,SabaIntelligent_RiskLevel_TCN,SabaIntelligent_RiskLevel_SCN,SabaIntelligent_RiskLevel_CN3,SabaIntelligent_RiskLevel_THB,SabaIntelligent_RiskLevel_IND,GroupPriority)
VALUES (65,'Early Warning Members','Early Warning Members',50,199,1,0,NOW(),NULL,NULL,NULL,NULL,'预警会员',NULL,NULL,NULL,65,NULL,NULL,NULL,'AI',NULL,NULL,NULL,NULL,NULL,2800,'Dangerous','危險',2800,105,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,0,NULL,53,0,NULL,NULL,'Dangerous','危險','危险',NULL,NULL,NULL,50500)
	,(105,'Early Warning Members (Losing)','Early Warning Members (Losing)',50,199,1,0,NOW(),NULL,NULL,NULL,NULL,'预警会员 (输钱)',NULL,NULL,NULL,105,NULL,NULL,NULL,'AI',NULL,NULL,NULL,NULL,NULL,2801,'Dangerous-','危險 -',2801,65,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,1,NULL,53,1,NULL,NULL,'Dangerous','危險','危险',NULL,NULL,NULL,50500)
;
SELECT cat.IsPAProbation, cat.* FROM CustomerCategory cat WHERE CategoryID IN (65, 105)#, 54,94)
;
#====Initial ClassifiedScore, ClassifiedDate FOR Credit Customer======================================================
UPDATE Customer_DangerousScore
SET ClassifiedScore = DangerousScore
	, ClassifiedDate = LastModifiedDate
WHERE DangerousScore BETWEEN 0.45 AND 0.95
	AND IsLicensee = 0
;