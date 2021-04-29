/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Created:	20210426@John.Ngo
	Task:		Remove Duplicate Customer [Redmine ID: #153283]
	DB:			CTS_Adhoc

	Revisions:
		- 20210426@John.Ngo: Created [Redmine ID: #153283]
*/

USE CTS_Adhoc;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CTSCustomer;
CREATE TABLE CTS_Adhoc.BK153283_CTSCustomer LIKE CTS_DataCenter.CTSCustomer;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CustDCSAccount;
CREATE TABLE CTS_Adhoc.BK153283_CustDCSAccount LIKE CTS_DataCenter.CustDCSAccount;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociationByDevice;
CREATE TABLE CTS_Adhoc.BK153283_AssociationByDevice LIKE CTS_DataCenter.AssociationByDevice;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociationByManual;
CREATE TABLE CTS_Adhoc.BK153283_AssociationByManual LIKE CTS_DataCenter.AssociationByManual;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociationByAI;
CREATE TABLE CTS_Adhoc.BK153283_AssociationByAI LIKE CTS_DataCenter.AssociationByAI;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociationByIP;
CREATE TABLE CTS_Adhoc.BK153283_AssociationByIP LIKE CTS_DataCenter.AssociationByIP;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociationRemove;
CREATE TABLE CTS_Adhoc.BK153283_AssociationRemove LIKE CTS_DataCenter.AssociationRemove;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociatedAccountMonitor;
CREATE TABLE CTS_Adhoc.BK153283_AssociatedAccountMonitor LIKE CTS_DataCenter.AssociatedAccountMonitor;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_AssociatedAccountNotification;
CREATE TABLE CTS_Adhoc.BK153283_AssociatedAccountNotification LIKE CTS_DataCenter.AssociatedAccountNotification;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CustEvidence;
CREATE TABLE CTS_Adhoc.BK153283_CustEvidence LIKE CTS_DataCenter.CustEvidence;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CustRetractEvidence;
CREATE TABLE CTS_Adhoc.BK153283_CustRetractEvidence LIKE CTS_DataCenter.CustRetractEvidence;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CustEvidenceLog;
CREATE TABLE CTS_Adhoc.BK153283_CustEvidenceLog LIKE CTS_DataCenter.CustEvidenceLog;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CustException;
CREATE TABLE CTS_Adhoc.BK153283_CustException LIKE CTS_DataCenter.CustException;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CTSCustomerClassification;
CREATE TABLE CTS_Adhoc.BK153283_CTSCustomerClassification LIKE CTS_DataCenter.CTSCustomerClassification;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_CTSCustomerClassification_History;
CREATE TABLE CTS_Adhoc.BK153283_CTSCustomerClassification_History LIKE CTS_DataCenter.CTSCustomerClassification_History;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_PinCustomerCategory;
CREATE TABLE CTS_Adhoc.BK153283_PinCustomerCategory LIKE CTS_DataCenter.PinCustomerCategory;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_SpecialCustomerClass;
CREATE TABLE CTS_Adhoc.BK153283_SpecialCustomerClass LIKE CTS_DataCenter.SpecialCustomerClass;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_ProbationAccountMonitor;
CREATE TABLE CTS_Adhoc.BK153283_ProbationAccountMonitor LIKE CTS_DataCenter.ProbationAccountMonitor;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_SmartGroup;
CREATE TABLE CTS_Adhoc.BK153283_SmartGroup LIKE CTS_DataCenter.SmartGroup;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_SmartGroupHistory;
CREATE TABLE CTS_Adhoc.BK153283_SmartGroupHistory LIKE CTS_DataCenter.SmartGroupHistory;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_DCS_Account;
CREATE TABLE CTS_Adhoc.BK153283_DCS_Account LIKE DCS_DataCenter.Account;

DROP TABLE IF EXISTS CTS_Adhoc.BK153283_DCS_Association;
CREATE TABLE CTS_Adhoc.BK153283_DCS_Association LIKE DCS_DataCenter.Association;
