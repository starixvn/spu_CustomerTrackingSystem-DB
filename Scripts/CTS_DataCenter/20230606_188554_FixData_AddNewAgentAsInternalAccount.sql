/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230606@Long.Luu
	Task:	 	Fix Data - Add New Agent As Internal Account
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230606@Long.Luu: 	Fix Data - Add New Agent As Internal Account [Redmine ID: #188554]

*/	
	
SET SQL_SAFE_UPDATES = 0;

# Update IsInternal attr
UPDATE CTSCustomer
SET IsInternal = 1
WHERE Recommend = 27787409;

# Remove internal's account Category & push CC NULL
DROP TABLE IF EXISTS Adhoc_InternalAccount;	
CREATE TABLE Adhoc_InternalAccount
(
		CustID		BIGINT UNSIGNED	PRIMARY KEY
	,	CTSCustID	BIGINT UNSIGNED
);

INSERT INTO Adhoc_InternalAccount(CustID)
SELECT CustID
FROM CTSCustomer
WHERE Recommend = 27787409;

DELETE a
FROM CTSCustomer AS c
	INNER JOIN CTSCustomerClassification AS a ON c.Recommend = 27787409 AND c.CustID = a.CustID;
    
DELETE a
FROM CTSCustomer AS c
	INNER JOIN CTSCustomerClassification_History AS a ON c.Recommend = 27787409 AND c.CustID = a.CustID;

DELETE a
FROM CTSCustomer AS c
	INNER JOIN CTSCustomerClassification_BySport AS a ON c.Recommend = 27787409 AND c.CustID = a.CustID;
    
DELETE a
FROM CTSCustomer AS c
	INNER JOIN CTSCustomerClassification_BySport_History AS a ON c.Recommend = 27787409 AND c.CustID = a.CustID;
#select * from CTSCustomerClassification_InputDataLog;    
# Remove Association
DELETE a
FROM Adhoc_InternalAccount AS c
	INNER JOIN AssociationByAI AS a ON c.CustID = a.FromCustID;    
DELETE a
FROM Adhoc_InternalAccount AS c
	INNER JOIN AssociationByAI AS a ON c.CustID = a.ToCustID;

DELETE a
FROM Adhoc_InternalAccount AS c
	INNER JOIN AssociationByDevice AS a ON c.CTSCustID = a.CTSCustID;

DELETE a
FROM Adhoc_InternalAccount AS c
	INNER JOIN AssociationByIP AS a ON c.CustID = a.FromCustID;
DELETE a
FROM Adhoc_InternalAccount AS c
	INNER JOIN AssociationByIP AS a ON c.CustID = a.ToCustID;

DELETE a
FROM Adhoc_InternalAccount AS c
	INNER JOIN AssociationGroupByAI AS a ON c.CustID = a.CustID;




/*
select count(1) from AssociationRemove;
select * from AssociationRemove AS a inner join Adhoc_InternalAccount AS b ON a.FromCTSCustID = b.CTSCustID;
select * from AssociationRemove AS a inner join Adhoc_InternalAccount AS b ON a.ToCTSCustID = b.CTSCustID;
*/




