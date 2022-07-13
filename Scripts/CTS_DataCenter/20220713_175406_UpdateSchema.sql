/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220713@Aries.Nguyen
    Task:	 	20220713@Aries.Nguyen: HotFix Customer NULL CC [Redmine ID: #175406]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE ArchiveCustomer_CTSCustomer 
ADD COLUMN IsReactivated BIT DEFAULT 0, 
ADD COLUMN ReactivateDate DATETIME,
ADD COLUMN ProcessedDate DATETIME,
ALGORITHM=INSTANT;


