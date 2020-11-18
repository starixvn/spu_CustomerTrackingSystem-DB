/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 20201018@Aries.Nguyen
Task: Add InsertedTime, ModifiedTime columns to CTSCustomer table.
DB: CTS_DataCenter
*/
USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSCustomer ADD COLUMN InsertedTime DATETIME(4) COMMENT "When row inserted", ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.CTSCustomer ADD COLUMN ModifiedTime DATETIME(4) COMMENT "When row modified", ALGORITHM=INSTANT;
