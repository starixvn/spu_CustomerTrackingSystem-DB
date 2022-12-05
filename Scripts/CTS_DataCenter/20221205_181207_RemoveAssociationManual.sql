/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20221205@Aries.Nguyen
	Task: Re-arrange type options on Association Detection
	DB: CTS_DataCenter
  
	Revisions:
		- 20221205@Aries.Nguyen: created  [Redmine ID: #181207]
*/
USE CTS_Archive;
SHOW CREATE TABLE AssociationByManual_Arc;
RENAME TABLE AssociationByManual_Arc TO AssociationByManual_Arc_BK;    
# Execute create table


USE CTS_DataCenter;
SHOW CREATE TABLE AssociationByManual;
RENAME TABLE AssociationByManual TO AssociationByManual_BK;
# Execute create table
     
