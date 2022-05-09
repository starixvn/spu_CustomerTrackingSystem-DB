/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220905@Aries.Nguyen
Task:	 	CTS - Robot Classification - Wrong mapping to push CC and ABI Danger [Redmine ID: 172497] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
UPDATE  CTS_DataCenter.CustomerCategory
SET CustomerClassException = 13,
    ABIDangerLevelException_Credit = 6,
    ABIDangerLevelException_Licensee = 16
WHERE CategoryID = 164;