/*
Creator: 	20200603@Casey.Huynh
Task:	 	CTS_Schema
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 

        - [20200603@Casey.Huynh][135324]: 
			+ Alter Table CTSCustomerClassification, add column LastScannedDate
            + Alter table CTS_DataCenter.CustomerCategory: Add ScanIntervalInSecond
Reviewer:
*/

ALTER TABLE CTS_DataCenter.CTSCustomerClassification
ADD COLUMN LastScannedDate DATETIME;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification
ADD COLUMN 	CustID	INT UNSIGNED;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification
ADD INDEX IX_CTSCustomerClassification_LastScannedDate(LastScannedDate);

ALTER TABLE CTS_DataCenter.CTSCustomerClassification
ADD INDEX IX_CTSCustomerClassification_CategoryID(CategoryID);

ALTER TABLE CTS_DataCenter.CTSCustomerClassification
ADD INDEX IX_CTSCustomerClassification_CustID(CustID);

ALTER TABLE	CTS_DataCenter.CustomerCategory
ADD COLUMN  ScanIntervalInSecond BIGINT;

/************Initial CustomerCategory.SecondSchedule***************/
INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID, CategoryName, CategorySpec, ParentID, DisplayOrder, IsActive, CreatedDate, IsUsedManually)
VALUES(10, 'Probation', 'Probation', 1, 9, 1, Current_Date(), 0);

UPDATE CTS_DataCenter.CustomerCategory
SET IntervalScanSecond = 	(CASE	WHEN CategoryID = 4 	THEN 1209600	#Normal Member 2 week
									WHEN CategoryID = 5 	THEN 604800		#VIP 1 week
									WHEN CategoryID = 6 	THEN 604800		#Smart Punter 1 week
									WHEN CategoryID = 7 	THEN 604800		#High Risk Punter 1 week
									WHEN CategoryID = 10 	THEN 604800		#Probation 1 week
							END
						);

