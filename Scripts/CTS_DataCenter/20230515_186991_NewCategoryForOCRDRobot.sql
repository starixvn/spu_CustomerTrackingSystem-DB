/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230515@Casey.Huynh
Task:	 	new category for OCRD
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230515@Casey.Huynh: Created [Redmine ID: #186991]
Reviewer:
*/

USE CTS_DataCenter;

#=================================================
ALTER TABLE RobotDetection
		DROP PRIMARY KEY 
    ,	ADD ID BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY
    ,	ADD UNIQUE KEY UK_RobotDetection_CustIDPeriodRangeType(CustID,PeriodRangeType);
    
ALTER TABLE RobotImperva
		DROP PRIMARY KEY 
    ,	ADD PRIMARY KEY(LogID)
    ,	DROP COLUMN IsScanned
    ,	ADD UNIQUE KEY UK_RobotDetection_CustIDPeriodRangeType(CustID,Platform);
 
SET @MaxID = (SELECT MAX(ID) FROM CTS_DataCenter.RobotDetection);

SET @MaxLogID = (SELECT MAX(LogID) FROM CTS_DataCenter.RobotImperva);

UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = @MaxID
	, ParameterName = 'BettingService_RobotDetection_LastID'
    , ParameterDesc = 'Last RobotDetection.ID'
    , ParameterDataType = 'BIGINT UNSIGNED'
WHERE ParameterID = 94;

UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = @MaxLogID
	, ParameterName = 'BettingService_RobotImperva_LastID'
    , ParameterDesc = 'Last RobotImperva.LogID'
    , ParameterDataType = 'BIGINT UNSIGNED'
WHERE ParameterID = 134;

SELECT * FROM CTS_DataCenter.SystemParameter WHERE ParameterID IN (94,134);

DROP PROCEDURE CTS_DC_RobotImperva_Transform_Update;

#===========================================
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,CategoryNameCN,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit,IsProbation,ProblemCaseID,IsHedgingReasonMM
	, RootTaggingID,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,SabaSportType,OldCustomerClass,SabaIntelligent_RiskLevel,SabaIntelligent_RiskLevel_TCN,SabaIntelligent_RiskLevel_SCN)
VALUES	(165,'Odds Crawler Robot','Odds Crawler Robot',50,165,1,0,NOW(),NULL,NULL,NULL,0,'机械爬虫',165,NULL,NULL,165,'AI',NULL,NULL,NULL,NULL,NULL,3100,'Robot','機械',3100,166,NULL,NULL,NULL,NULL,0,1,NULL,13,0,2,45,0,'[2]',131,'Robot','機械','机械')
	,	(166,'Odds Crawler Robot (Losing)','Odds Crawler Robot (Losing)',50,166,1,0,NOW(),NULL,NULL,NULL,0,'机械爬虫 (输钱)',166,NULL,NULL,166,'AI',NULL,NULL,NULL,NULL,NULL,3200,'Robot','機械',3200,165,NULL,NULL,NULL,NULL,1,1,NULL,13,1,2,45,1,'[2]',132,'Robot','機械','机械');

SELECT c.Priority, c.* FROM CustomerCategory c WHERE CategoryID IN (132,152,163,164,165,166);