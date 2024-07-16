/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240530@Thomas.Nguyen
Task:	 	New CC 2700/2701.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240530@Thomas.Nguyen: Created [Redmine ID: #199345]
Reviewer:
*/

USE CTS_DataCenter;

#=================================================
CREATE TABLE Customer_InitialSmart (
    CustID BIGINT UNSIGNED NOT NULL PRIMARY KEY
,   Probability DECIMAL(8,4)
,   PredictTime DATETIME(3)
,   InsertedTime DATETIME(3)
,   KEY IX_Customer_InitialSmart_InsertedTime_CustID (InsertedTime,CustID);
);

/*For tracking when receiving duplicate cust */
CREATE TABLE Customer_InitialSmart_Log (
    ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
,   CustID BIGINT UNSIGNED NOT NULL
,   Probability DECIMAL(8,4)
,   PredictTime DATETIME(3)
,   InsertedTime DATETIME(3) 
,   KEY IX_Customer_InitialSmart_Log_CustID (CustID)
);

INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(159,'InitialSmart_LastScanCustID','InitialSmart_LastScanCustID','INT',0);

INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(160,'InitialSmart_LastScanDate','InitialSmart_LastScanDate','DATETIME(3)',CURRENT_TIMESTAMP(3));

INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(161,'InitialSmart_BatchSize','InitialSmart_BatchSize','INT',1000);

SELECT * FROM CTS_DataCenter.SystemParameter WHERE ParameterID IN (159,160,161);


INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,ScanTaggingIntervalInSecond,CategoryNameCN
    ,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName
    ,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit
    ,IsProbation,ProblemCaseID,IsHedgingReasonMM,RootTaggingID,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,OldCustomerClass,SabaSportType,SabaIntelligent_RiskLevel,SabaIntelligent_RiskLevel_TCN,SabaIntelligent_RiskLevel_SCN,SabaIntelligent_RiskLevel_CN3,SabaIntelligent_RiskLevel_IND,SabaIntelligent_RiskLevel_THB,GroupPriority)
VALUES(66,'Initial Smart','Initial Smart',150,66,1,0,NOW(),NULL,NULL,NULL,0,NULL,'初始精明玩家'
    ,'Cược Thông Minh','นักเดิมพันฉลาดเบื้องต้น','Pemain Pintar Awal',66,NULL,NULL,66,'CTS',NULL,NULL,NULL,NULL,NULL,2700,'Dangerous'
    ,'危險',2700,106,NULL,NULL,NULL,NULL
    ,0,NULL,NULL,NULL,0,NULL,53,0,NULL,NULL,'Dangerous','危險','危险','Nguy hiểm','Berbahaya','อันตราย',15201)
 ,(106,'Initial Smart (Losing)','Initial Smart (Losing)',150,106,1,0,NOW(),NULL,NULL,NULL,0,NULL,'初始精明玩家 (输钱)'
    ,'Cược Thông Minh (Thua)','นักเดิมพันฉลาดเริ่มต้น (ขาดทุน)','Pemain Pintar Awal (Kalah)',106,NULL,NULL,106,'CTS',NULL,NULL,NULL,NULL,NULL,2701,'Dangerous -'
    ,'危險-',2701,66,NULL,NULL,NULL,NULL
    ,1,NULL,NULL,NULL,1,NULL,53,1,NULL,NULL,'Dangerous','危險','危险','Nguy hiểm','Berbahaya','อันตราย',15201);

SELECT * FROM CTS_DataCenter.CustomerCategory WHERE CategoryID IN (66,106);

INSERT INTO SPU_Stats.Function(FunctionId,FunctionName,SystemId) VALUES(244,'AddCustomerInitialSmarts',2);