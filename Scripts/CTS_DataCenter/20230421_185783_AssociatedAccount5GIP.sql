/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230421@Casey.Huynh
Task:	 	AssociatedAccount5GIP
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230421@Casey.Huynh: Created [Redmine ID: #185783]          
Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.AssociationTypeSetting(ID, AssGroupName, AssTypeID, AssTypeName, AssTypeItemValue, AssTypeItemName, AssTypeItemStatus, CreatedDate)
SELECT 7, 'Association By IP', 3, 'AssociationByIP', 2, '5GIP', 1, NOW();

SELECT * FROM CTS_DataCenter.AssociationTypeSetting AS atd;

