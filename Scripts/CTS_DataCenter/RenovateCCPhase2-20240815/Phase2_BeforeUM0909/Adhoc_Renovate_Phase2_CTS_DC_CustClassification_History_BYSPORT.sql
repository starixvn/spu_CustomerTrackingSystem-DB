/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_BYSPORT`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_BYSPORT`(
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
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_History_BYSPORT(ip_Batchsize,ip_MinID,op_NextID);
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DECLARE lv_NextID						BIGINT DEFAULT 0;

	DROP TEMPORARY TABLE IF EXISTS Temp_History_BySport;    
	CREATE TEMPORARY TABLE Temp_History_BySport(	  
			ID 						BIGINT 
		,	ParentID	 			INT 
		,	CategoryID_new 			INT
		,	CategoryID_bk 			INT
		,	PRIMARY KEY (ID)
	);
	
	INSERT INTO Temp_History_BySport (ID, CategoryID_bk, ParentID, CategoryID_new)
	SELECT 	h.ID
		, 	h.CategoryID AS CategoryID_bk
		, 	cate.ParentID
		, 	cate.CategoryID AS CategoryID_new
	FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS h
		LEFT JOIN CTS_DataCenter.CustomerCategory_new AS cate ON cate.OldCategoryID = h.CategoryID
	WHERE h.ID >= ip_MinID
	ORDER BY h.ID
	LIMIT ip_Batchsize;
	
	UPDATE CTS_DataCenter.CTSCustomerClassification_BySport_History AS h
		INNER JOIN Temp_History_BySport AS temp ON temp.ID = h.ID
	SET 	h.ParentID 			= temp.ParentID		
		,	h.CategoryID_bk 	= temp.CategoryID_bk
		,	h.CategoryID_new 	= temp.CategoryID_new	
	;
	
	SELECT MAX(ID)
	INTO lv_NextID
	FROM Temp_History;
	
	SET op_NextID = lv_NextID;
	
END$$
DELIMITER ;