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
 
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,CategoryNameCN,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit,IsProbation,ProblemCaseID,IsHedgingReasonMM,RootTaggingID,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,SabaSportType,OldCustomerClass)
VALUES	(165,'Odds Crawler Robot','Odds Crawler Robot',50,165,1,0,NOW(),NULL,NULL,NULL,0,'机械爬虫',165,NULL,NULL,165,'AI',NULL,NULL,NULL,NULL,NULL,3100,'Odds Crawler Robot','机械爬虫',3100,166,NULL,NULL,NULL,NULL,0,1,NULL,13,0,2,48,0,'[2]',131)
	,	(166,'Odds Crawler Robot (Losing)','Odds Crawler Robot (Losing)',50,166,1,0,NOW(),NULL,NULL,NULL,0,'机械爬虫 (输钱)',166,NULL,NULL,166,'AI',NULL,NULL,NULL,NULL,NULL,3200,'Odds Crawler Robot','机械爬虫',3200,165,NULL,NULL,NULL,NULL,1,1,NULL,13,1,2,48,1,'[2]',132);

SELECT c.Priority, c.* FROM CustomerCategory c WHERE CategoryID IN (132,152,163,164,165,166);