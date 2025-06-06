/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250529@Thomas.Nguyen
Task:	 	Insert cust need to correct ABI into Adhoc_HF222541_CustNeedToUpdateABI
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250529@Thomas.Nguyen: Created [Redmine ID: #222541]
Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.Adhoc_HF222541_CustNeedToUpdateABI (CustID, UserName, ABI, GroupID, Created)
SELECT cus.CustID, cus.UserName, cus.Danger2 AS ABI, ad.GroupID, ad.Created
FROM CTS_DataCenter.Adhoc_HF222541_AssociatedGroupAccount_Clean AS ad
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ad.CTSCustID
	INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON ag.GroupID = ad.GroupID
WHERE ag.ABI = cus.Danger2
GROUP BY cus.CustID, cus.UserName, ad.GroupID, cus.Danger2, ad.Created;

/*SELECT CustID
FROM Adhoc_HF222541_CustNeedToUpdateABI;*/