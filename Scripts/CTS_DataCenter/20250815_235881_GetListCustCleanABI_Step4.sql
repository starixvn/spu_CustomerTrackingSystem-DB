/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250815@Thomas.Nguyen
Task:	 	Insert cust need to correct ABI into Adhoc_HF235881_CustNeedToUpdateABI
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250815@Thomas.Nguyen: Created [Redmine ID: #235881]
Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.Adhoc_HF235881_CustNeedToUpdateABI (CustID, UserName, ABI, GroupID, Created)
SELECT cus.CustID, cus.UserName, cus.Danger2 AS ABI, ad.GroupID, ad.Created
FROM CTS_DataCenter.Adhoc_HF235881_AssociatedGroupAccount_Clean AS ad
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ad.CTSCustID
	INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON ag.GroupID = ad.GroupID
WHERE ag.ABI = cus.Danger2
GROUP BY cus.CustID, cus.UserName, ad.GroupID, cus.Danger2, ad.Created;

/*SELECT CustID, ABI as danger2
FROM Adhoc_HF235881_CustNeedToUpdateABI;*/