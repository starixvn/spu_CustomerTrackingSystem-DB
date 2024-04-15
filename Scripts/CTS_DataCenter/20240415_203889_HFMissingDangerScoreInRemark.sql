/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20240415@Casey.Huynh
    Task:	 	Customer Classification
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20240415@Casey.Huynh: Update Remark Info for (65,105) [Redmine ID: #203889]
    Reviewer: Long.Lưu
*/
USE CTS_DataCenter;
#====Count on '2024-04-15': 47 rows========================
SELECT COUNT(1)
FROM CTSCustomerClassification AS c
INNER JOIN CTSCustomerClassification_History AS h ON c.CustID = h.CustID
INNER JOIN Customer_DangerousScore AS cd ON cd.CustID = h.CustID
WHERE c.CategoryID IN (65,105)
	AND h.CategoryID IN (65,105)
    AND h.Remark IS NULL;

#================================
UPDATE CTSCustomerClassification AS c
INNER JOIN CTSCustomerClassification_History AS h ON c.CustID = h.CustID
INNER JOIN Customer_DangerousScore AS cd ON cd.CustID = h.CustID
SET h.Remark = CONCAT('Detection Date: ', DATE_FORMAT(cd.ClassifiedDate, '%d %b, %Y'),' - Dangerous Score: ',CAST(cd.ClassifiedScore*100 AS DECIMAL(5,2)),'%')
WHERE c.CategoryID IN (65,105)
	AND h.CategoryID IN (65,105)
    AND h.Remark IS NULL;
