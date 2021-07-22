/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210630@Long.Luu
	Task: 	 157203 - Update Index Name
	DB: 	 CTS_DataCenter
    
    Revisions: 
		- 20210601@Aries.Nguyen: Update Index Name
*/
USE CTS_DataCenter
ALTER TABLE CTSCustomer RENAME INDEX IX_CTSCustomer_04062020_UserName2  TO IX_CTSCustomer_UserName2;