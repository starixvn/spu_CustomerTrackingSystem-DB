/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation`(
		IN		ip_Batchsize			INT
	,	IN		ip_SportGroupID			INT
	,	IN		ip_CategoryID			INT
	,	IN		ip_MinCustID			BIGINT
	,	IN		ip_TotalCust			BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240829@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(10000,200,206,402076,140714);
			
		Revisions: 
			- 20240829@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	
		DECLARE lv_FromID						BIGINT DEFAULT 0;
		DECLARE lv_ToID							BIGINT DEFAULT 0;
		DECLARE lv_FromID_Next					BIGINT DEFAULT 0;
		DECLARE lv_ToID_Next					BIGINT DEFAULT 0;
		DECLARE lv_TotalCustUpdated				BIGINT DEFAULT 0;
		DECLARE lv_UpdatedCount					BIGINT DEFAULT 0;
		DECLARE lv_TotalCust					BIGINT;
		DECLARE	CONST_SPORTGROUP_NORMAL			INT DEFAULT 200;
		DECLARE CONST_CATEGORYGROUP_PROBATION	INT DEFAULT 206;
		
		DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
		CREATE TEMPORARY TABLE Temp_Customer (
				ID			BIGINT UNSIGNED AUTO_INCREMENT
			,	CustID		BIGINT UNSIGNED
			,	RoleID		TINYINT
			,	PRIMARY KEY (ID)
		);
		
		INSERT INTO Temp_Customer (CustID,RoleID)
		SELECT cc.CustID,cust.RoleID
		FROM CTS_DataCenter.CTSCustomerClassification AS cc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
			INNER JOIN CTS_DataCenter.ProbationAccountMonitor AS pro ON pro.CustID = cc.CustID AND pro.SportGroupID = CONST_SPORTGROUP_NORMAL
		WHERE cc.SportGroupID = ip_SportGroupID
			AND cc.CategoryID = ip_CategoryID
			AND cc.CustID >= ip_MinCustID
			AND (cc.ParentID_new IS NULL 
				OR (cc.CategoryID = cc.CategoryID_bk AND cc.LastScannedDate_new <> pro.LastScannedDate)
				OR (cc.CategoryID <> cc.CategoryID_bk))
		ORDER BY cc.CustID;
		
		

END$$
DELIMITER ;