/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211207@Aries.Nguyen
    Task:	 	Drop column FingerprintMoreInfo, CreatedDate
    DBName:		DCS_DataCenter
*/
USE DCS_DataCenter;
ALTER TABLE DeviceFingerprint
DROP COLUMN FingerprintMoreInfo,  
DROP COLUMN CreatedDate, 
ALGORITHM=INPLACE, LOCK=NONE;