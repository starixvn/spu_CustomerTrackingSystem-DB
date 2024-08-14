/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History`(
		IN		ip_Batchsize			INT
	,	IN		ip_SportID				SMALLINT
	,	IN		ip_MinID				BIGINT
	,	IN		ip_TotalRows			BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240809@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport_History(9);
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DECLARE lv_FromID						BIGINT DEFAULT 0;
	DECLARE lv_ToID							BIGINT DEFAULT 0;
	DECLARE lv_FromID_Next					BIGINT DEFAULT 0;
	DECLARE lv_ToID_Next					BIGINT DEFAULT 0;
	DECLARE lv_TotalRowsUpdated				BIGINT DEFAULT 0;
	DECLARE lv_UpdatedCount					BIGINT DEFAULT 0;
	DECLARE lv_TotalRows					BIGINT;

	WITH CTE AS
	(	SELECT cc.ID
		FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS cc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = cc.CTSCustID AND cust.CustSubID = 0
		WHERE cc.SportID = ip_SportID
			AND cc.ID >= ip_MinID
		ORDER BY cc.ID
		LIMIT ip_Batchsize
	)
	SELECT MIN(c.ID), MAX(c.ID)
	INTO lv_FromID, lv_ToID
	FROM CTE AS c;
		
	SET lv_TotalRows = ip_TotalRows;
	
	WHILE (lv_TotalRows > 0 AND lv_FromID > 0 AND lv_ToID > 0)
	DO
		SET lv_UpdatedCount = 0;
		
		UPDATE CTS_DataCenter.CTSCustomerClassification_BySport_History AS cc
			INNER JOIN CTS_DataCenter.CustomerCategory_new AS newcate ON newcate.OldCategoryID = cc.CategoryID
		SET 	cc.ParentID_new 		= newcate.ParentID
			,	cc.CategoryID_new 		= newcate.CategoryID
			,	cc.CategoryID_bk 		= cc.CategoryID
		WHERE cc.ID BETWEEN lv_FromID AND lv_ToID
			AND cc.SportID = ip_SportID;
		
		SET lv_UpdatedCount = FOUND_ROWS();
		SET lv_TotalRowsUpdated = lv_TotalRowsUpdated + lv_UpdatedCount;
		SET lv_TotalRows = lv_TotalRows - lv_UpdatedCount;
		
		WITH CTE AS
		(	SELECT cc.ID
			FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS cc
				INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = cc.CTSCustID AND cust.CustSubID = 0
			WHERE cc.SportID = ip_SportID
				AND cc.ID > lv_ToID
			ORDER BY cc.ID
			LIMIT ip_Batchsize
		)
		SELECT MIN(c.ID), MAX(c.ID)
		INTO lv_FromID_Next, lv_ToID_Next
		FROM CTE AS c;
		
		IF lv_FromID_Next > 0 AND lv_ToID_Next > 0 
			AND lv_FromID_Next <> lv_FromID AND lv_ToID_Next <> lv_ToID 
			AND lv_FromID_Next > lv_FromID AND lv_ToID_Next > lv_ToID THEN
		
			SET lv_FromID = lv_FromID_Next;
			SET lv_ToID = lv_ToID_Next;
		
		ELSE
			
			SET lv_FromID = 0;
			SET lv_ToID = 0;
			
		END IF;
	
	END WHILE;
	
	SELECT 	ip_Batchsize AS Batchsize
		,	ip_SportID AS SportID
		,	ip_MinID AS MinID
		,	ip_TotalRows AS TotalRows
		,	lv_TotalRowsUpdated AS TotalRowsUpdated;

END$$
DELIMITER ;