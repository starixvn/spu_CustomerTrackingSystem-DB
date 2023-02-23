/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
    Creator: 	20230116@Victoria.Le
    Task:	    CTSCustomer: Add columns AssType for table AssociationByAI_Arc[Redmine ID: #181994]
    DBName:		CTS_Archive
*/

USE CTS_Archive;

ALTER TABLE CTS_Archive.AssociationByAI_Arc 
ADD COLUMN AssType SMALLINT UNSIGNED DEFAULT NULL AFTER ID;

