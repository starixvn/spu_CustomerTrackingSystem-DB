/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240129@Jonathan.Doan
	Task:	 	Truncate data [Redmine ID: #200335]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20240129@Jonathan.Doan: Truncate data [Redmine ID: #200335]
	Reviewer:
*/
USE DCS_DataCenter;

TRUNCATE TABLE FPDevice;
TRUNCATE TABLE FPDeviceFingerPrint;
TRUNCATE TABLE DeviceCookie;
TRUNCATE TABLE AccountFingerprint;
TRUNCATE TABLE EvolvedTransaction;
TRUNCATE TABLE AssociationMapping;