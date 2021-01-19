/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210119@Irena.Vo
	Task: 	 149026-Init data VVIP  [Redmine ID: #149026]
	DB: 	 CTS_DataCenter, CTS_Adhoc
    
    Revisions: 
	-	[202010119@Irena.Vo]: Init data VVIP
*/
USE CTS_Adhoc;
/* Create Backup VVIP Table  */
CREATE TABLE CTS_Adhoc.BK_149026_VVIPCustomerClass LIKE CTS_DataCenter.SpecialCustomerClass;

/* Insert Backup VVIP Data */
INSERT INTO CTS_Adhoc.BK_149026_VVIPCustomerClass (CTSCustID,CustID,RootCTSCustID,SubscriberID,CustomerClass,CreatedBy,CreatedDate,LastModifiedBy,LastModifiedDate,CreatedFromFunction)
SELECT 	CTSCustID 
	,	CustID 			
	,	RootCTSCustID 		  
	,	SubscriberID 		 
	,	CustomerClass 		 
	,	CreatedBy 			 
	,	CreatedDate 		 
	,	LastModifiedBy 		 
	,	LastModifiedDate 	 
	,	CreatedFromFunction 
FROM CTS_DataCenter.SpecialCustomerClass
WHERE CTSCustID > 0 AND CreatedFromFunction = 11;

USE CTS_DataCenter;
/* Init VVIP Data */
INSERT IGNORE INTO CTS_DataCenter.PinCustomerCategory (CustID,CreatedTime)
SELECT 	CustID
	,	CURRENT_TIME() AS CreatedTime
FROM CTS_Adhoc.BK_149026_VVIPCustomerClass;

/* Remove Old VVIP Data */
DELETE 
FROM CTS_DataCenter.SpecialCustomerClass
WHERE CTSCustID > 0 AND CreatedFromFunction = 11;