/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240417@Thomas.Nguyen
Task:	 	New CC 2600/2601.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240417@Thomas.Nguyen: Created [Redmine ID: #200854]
Reviewer:
*/

USE CTS_DataCenter;

#=================================================

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,ScanIntervalInSecond,ScanTaggingIntervalInSecond,CategoryNameCN
    ,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CategoryGroup,TaggingID,TaggingType,ReasonID,SourceType,AFCFraudID,EvidenceID_Licensee,EvidenceCode_Licensee,EvidenceID_Credit,EvidenceCode_Credit,CustomerClass,CustomerClassName
    ,CustomerClassNameCN,CustomerClassException,RelevantCategoryID,ABIDangerLevel_Licensee,ABIDangerLevelException_Licensee,ABIDangerLevel_Credit,ABIDangerLevelException_Credit
    ,IsProbation,ProblemCaseID,IsHedgingReasonMM,RootTaggingID,IsPAProbation,DangerLevelType,Priority,IsDangerProbation,OldCustomerClass,SabaSportType,SabaIntelligent_RiskLevel,SabaIntelligent_RiskLevel_TCN,SabaIntelligent_RiskLevel_SCN,SabaIntelligent_RiskLevel_CN3,SabaIntelligent_RiskLevel_IND,SabaIntelligent_RiskLevel_THB,GroupPriority)
VALUES(67,'Initial Group Betting','Initial Group Betting',150,67,1,0,NOW(),NULL,NULL,NULL,0,NULL,'初始群组投注'
    ,'Cược Nhóm Khởi Đầu','การเดิมพันกลุ่มเบื้องต้น','Taruhan Grup Awal',67,NULL,NULL,67,'CTS',NULL,NULL,NULL,NULL,NULL,2600,'Dangerous'
    ,'危險',2600,107,NULL,NULL,NULL,NULL
    ,0,NULL,NULL,NULL,0,NULL,53,0,NULL,NULL,'Dangerous','危險','危险','Nguy hiểm','Berbahaya','อันตราย',15202)
 ,(107,'Initial Group Betting (Losing)','Initial Group Betting (Losing)',150,107,1,0,NOW(),NULL,NULL,NULL,0,NULL,'初始群组投注 (输钱)'
    ,'Cược Nhóm Khởi Đầu (Thua)','การเดิมพันกลุ่มเริ่มต้น (ขาดทุน)','Taruhan Grup Awal (Kalah)',107,NULL,NULL,107,'CTS',NULL,NULL,NULL,NULL,NULL,2601,'Dangerous -'
    ,'危險-',2601,67,NULL,NULL,NULL,NULL
    ,1,NULL,NULL,NULL,1,NULL,53,1,NULL,NULL,'Dangerous','危險','危险','Nguy hiểm','Berbahaya','อันตราย',15202);

SELECT * FROM CTS_DataCenter.CustomerCategory WHERE CategoryID IN (67,107);

UPDATE CustomerCategory
SET ParentID = 150
    , GroupPriority = 15200
WHERE CategoryID IN (65,105);

UPDATE CTSCustomerClassification
SET SportGroupID = 150
WHERE CategoryID IN (65,105);

SELECT * FROM CTS_DataCenter.CustomerCategory WHERE CategoryID IN (65,105);
SELECT * FROM CTS_DataCenter.CTSCustomerClassification WHERE CategoryID IN (65,105);

/*Get list Cust for init CC 2600/2601*/
CREATE TEMPORARY TABLE CustLatestCCNewGB (CustID BIGINT);
INSERT INTO CustLatestCCNewGB (CustID)
WITH CTE_CustNewGB AS (
	SELECT clss.CustID, clss.CategoryID
	FROM CTS_DataCenter.CTSCustomerClassification AS clss
	WHERE  clss.CategoryID = 239
)
, CTE_CustLatestCC AS (
    SELECT clss.CustID, clss.CategoryID
    FROM CTE_CustNewGB AS cte,
    LATERAL(SELECT clss.CustID, clss.CategoryID
            FROM CTS_DataCenter.CTSCustomerClassification AS clss
                INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID
            WHERE cte.CustID = clss.CustID
            ORDER BY  cate.Priority ASC  
                    , clss.LastModifiedDate DESC
            LIMIT 1) AS clss
)
SELECT cng.CustID
FROM CTE_CustNewGB AS cng
    INNER JOIN CTE_CustLatestCC AS clc
ON cng.CustID = clc.CustID AND cng.CategoryID = clc.CategoryID;

SELECT * FROM CustLatestCCNewGB;