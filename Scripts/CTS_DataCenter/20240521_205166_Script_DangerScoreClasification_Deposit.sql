/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20240521@Victoria.Le
    Task:	 	Danger Score - Deposit
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20240521@Victoria.Le: Schema and Innit Data [Redmine ID: #205166]
    Reviewer: 
*/
USE CTS_DataCenter;


/*** Schema ****/

UPDATE Customer_DangerousScore AS ds
	INNER JOIN CTSCustomer AS cus ON cus.CustID = ds.CustID 
SET 	ds.ClassifiedScore 	= ds.DangerousScore
	, 	ds.ClassifiedDate 	= ds.LastModifiedDate
WHERE ds.DangerousScore >= 0.91 AND ds.IsLicensee = 1 AND cus.IsLicensee = 1
;



/*** Initial Data ****/
INSERT INTO StaticList(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, ItemValue, ItemDefaultValue, ItemParentItemID, PriorityOrder, Status, Description, CreatedDate)
VALUES	(22, 3, 'Classification Dangerous Score Rule', 'DepositMinDangerousScore', 'Deposit Min Dangerous Score','Deposit Min Dangerous Score', 0.91 ,NULL, NULL, NULL, 1, NULL,  NOW())
;

SELECT * FROM StaticList WHERE ListID = 22;

INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(156, 'ClassificationDangerousScoreDeposit_LastDate','Customer_DangerousScore.LastModifiedDate', 'DATETIME(3)', '2023-08-23')
	,	(157, 'ClassificationDangerousScoreDeposi_LastCustID','Customer_DangerousScore.CustID', 'INT', '0')
    ,	(158, 'ClassificationDangerousScoreDeposi_BatchSize',NULL, 'INT', '1000')
;

select * from SystemParameter where ParameterID in (156,157,158);