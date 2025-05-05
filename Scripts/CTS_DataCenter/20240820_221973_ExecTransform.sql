/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
Creator:	20250409@Casey.Huynh
Task:	 	Exec Manual Transform
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250409@Casey.Huynh: Created [Redmine ID: #221973]
Reviewer:
*/
USE CTS_Adhoc;


SELECT NOW() AS StartTransformAccount;

CALL CTS_Adhoc.CTS_DC_DCSTransform_MBAccount_Manualy(1000);

SELECT NOW() AS EndTransformAccount;

#========================================================
SELECT NOW() AS StartTransformAssociation;

CALL CTS_Adhoc.CTS_DC_DCSTransform_MBAssociation_Manualy(1000);

SELECT NOW() AS EndTransformAssociation;