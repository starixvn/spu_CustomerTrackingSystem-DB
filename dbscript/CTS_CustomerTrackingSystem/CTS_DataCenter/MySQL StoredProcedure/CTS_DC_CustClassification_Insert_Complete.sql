/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_Complete`(
		IN	ip_InputFlowID			INT
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
			- 
*/

	-- CALL CTS_DataCenter.CTS_DC_CustClassification_Remark_Get(ip_InputFlowID); 
	DECLARE CONST_CATEID_VVIP 				INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 	INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 	INT;
	DECLARE CONST_CATEID_LICBA 				INT;
	DECLARE CONST_PARENTID_VVIP 			INT;
	DECLARE CONST_PARENTID_WRAPPER 			INT;
	DECLARE CONST_PARENTID_PA 				INT;
	
	
    DECLARE lv_MaxCTSCustID					BIGINT UNSIGNED;
    DECLARE lv_LicVIPPriority				SMALLINT UNSIGNED;
    DECLARE lv_LicBAPriority				SMALLINT UNSIGNED;
	
	SET CONST_CATEID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_PARENTID_VVIP 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	
	-- ADD MAIN TABLE CC - FROM OLD - isnew = 1
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
			CustID, CTSCustID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
		, 	LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsMarkedDirect, InsertTime, TVSRequestID, IsParlay, SportType, IssueTypeID) 
	SELECT temp_old.CustID
		, temp_old.CTSCustID
        , temp_old.SubscriberID
        , temp_old.ParentID
        , temp_old.CategoryID
        , temp_old.Remark
        , temp_old.CreatedDate
        , temp_old.CreatedBy
        , temp_old.LastModifiedDate
        , temp_old.LastModifiedBy
        , temp_old.LastScannedDate
        , temp_old.IsFromTVS
        , temp_old.IsFromTW
        , temp_old.IsFromCTS
        , temp_old.IsFromAI
        , temp_old.IsMarkedDirect
        , CURRENT_TIMESTAMP(3) AS InsertTime
        , temp_old.TVSRequestID
		, temp_old.IsParlay
		, temp_old.SportType
		, temp_old.IssueTypeID
    FROM Temp_CTSCustomerClassification_Old AS temp_old
	WHERE temp_old.IsNew = 1;
	
	-- DELETE MAIN TABLE - FROM OLD - isnew = 0 + IsRemove = 1
	DELETE cls
	FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp_old.CustID = cls.CustID
																		AND temp_old.ExistCategoryID = cls.CategoryID
	WHERE temp_old.IsNew = 0 AND temp_old.IsRemove = 1;
	
	
END$$
DELIMITER ;