/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other_V2`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other_V2`(
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
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other_V2(10000,200,201,402076,140714);
			
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
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			ID					BIGINT UNSIGNED AUTO_INCREMENT
		,	CustID				BIGINT UNSIGNED
		,	RoleID				TINYINT
		,	ParentID			INT
		,	CategoryID			INT
		,	CreatedDate			DATETIME
		,	LastScannedDate		DATETIME
		,	PRIMARY KEY (ID)
	);
	
	INSERT INTO Temp_Customer (CustID,RoleID,ParentID,CategoryID,CreatedDate,LastScannedDate)
	SELECT 	cc.CustID,cust.RoleID,curcate.ParentID,curcate.CategoryID,cc.CreatedDate,cc.LastScannedDate
	FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = cc.CustID AND cust.CustSubID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory AS curcate ON curcate.OldCategoryID = cc.CategoryID_arc 
	WHERE cc.SportGroupID_arc = ip_SportGroupID
		AND cc.CategoryID_arc = ip_CategoryID
		AND cc.CustID >= ip_MinCustID
		AND (cc.ParentID IS NULL 
			OR (cc.SportGroupID_arc <> cc.SportGroupID_bk) -- issue: update 10 million to estimate
			OR (cc.CategoryID_arc <> cc.CategoryID_bk)) -- issue: update 10 million to estimate
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
		
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
			INNER JOIN Temp_Customer AS temp ON cc.CustID = temp.CustID 
												AND cc.SportGroupID_arc = ip_SportGroupID
												AND cc.CategoryID_arc = ip_CategoryID
		SET 	cc.RoleID		 		= temp.RoleID
			,	cc.ParentID 			= temp.ParentID
			,	cc.CategoryID	 		= temp.CategoryID
			,	cc.CreatedDate	 		= temp.CreatedDate
			,	cc.LastScannedDate	 	= temp.LastScannedDate
			,	cc.SportGroupID_bk 		= cc.SportGroupID_arc
			,	cc.CategoryID_bk 		= cc.CategoryID_arc
			,	cc.CreatedDate_bk 		= cc.CreatedDate
			,	cc.LastScannedDate_bk 	= cc.LastScannedDate
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
		,	ip_SportGroupID AS SportGroupID
		,	ip_CategoryID AS CategoryID
		,	ip_MinCustID AS MinCustID
		,	ip_TotalCust AS TotalCust
		,	lv_TotalCustUpdated AS TotalCustUpdated;

END$$
DELIMITER ;