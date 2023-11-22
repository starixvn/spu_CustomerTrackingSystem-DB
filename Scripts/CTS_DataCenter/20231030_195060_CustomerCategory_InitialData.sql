/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231030@Tony.Nguyen
Task:	 	New category for new member scanned tagging
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231030@Tony.Nguyen: Initial Writing [Redmine ID: #195060]

*/

USE CTS_DataCenter;

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,ScanTaggingIntervalInSecond,CategoryNameCN,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit,IsProbation,ProblemCaseID,IsHedgingReasonMM,RootTaggingID,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,OldCustomerClass,SabaSportType,SabaIntelligent_RiskLevel,SabaIntelligent_RiskLevel_TCN,SabaIntelligent_RiskLevel_SCN)
VALUES(239,'New Group Betting','New Member',200,99,1,0,NOW(),NULL,NULL,NULL,0,NULL,'新群组投注玩家',201,9,2,99,NULL,NULL,NULL,NULL,NULL,NULL,2300,'Dangerous -','危險-',2300,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,0,1,60,0,NULL,NULL,'Dangerous','危險','危险');

INSERT INTO TaggingToCategory(CategoryID,TaggingID,TaggingType,CategoryGroup)
VALUES(239,9,2,201);