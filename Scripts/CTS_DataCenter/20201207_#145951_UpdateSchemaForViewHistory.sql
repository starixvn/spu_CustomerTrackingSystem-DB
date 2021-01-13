/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201207@Irena.Vo
	Task: 	 145951-Update schema for View History  [Redmine ID: #145951]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20201207@Irena.Vo]: Update index in table: CTSCustomerClassification_History & Insert new columns
*/
USE CTS_DataCenter;
-- Insert new column in Classification History
-- Column
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN TargetCC TINYINT, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN SourceTypeID SMALLINT UNSIGNED, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN IsAppliedCC BIT DEFAULT 0, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN LastXDaysMargin DECIMAL(20,4), ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN ProbationPeriodWinloss DECIMAL(20,4), ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN FromCategoryID SMALLINT UNSIGNED, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN ToCategoryID SMALLINT UNSIGNED, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN IsDataChanged BIT DEFAULT 0, ALGORITHM=INSTANT;

-- Index
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
DROP INDEX IX_CTSCustomerClassification_History_LastModifiedDate;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD INDEX IX_CTSCustomerClassification_CTSCustID(CTSCustID), ALGORITHM=INPLACE, LOCK=NONE;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD INDEX IX_CTSCustomerClassification_History_InsertDate(InsertDate), ALGORITHM=INPLACE, LOCK=NONE;