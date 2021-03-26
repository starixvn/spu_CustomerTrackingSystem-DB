/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210326@Irena.Vo
	Task: 	 152249-Add column IsCateChanged  [Redmine ID: #152249]
	DB: 	 CTS_DataCenter
    
     Revisions: 
	 -	[20210326@Irena.Vo]: Add column IsCateChanged
*/

USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN IsCateChanged BIT DEFAULT 0;