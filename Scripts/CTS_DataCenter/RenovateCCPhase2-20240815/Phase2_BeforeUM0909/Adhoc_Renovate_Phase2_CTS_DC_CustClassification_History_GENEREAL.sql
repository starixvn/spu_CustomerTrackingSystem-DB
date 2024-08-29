/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_GENEREAL`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_GENEREAL`(
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
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_GENEREAL(ip_Batchsize,ip_MinID,op_NextID);
			
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
		, 	CASE WHEN cate.ParentID IS NULL AND h.SportGroupID IS NOT NULL THEN
					CASE WHEN h.SportGroupID = 0 THEN 20000
						 WHEN h.SportGroupID = 200 AND h.TargetCC = -1 THEN 1000 END
				 ELSE cate.ParentID END AS ParentID_new
		, 	cate.CategoryID AS CategoryID_new
		, 	cateF.CategoryID AS OldCategoryID_new
	FROM CTS_DataCenter.CTSCustomerClassification_History AS h -- USE INDEX (PRIMARY)
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
	;
	
	UPDATE CTS_DataCenter.CTSCustomerClassification_History AS h
		INNER JOIN Temp_History AS temp ON temp.ID = h.ID
	SET 	h.SportGroupID_bk 	= temp.SportGroupID_bk
		,	h.CategoryID_bk 	= temp.CategoryID_bk	
		,	h.FromCategoryID_bk = temp.FromCategoryID_bk	
		,	h.ToCategoryID_bk 	= temp.ToCategoryID_bk	
		,	h.ParentID_new 		= temp.ParentID_new	
		,	h.CategoryID_new 	= temp.CategoryID_new	
		,	h.OldCategoryID_new = temp.OldCategoryID_new	
		,	h.DWCategoryID_new	= temp.DWCategoryID_new	
	;
	
	SELECT MAX(ID)
	INTO lv_NextID
	FROM Temp_History;
	
	SET op_NextID = lv_NextID;
	
END$$
DELIMITER ;