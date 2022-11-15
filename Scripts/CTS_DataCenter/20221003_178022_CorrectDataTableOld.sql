/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20221003@Harvey.Nguyen
Task:	 	Change table name: CTSCustomerClassificationOldPA -> CTSCustomerClassificationOldCategory
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20221003@Harvey.Nguyen: Created [Redmine ID: #178601]
Reviewer:
*/

USE CTS_DataCenter;

#========================CHANGE TABLE NAME===============================================
ALTER TABLE CTS_DataCenter.CTSCustomerClassificationOldPA RENAME TO  CTS_DataCenter.CTSCustomerClassificationOldCategory;

#========================CORRECT DATA CTSCustomerClassificationOldCategory====================
#1. Remove Robot TW and Robot AI
/*
SELECT COUNT(1) ~44
FROM CTSCustomerClassificationOldPA AS del
WHERE del.CategoryID IN (163, 164) AND (IsFromAI = 1 OR IsFromTW = 1);
*/
DELETE del
FROM CTSCustomerClassificationOldCategory AS del
WHERE del.CategoryID IN (163, 164) AND (IsFromAI = 1 OR IsFromTW = 1);

#1. Remove Robot TW and Robot AI
/*
SELECT COUNT(1) # ~1102
FROM CTSCustomerClassificationOldPA AS del
	INNER JOIN CustomerCategory AS cc on cc.CategoryID = del.CategoryID
WHERE SportGroupID = 200 and cc.CategoryGroup not in (203, 204);*/
DELETE del
FROM CTSCustomerClassificationOldCategory AS del
	INNER JOIN CustomerCategory AS cc on cc.CategoryID = del.CategoryID
WHERE SportGroupID = 200 and cc.CategoryGroup not in (203, 204);