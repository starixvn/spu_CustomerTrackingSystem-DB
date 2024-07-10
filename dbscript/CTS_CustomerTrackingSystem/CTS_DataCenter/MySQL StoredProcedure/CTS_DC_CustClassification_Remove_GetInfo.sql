/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Remove_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_CustInfo				JSON
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- CTS_DC_CustClassification_Remove_GetInfo ();
*/
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			CustID						BIGINT UNSIGNED PRIMARY KEY
		, 	CTSCustID					BIGINT UNSIGNED
		, 	SubscriberID				INT UNSIGNED
		,	RoleID						INT	
		,	Remark 						VARCHAR(500) 
		,	CreatedBy 					INT UNSIGNED
		,	IsExistVVIP					BIT(1)
		,	IsExceptDirectDownline		BIT(1) DEFAULT NULL
        ,	IsMarkedDirectly			BIT(1) DEFAULT NULL
        ,	IsRemovedPA					BIT(1) DEFAULT 1
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClassification;
	CREATE TEMPORARY TABLE 	Temp_CustomerClassification (
			CustID						BIGINT UNSIGNED  
		, 	CTSCustID					BIGINT UNSIGNED
		, 	SubscriberID				INT UNSIGNED
		,	RoleID						INT	
		,	Remark 						VARCHAR(500) 
		,	CreatedBy 					INT UNSIGNED
        ,	IsMarkedDirectly			BIT(1) DEFAULT NULL
        ,	IsRemovedPA					BIT(1) DEFAULT 0
		,	CategoryID 					INT UNSIGNED
		,	Ext_EvidenceID_Licensee 	SMALLINT UNSIGNED	
		,	Ext_EvidenceID_Credit		SMALLINT UNSIGNED

		,	PRIMARY KEY PK_Temp_CC_CustIDCategoryID(CustID, CategoryID)
		,	INDEX IX_Temp_CC_IsRemovedPA(IsRemovedPA)
	);
	
	INSERT INTO Temp_Customer(CustID, CTSCustID, CreatedBy, IsExistVVIP)
	

END$$
DELIMITER ;