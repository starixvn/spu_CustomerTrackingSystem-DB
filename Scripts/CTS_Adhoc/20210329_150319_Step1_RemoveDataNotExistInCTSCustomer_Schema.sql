/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
		Created: John.Ngo
		Task:	 Remove data from tables which is not existing in CTSCustomer
		DB: 	 CTS_Adhoc

		Revisions:
				- 20210329@John.Ngo: Created [Redmine ID: 150319]
*/
USE CTS_Adhoc;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_SpecialCustomerClass;
CREATE TABLE CTS_Adhoc.BK150319_SpecialCustomerClass LIKE CTS_DataCenter.SpecialCustomerClass;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_ProbationAccountMonitor;
CREATE TABLE CTS_Adhoc.BK150319_ProbationAccountMonitor LIKE CTS_DataCenter.ProbationAccountMonitor;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_CTSCustomerClassification;
CREATE TABLE CTS_Adhoc.BK150319_CTSCustomerClassification LIKE CTS_DataCenter.CTSCustomerClassification;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_CTSCustomerClassification_History;
CREATE TABLE CTS_Adhoc.BK150319_CTSCustomerClassification_History LIKE CTS_DataCenter.CTSCustomerClassification_History;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_CustEvidence;
CREATE TABLE CTS_Adhoc.BK150319_CustEvidence LIKE CTS_DataCenter.CustEvidence;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_CustDCSAccount;
CREATE TABLE CTS_Adhoc.BK150319_CustDCSAccount LIKE CTS_DataCenter.CustDCSAccount;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_AssociationByDevice;
CREATE TABLE CTS_Adhoc.BK150319_AssociationByDevice LIKE CTS_DataCenter.AssociationByDevice;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_Account;
CREATE TABLE CTS_Adhoc.BK150319_Account LIKE DCS_DataCenter.Account;

DROP TABLE IF EXISTS CTS_Adhoc.BK150319_Parameter;
CREATE TABLE IF NOT EXISTS CTS_Adhoc.BK150319_Parameter (
		ID				SMALLINT AUTO_INCREMENT NOT NULL PRIMARY KEY
    ,	TableName		VARCHAR(200)
    ,	MinID			BIGINT
	,	MaxID			BIGINT
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

INSERT INTO `CTS_Adhoc`.`BK150319_Parameter` (`TableName`, `MinID`, `MaxID`)
VALUES ('ProbationAccountMonitor', '0', '0')
	,  ('CTSCustomerClassification', '0', '0')
	,  ('CTSCustomerClassification_History', '0', '0')
	,  ('CustEvidence', '0', '0')
	,  ('CustDCSAccount', '0', '0')
	,  ('SpecialCustomerClass', '0', '0')
	,  ('AssociationByDevice', '0', '0')
	,  ('Account', '0', '0');