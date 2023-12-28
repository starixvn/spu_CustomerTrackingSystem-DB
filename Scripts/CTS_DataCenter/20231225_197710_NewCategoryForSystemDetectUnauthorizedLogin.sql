/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231225@Thomas.Nguyen
Task:	 	new CC 305/3005 System Detect Unauthorized Login.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231225@Thomas.Nguyen: Created [Redmine ID: #197710]
Reviewer:
*/

USE CTS_DataCenter;

#=================================================
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(147,'UnauthorizedLogin_LastScanCustID_Credit','UnauthorizedLogin_LastScanCustID_Credit','INT',0);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(148,'UnauthorizedLogin_LastScanCustID_Licensee','UnauthorizedLogin_LastScanCustID_Licensee','INT',0);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(149,'UnauthorizedLogin_LastScanDate_Credit','UnauthorizedLogin_LastScanDate_Credit','DATE',NULL);

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(150,'UnauthorizedLogin_LastScanDate_Licensee','UnauthorizedLogin_LastScanDate_Licensee','DATE',NULL);

SELECT * FROM CTS_DataCenter.SystemParameter WHERE ParameterID IN (147,148,149,150);


INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,ScanTaggingIntervalInSecond,CategoryNameCN
    ,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName
    ,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit
    ,IsProbation,ProblemCaseID,IsHedgingReasonMM,RootTaggingID,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,OldCustomerClass,SabaSportType,SabaIntelligent_RiskLevel,SabaIntelligent_RiskLevel_TCN,SabaIntelligent_RiskLevel_SCN,SabaIntelligent_RiskLevel_CN3,SabaIntelligent_RiskLevel_IND,SabaIntelligent_RiskLevel_THB)
VALUES(64,'System Detect Unauthorized Login','System Detect Unauthorized Login',50,64,1,0,NOW(),NULL,NULL,NULL,0,NULL,'系统侦测軟件登入'
    ,'Hệ thống Cảnh Báo Đăng Nhập Bất Thường','ระบบแจ้งเตือนการเข้าสู่ระบบที่ไม่ปกติ','Sistem Peringatan Login Tidak Biasa',64,NULL,NULL,64,'CTS',NULL,NULL,NULL,NULL,NULL,305,'Problems'
    ,'问题',305,104,NULL,NULL,NULL,NULL
    ,0,4,NULL,NULL,0,2,42,0,NULL,NULL,'Problems','問題','问题','Vấn đề','Masalah','ปัญหา')
 ,(104,'System Detect Unauthorized Login (Losing)','System Detect Unauthorized Login (Losing)',50,104,1,0,NOW(),NULL,NULL,NULL,0,NULL,'系统侦测軟件登入（输钱）'
    ,'Hệ thống Cảnh Báo Đăng Nhập Bất Thường (Thua)','ระบบแจ้งเตือนการเข้าสู่ระบบที่ไม่ปกติ (แพ้)','Sistem Peringatan Login Tidak Biasa (Kalah)',104,NULL,NULL,104,'CTS',NULL,NULL,NULL,NULL,NULL,3005,'Problems -'
    ,'问题 -',3005,64,NULL,NULL,NULL,NULL
    ,1,4,NULL,NULL,1,2,42,1,NULL,NULL,'Problems','問題','问题','Vấn đề','Masalah','ปัญหา');

SELECT * FROM CTS_DataCenter.CustomerCategory WHERE CategoryID IN (64,104);

SET @CreatedDate := NOW();

INSERT INTO StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES 
	(4,39,'Classification Source Type','Classification Source Type','System Detect Unauthorized Login','System Detect Unauthorized Login',NULL,NULL,NULL,39,1,'System Detect Unauthorized Login',@CreatedDate);

SELECT * FROM StaticList WHERE ListID = 4 AND ItemID = 39;