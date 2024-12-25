/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241225@Jonas.Huynh	
Task:	 	HF - Correct Inactive Category
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241225@Jonas.Huynh: Created [Redmine ID: #215615]

*/
USE CTS_DataCenter;

#1. Update CategoryID (Table CCMain) = OldCategoryID (CCHistory)
CALL CTS_DC_Adhoc_CorrectInactiveCategory();

#2. Get cust to rescan 
SELECT DISTINCT CustID 
FROM CTS_DataCenter.Adhoc_CC_Inactive_Incorrect AS adh
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON cc.CustID = adh.CustID
WHERE cc.CategoryID IN (40400,40401,40402,40403,40404,40405,40406,40500,40501,40502,40503,40504,40505,40506,40600,40601,40602,40603,40604,40605,40606);

#3. Rescan Metaverse
