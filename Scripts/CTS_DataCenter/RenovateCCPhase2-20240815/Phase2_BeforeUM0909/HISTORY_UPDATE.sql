/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_NEW`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_NEW`(
		IN		ip_Batchsize			INT
	,	IN		ip_MinID				BIGINT
	,	OUT		op_NextID				BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240809@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_NEW(9);
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DECLARE lv_NextID						BIGINT DEFAULT 0;

	DROP TEMPORARY TABLE IF EXISTS Temp_History;    
	CREATE TEMPORARY TABLE Temp_History(	  
			ID 						BIGINT 
		,	ParentID_new 			INT 
		,	CategoryID_new 			INT
		,	OldCategoryID_new 		INT
		,	DWCategoryID_new 		INT DEFAULT NULL
		,	SportGroupID_bk 		INT
		,	CategoryID_bk 			INT
		,	FromCategoryID_bk 		INT
		,	ToCategoryID_bk  		INT
		,	PRIMARY KEY (ID)
		,	KEY IX_ToCategoryID (ToCategoryID_bk)
	);
	
	INSERT INTO Temp_History (ID, SportGroupID_bk, CategoryID_bk, FromCategoryID_bk, ToCategoryID_bk, ParentID_new, CategoryID_new, OldCategoryID_new)
	SELECT 	h.ID
		, 	h.SportGroupID AS SportGroupID_bk
		, 	h.CategoryID AS CategoryID_bk
		, 	h.FromCategoryID AS FromCategoryID_bk
		, 	h.ToCategoryID AS ToCategoryID_bk
		, 	CASE WHEN cate.ParentID IS NULL AND h.SportGroupID IS NOT NULL THEN 20000 ELSE cate.ParentID END AS ParentID_new
		, 	cate.CategoryID AS CategoryID_new
		, 	cateF.CategoryID AS OldCategoryID_new
	FROM CTS_DataCenter.CTSCustomerClassification_History AS h
		LEFT JOIN CTS_DataCenter.CustomerCategory_new AS cate ON cate.OldCategoryID = h.CategoryID
		LEFT JOIN CTS_DataCenter.CustomerCategory_new AS cateF ON cateF.OldCategoryID = h.FromCategoryID
	WHERE h.ID >= ip_MinID
	ORDER BY h.ID
	LIMIT ip_Batchsize;
	
	UPDATE Temp_History AS h
	, LATERAL (
		SELECT cateT.CategoryID
		FROM CTS_DataCenter.CustomerCategory_new AS cateT
		WHERE cateT.Ext_CategoryGroupID = h.ToCategoryID_bk
		ORDER BY cateT.CategoryID
		LIMIT 1
    ) AS cateT1
	SET 	h.DWCategoryID_new = cateT1.CategoryID
	--	,	 , h.ParentID_new = CASE WHEN  h.ParentID_new IS NULL THEN 20000 ELSE h.ParentID_new END
	;
	
	SELECT *
	FROM Temp_History;

	UPDATE CTS_DataCenter.CTSCustomerClassification_History AS h

		
		UPDATE CTS_DataCenter.CTSCustomerClassification_History AS cc
			INNER JOIN CTS_DataCenter.CustomerCategory_new AS newcate ON newcate.OldCategoryID = cc.CategoryID
			LEFT JOIN CTS_DataCenter.CustomerCategory_new AS fromcate ON fromcate.OldCategoryID = cc.FromCategoryID
			LEFT JOIN CTS_DataCenter.CustomerCategory_new AS tocate ON tocate.OldCategoryID = cc.ToCategoryID
		SET 	cc.ParentID_new 		= newcate.ParentID
			,	cc.CategoryID_new 		= newcate.CategoryID
			,	cc.OldCategoryID_new	= CASE WHEN fromcate.CategoryID IS NOT NULL THEN fromcate.CategoryID ELSE cc.FromCategoryID END
			,	cc.DWCategoryID_new		= CASE WHEN tocate.CategoryID IS NOT NULL THEN tocate.CategoryID ELSE cc.ToCategoryID END
			,	cc.SportGroupID_bk 		= cc.SportGroupID
			,	cc.CategoryID_bk 		= cc.CategoryID
			,	cc.FromCategoryID_bk	= cc.FromCategoryID
			,	cc.ToCategoryID_bk 		= cc.ToCategoryID
		WHERE cc.ID BETWEEN lv_FromID AND lv_ToID
			AND cc.SportGroupID = ip_SportGroupID;
		
		SET lv_UpdatedCount = FOUND_ROWS();
		SET lv_TotalRowsUpdated = lv_TotalRowsUpdated + lv_UpdatedCount;
		SET lv_TotalRows = lv_TotalRows - lv_UpdatedCount;
		
		WITH CTE AS
		(	SELECT cc.ID
			FROM CTS_DataCenter.CTSCustomerClassification_History AS cc
				INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CTSCustID = cc.CTSCustID AND cust.CustSubID = 0
			WHERE cc.SportGroupID = ip_SportGroupID
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
		,	ip_SportGroupID AS SportGroupID
		,	ip_MinID AS MinID
		,	ip_TotalRows AS TotalRows
		,	lv_TotalRowsUpdated AS TotalRowsUpdated;

END$$
DELIMITER ;