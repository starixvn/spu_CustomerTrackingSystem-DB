/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Update`(
		IN		ip_Batchsize			INT
	,	IN		ip_SportID				SMALLINT
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
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Update(10000,1,201,402076,140714);
			
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
	DECLARE CONST_CATEGORYID_PROBATION		INT DEFAULT 206;
	DECLARE lv_IsProbation					TINYINT(1) DEFAULT 0;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			ID					BIGINT UNSIGNED AUTO_INCREMENT
		,	CustID				BIGINT UNSIGNED
		,	PRIMARY KEY (ID)
	);
	
	IF ip_CategoryID = CONST_CATEGORYID_PROBATION THEN
		SET lv_IsProbation = 1;
	END IF;
	
	INSERT INTO Temp_Customer (CustID)
	SELECT cc.CustID
	FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
	WHERE cc.SportID = ip_SportID
		AND cc.CustID >= ip_MinCustID
		AND cc.CategoryID = ip_CategoryID
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
		
		-- OPTION 1: ONLY UPDATE CreatedDate/LastScannedDate for PROBATION
		UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cc
			INNER JOIN Temp_Customer AS temp ON cc.CustID = temp.CustID 
												AND cc.SportID = ip_SportID
												AND cc.CategoryID = ip_CategoryID
		SET 	cc.CreatedDate 			= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE cc.CreatedDate END
			,	cc.LastScannedDate 		= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE cc.LastScannedDate END
			,	cc.CreatedDate_new 		= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE NULL END
			,	cc.LastScannedDate_new 	= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE NULL END
		WHERE temp.ID BETWEEN lv_FromID AND lv_ToID;
		
		-- OPTION 2: UPDATE COLUMNS suffix _new >> existing
		UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cc
			INNER JOIN Temp_Customer AS temp ON cc.CustID = temp.CustID 
												AND cc.SportID = ip_SportID
												AND cc.CategoryID = ip_CategoryID
		SET 	cc.CategoryID 			= cc.CategoryID_new
			,	cc.CreatedDate 			= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE cc.CreatedDate END
			,	cc.LastScannedDate 		= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE cc.LastScannedDate END
			,	cc.CreatedDate_new 		= CASE WHEN lv_IsProbation = 1 THEN cc.CreatedDate_new ELSE NULL END
			,	cc.LastScannedDate_new 	= CASE WHEN lv_IsProbation = 1 THEN cc.LastScannedDate_new ELSE NULL END
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