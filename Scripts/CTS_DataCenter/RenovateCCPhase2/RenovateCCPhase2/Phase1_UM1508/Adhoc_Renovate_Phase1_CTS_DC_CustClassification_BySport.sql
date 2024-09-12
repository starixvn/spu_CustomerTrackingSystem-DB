/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport`(
		IN		ip_Batchsize			INT
	,	IN		ip_SportID				SMALLINT
	,	IN		ip_CategoryID			INT
	,	IN		ip_MinCustID			BIGINT
	,	IN		ip_TotalCust			BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240809@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase1_CTS_DC_CustClassification_BySport(9);
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
			- 20240816@Victoria.Le:			Missing initial data [Redmine ID: #205317]
*/

	
	DECLARE lv_FromID						BIGINT DEFAULT 0;
	DECLARE lv_ToID							BIGINT DEFAULT 0;
	DECLARE lv_FromID_Next					BIGINT DEFAULT 0;
	DECLARE lv_ToID_Next					BIGINT DEFAULT 0;
	DECLARE lv_TotalCustUpdated				BIGINT DEFAULT 0;
	DECLARE lv_UpdatedCount					BIGINT DEFAULT 0;
	DECLARE lv_TotalCust					BIGINT;
    DECLARE CONST_CATEGORYID_PROBATION		INT DEFAULT 206;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			ID			BIGINT UNSIGNED AUTO_INCREMENT
		,	CustID		BIGINT UNSIGNED
		,	PRIMARY KEY (ID)
	);
	
	INSERT INTO Temp_Customer (CustID)
	SELECT cc.CustID
	FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = cc.CTSCustID AND cust.CustSubID = 0
	WHERE cc.SportID = ip_SportID
		AND cc.CustID >= ip_MinCustID
		AND cc.CategoryID = ip_CategoryID
		AND cc.ParentID IS NULL
		AND cc.CreatedDate  < '2024-08-15 00:00:00' and cc.LastModifiedDate  < '2024-08-15 00:00:00' and cc.LastScannedDate < '2024-08-15 00:00:00'
		ORDER BY cc.CustID;
	
	WITH CTE AS
	(	SELECT temp.ID
		FROM Temp_Customer AS temp
		ORDER BY temp.ID
		LIMIT ip_Batchsize
	)
	SELECT MIN(c.ID),MAX(c.ID)
	INTO lv_FromID, lv_ToID
	FROM CTE AS c;
	
	SET lv_TotalCust = ip_TotalCust;
	
	WHILE (lv_TotalCust > 0 AND lv_FromID > 0 AND lv_ToID > 0)
	DO
		SET lv_UpdatedCount = 0;
	
		UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cc
			INNER JOIN Temp_Customer AS temp ON cc.CustID = temp.CustID 
												AND cc.SportID = ip_SportID
												AND cc.CategoryID = ip_CategoryID
			INNER JOIN CTS_DataCenter.CustomerCategory_new AS newcate ON newcate.OldCategoryID = cc.CategoryID
			LEFT JOIN CTS_DataCenter.CustomerCategory AS curcate ON curcate.CategoryID = cc.CategoryID
																		AND curcate.CategoryID = CONST_CATEGORYID_PROBATION
			LEFT JOIN CTS_DataCenter.ProbationAccountMonitor_BySport AS pro ON pro.CustID = cc.CustID AND pro.SportID = cc.SportID
		SET 	cc.ParentID		 		= newcate.ParentID
			,	cc.CategoryID_new 		= newcate.CategoryID
			,	cc.CreatedDate_new 		= CASE 	WHEN curcate.CategoryID IS NOT NULL AND pro.CustID IS NOT NULL 
													THEN pro.CreatedDate 
												ELSE cc.CreatedDate_new END
			,	cc.LastScannedDate_new 	= CASE 	WHEN curcate.CategoryID IS NOT NULL AND pro.CustID IS NOT NULL AND cc.LastScannedDate <> pro.LastScannedDate
													THEN pro.LastScannedDate 
												ELSE cc.LastScannedDate_new END
			,	cc.CategoryID_bk 		= cc.CategoryID
			,	cc.CreatedDate_bk 		= CASE 	WHEN curcate.CategoryID IS NOT NULL AND pro.CustID IS NOT NULL 
													THEN cc.CreatedDate 
												ELSE cc.CreatedDate_bk END
			,	cc.LastScannedDate_bk 	= CASE 	WHEN curcate.CategoryID IS NOT NULL AND pro.CustID IS NOT NULL AND cc.LastScannedDate <> pro.LastScannedDate
													THEN cc.LastScannedDate 
												ELSE cc.LastScannedDate_bk END
		WHERE temp.ID BETWEEN lv_FromID AND lv_ToID;
		
		SET lv_UpdatedCount = FOUND_ROWS();
		SET lv_TotalCustUpdated = lv_TotalCustUpdated + lv_UpdatedCount;
		SET lv_TotalCust = lv_TotalCust - lv_UpdatedCount;
		
		WITH CTE AS
		(	SELECT temp.ID
			FROM Temp_Customer AS temp
			WHERE temp.ID > lv_ToID
			ORDER BY temp.ID
			LIMIT ip_Batchsize
		)
		SELECT MIN(c.ID),MAX(c.ID)
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
		,	ip_CategoryID AS CategoryID
		,	ip_MinCustID AS MinCustID
		,	ip_TotalCust AS TotalCust
		,	lv_TotalCustUpdated AS TotalCustUpdated;

END$$
DELIMITER ;