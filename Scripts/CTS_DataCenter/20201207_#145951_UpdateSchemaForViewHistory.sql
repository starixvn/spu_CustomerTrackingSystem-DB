# [20201207@Irena.Vo][145951]: 
-- Insert item list for Source Type for category
INSERT INTO CTS_DataCenter.StaticList
(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES
(4,1, 'Classification Source Type','Classification Source Type','Account has less than 10 bets for first time scan','Account has less than 10 bets for first time scan',1,1,'New: New Customer',CURRENT_TIME()),
(4,2, 'Classification Source Type','Classification Source Type','Re-scan after first 10 bets','Re-scan after first 10 bets',2,1,'Other: From New To Normal,VIP/VIP,Normal,Probation,Smart,High Risk...Probation: From New To Probation,Smart,High Risk',CURRENT_TIME()),
(4,3, 'Classification Source Type','Classification Source Type','Re-scan on Schedule Date','Re-scan on Schedule Date',3,1,'Other: From Normal,VIP To VIP,Normal/ From Probation To Normal,VIP/ From Smart,High Risk To High Risk,Smart...Probation: From Normal,VIP To Probation,Smart,High Risk',CURRENT_TIME()),
(4,4, 'Classification Source Type','Classification Source Type','Pass 20 days Probation','Pass 20 days Probation',4,1,'Other: From Probation To Smart,High Risk',CURRENT_TIME()),
(4,5, 'Classification Source Type','Classification Source Type','Cannot pass Probation','Cannot pass Probation',5,1,'Probation: From Probation To Probation',CURRENT_TIME()),
(4,6, 'Classification Source Type','Classification Source Type','Add from NAP CM','Add from NAP CM',6,1,'From NapCM',CURRENT_TIME()),
(4,7, 'Classification Source Type','Classification Source Type','Add from Evidence','Add from Evidence',7,1,'From Evidence',CURRENT_TIME()),
(4,8, 'Classification Source Type','Classification Source Type','Manual Remove Problem Account','Manual Remove Problem Account',8,1,'From PA',CURRENT_TIME()),
(4,9, 'Classification Source Type','Classification Source Type','Manual Add Customer Class','Manual Add Customer Class',9,1,'From Special CC',CURRENT_TIME()),
(4,10, 'Classification Source Type','Classification Source Type','Change Customer Class by Robot Icon','Change Customer Class by Robot Icon',10,1,'From Robot',CURRENT_TIME()),
(4,11, 'Classification Source Type','Classification Source Type','Manual Remove Customer Class','Manual Remove Customer Class',11,1,'From CC',CURRENT_TIME()),
(4,12, 'Classification Source Type','Classification Source Type','Manual Add VVIP','Manual Add VVIP',12,1,'From VVIP',CURRENT_TIME()),
(4,13, 'Classification Source Type','Classification Source Type','Manual Remove VVIP','Manual Remove VVIP',13,1,'From VVIP',CURRENT_TIME())
;

-- Insert new table PinCustomerCategory
    DROP TABLE IF EXISTS CTS_DataCenter.PinCustomerCategory;
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.PinCustomerCategory (
			CustID 				BIGINT		UNSIGNED	NOT NULL PRIMARY KEY
		, 	CreatedTime 		DATETIME    NOT NULL
	) ENGINE=INNODB;

-- Insert new table for mapping Category to CC
DROP TABLE IF EXISTS CTS_DataCenter.CategoryToCustomerClass;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CategoryToCustomerClass(
			CategoryID			SMALLINT UNSIGNED
		, 	CustomerClass		SMALLINT UNSIGNED
        , 	PRIMARY KEY			PK_CategoryToCustomerClass_CategoryID_CustomerClass(CategoryID,CustomerClass)
        , 	INDEX				IX_CategoryToCustomerClass_CategoryID_CustomerClass(CategoryID,CustomerClass)
) ENGINE=INNODB;

INSERT INTO CTS_DataCenter.CategoryToCustomerClass(CategoryID,CustomerClass)
SELECT cc.CategoryID
       , CASE     -- New Member
                  WHEN cc.CategoryID = 201 THEN 3
				  -- VVIP
                  WHEN cc.CategoryID = 213 THEN 100
                  -- Problem Accounts
				  WHEN cc.CategoryID IN (52, 72, 152) THEN 8
                  WHEN cc.CategoryID IN (54, 58, 74, 78, 154, 158) THEN 9
                  WHEN cc.CategoryID IN (53, 55, 59, 73, 75, 79, 153, 155, 159) THEN 10
                  WHEN cc.CategoryID IN (56, 60, 76, 80, 156) THEN 11
				  WHEN cc.CategoryID IN (57, 157) THEN 13
                  -- Normal Accounts
                  WHEN cc.CategoryID = 205 THEN 1
                  WHEN cc.CategoryID = 202 THEN 2
                  WHEN cc.CategoryID = 206 THEN 5
                  WHEN cc.CategoryID = 203 THEN 6
                  WHEN cc.CategoryID = 204 THEN 7
		  END AS CustomerClass
FROM CTS_DataCenter.CustomerCategory AS cc
WHERE cc.ParentID IN (50, 200) AND cc.CategoryID NOT IN (51, 151, 160);

-- Insert new column in History
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN TargetCC TINYINT, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN SourceTypeID SMALLINT UNSIGNED, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN LastXDaysMargin DECIMAL(20,4), ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN ProbationPeriodWinloss DECIMAL(20,4), ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN FromCategoryID SMALLINT UNSIGNED, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN ToCategoryID SMALLINT UNSIGNED, ALGORITHM=INSTANT;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN IsAppliedCC BIT DEFAULT 0, ALGORITHM=INSTANT;