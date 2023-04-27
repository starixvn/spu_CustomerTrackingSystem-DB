/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230421@Casey.Huynh
Task:	 	Associated Account 5GIP
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230421@Casey.Huynh: Created [Redmine ID: #185783]          
Reviewer:
*/

USE CTS_DataCenter;
#==================================================================================================
ALTER TABLE AssociationByIP
		ADD AssType SMALLINT UNSIGNED AFTER ID
	,	DROP INDEX UX_AssociationByIP_FromCustIDToCustID
    ,	ADD UNIQUE KEY UX_AssociationByIP_FromCustIDToCustIDAssType(FromCustID,ToCustID,AssType)
    ,	ADD INDEX IX_AssociationByIP_AssType(AssType);
    
#=====Update AssType flow Profile Get 1:Device, 2:Ai, 3:Manual, 4:IP
UPDATE CTS_DataCenter.AssociationTypeSetting AS ats
SET ats.AssTypeID = 3
WHERE ats.ID = 4;

UPDATE CTS_DataCenter.AssociationTypeSetting AS ats
SET ats.AssTypeID = 4
WHERE ats.ID = 3;

INSERT INTO CTS_DataCenter.AssociationTypeSetting(ID, AssGroupName, AssTypeID, AssTypeName, AssTypeItemValue, AssTypeItemName, AssTypeItemStatus, CreatedDate)
SELECT 7, 'Association By IP', 4, 'AssociationByIP', 2, '5GIP', 1, NOW();


