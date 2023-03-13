/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220313@Casey.Huynh
Task:	 	Betting Partenr OTGB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220313@Casey.Huynh: Created [Redmine ID: #184791]
Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE AssociationTypeDetails(
		ID INT auto_increment primary key
	,	AssGroupName VARCHAR(100)
    ,	AssTypeID	INT
	,	AssTypeName VARCHAR(100)	
    ,	AssTypeItemValue INT
    ,	AssTypeItemName VARCHAR(100)
    ,	AssTypeItemStatus TINYINT COMMENT '1: New, 2:Applied, 3: Closed'
    ,	CreatedDate	DATETIME
    ,	Comments VARCHAR(500)
    
   ,	INDEX IX_AssociationTypeSetting_AssGroup (AssGroupName)
   ,	INDEX IX_AssociationTypeSetting_AssType(AssTypeID, AssTypeItemStatus)
);

INSERT INTO AssociationTypeDetails(ID, AssGroupName, AssTypeID, AssTypeName,  AssTypeItemValue, AssTypeItemName, AssTypeItemStatus, CreatedDate, Comments)
VALUE	(1,'Association By Device',1,'AssociationByDevice',1,'Association By Device',2,CURRENT_DATE(),NULL)
	,	(2,'Betting Patern',2,'AssociationByAI',1,'OTGB',2,CURRENT_DATE(),NULL)
    ,	(3,'Association By IP',3,'AssociationByIP',1,'Association By IP',2,CURRENT_DATE(),NULL)
    ,	(4,'AssociationByManual',4,'Association By Manual',1,'Association By Manual',3,CURRENT_DATE(),NULL)
    ,	(5,'Betting Patern',5,'AssociationGroupByAI',1,'Association Group By AI',2,CURRENT_DATE(),NULL)
    ,	(6,'Betting Patern',2,'AssociationByAI',2,'5G3S',2,CURRENT_DATE(),NULL);

