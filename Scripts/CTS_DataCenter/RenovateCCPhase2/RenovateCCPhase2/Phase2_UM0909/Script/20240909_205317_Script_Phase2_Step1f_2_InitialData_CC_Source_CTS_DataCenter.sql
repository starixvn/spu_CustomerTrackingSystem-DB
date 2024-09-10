/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240826@Victoria.Le
	Task :	Initial Data CTSCustomerClassification
	DB:			
	
	Description: 

	Revisions:	
		- 20240826@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
									Tables:
										1. SpecialCustomerClass
										2. SpecialCustomerClass_BySport
										3. CTSCustomerClassification - Current: CC = VVIP - From CTSCustomerClassificationVVIP | CTSCustomerClassificationOldCategory
										4. CTSCustomerClassification - Current: CC = PA - From CTSCustomerClassificationOldCategory
										5. RobotDetection - Update IsDisable = 1 - Customers have been archived
										6. RobotImperva - Update IsDisable = 1 - Customers have been archived
										7. CustomerLoginInfoDetection - Add 17 cust "Site Migration"
										8. CTSCustomerClassification/History - CTSCustID = 0
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

/*Initial variable*/
SET @CONST_CATEID_VVIP 				:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
SET @CONST_CATEID_SPECIALCC 		:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
SET @CONST_CATEGROUPID_RISKY 		:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_RISKY');
SET @CONST_CATEGROUPID_SMART 		:= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SMART');
SET @CONST_PARENTID_WRAPPER 		:= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
SET @CONST_PARENTID_NORMAL 			:= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
SET @CONST_PARENTID_PA 				:= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');

---------------------------------
/*1. SpecialCustomerClass - 20240827: 158 cust*/
---------------------------------
/* STEP 3.3.1.a */

DROP TEMPORARY TABLE IF EXISTS Temp_Customer_SpecialCC;    
CREATE TEMPORARY TABLE Temp_Customer_SpecialCC(	  
		CTSCustID				BIGINT 
	,	CustID					BIGINT 
	,	SubscriberID			INT 
	,	RoleID					INT 
	,	CreatedDate				DATETIME 
	,	LastModifiedBy			INT 
	,	LastModifiedDate		DATETIME 
	,	LastScannedDate			DATETIME 
	,	Remark					VARCHAR(500) 
	,	PRIMARY KEY (CTSCustID,CustID)
);

INSERT INTO Temp_Customer_SpecialCC (CTSCustID, CustID, SubscriberID, RoleID, CreatedDate, LastModifiedBy, LastScannedDate, Remark)
SELECT 	sp.CTSCustID, sp.CustID, cust.SubscriberID, cust.RoleID, sp.CreatedDate, sp.LastModifiedBy, sp.CreatedDate 
	,	(SELECT Remark FROM SpecialCustomerClass_History AS h WHERE h.CustID = sp.CustID ORDER BY h.CreatedDate DESC LIMIT 1) AS Remark
FROM SpecialCustomerClass as sp
	INNER JOIN CTSCustomer as cust on cust.CTSCustID = sp.CTSCustID
WHERE NOT EXISTS (SELECT 1 FROM CTSCustomerClassification AS cc WHERE cc.CTSCustID = sp.CTSCustID AND cc.CategoryID = @CONST_CATEID_VVIP) 
;

INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification (
		CustID, CTSCustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy
	, 	LastModifiedDate, LastModifiedBy, LastScannedDate, Remark, SportGroupID_arc, CategoryID_arc)
SELECT  temp.CustID
	, 	temp.CTSCustID
	,	temp.SubscriberID
	,	temp.RoleID
	,	@CONST_PARENTID_WRAPPER AS ParentID
	,	@CONST_CATEID_SPECIALCC AS CategoryID
	, 	temp.CreatedDate
	, 	temp.LastModifiedBy AS CreatedBy
	, 	NOW() AS LastModifiedDate
	, 	temp.LastModifiedBy
	, 	temp.LastScannedDate
	, 	temp.Remark
	,	0
	,	0
FROM Temp_Customer_SpecialCC AS temp;


DROP TEMPORARY TABLE IF EXISTS Temp_Customer_SpecialCC;   