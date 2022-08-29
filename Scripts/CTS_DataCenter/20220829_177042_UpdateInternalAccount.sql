/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220829@Aries.Nguyen
    Task:	 	Remove hard-coding of internal account in CTS [Redmine ID: #177042]
    DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;

UPDATE CTSCustomer
SET IsInternal = 1
WHERE  SRecommend IN (41430709) 
	AND IsInternal = 0;

UPDATE CTSCustomer
SET IsInternal = 1
WHERE  MRecommend IN (27899314, 11656504, 12146012) 
	AND RoleID IN (1,2)  
    AND IsInternal = 0;

UPDATE CTSCustomer
SET IsInternal = 1
WHERE Recommend IN (52466,5707545,29270764,134456) 
	AND RoleID = 1  
    AND IsInternal = 0;



