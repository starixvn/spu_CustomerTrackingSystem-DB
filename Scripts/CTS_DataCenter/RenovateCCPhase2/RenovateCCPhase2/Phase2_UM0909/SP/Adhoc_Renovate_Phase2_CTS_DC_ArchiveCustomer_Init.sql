/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Init`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Init`(
		OUT		op_NextID				BIGINT
)
    SQL SECURITY INVOKER
BEGIN 
/*
		Created:	20240809@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			CTS_DataCenter

		Param's Expanation:
		
		Example:
			- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Init(op_NextID);
			
		Revisions: 
			- 20240809@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	DECLARE lv_NextID									BIGINT DEFAULT 0;
	DECLARE lv_Batchsize								BIGINT DEFAULT 0;
	DECLARE lv_MinID									BIGINT DEFAULT 0;
	DECLARE CONST_PARAMID_ARCHIVECUSTOMER_BATCHSIZE		BIGINT DEFAULT 892;
	DECLARE CONST_PARAMID_ARCHIVECUSTOMER_ID			BIGINT DEFAULT 891;

	DROP TEMPORARY TABLE IF EXISTS Temp_History;    
	CREATE TEMPORARY TABLE Temp_History(	  
			ID 						BIGINT 
		,	ParentID	 			INT 
		,	CategoryID_new 			INT
		,	CategoryID_bk 			INT
		,	PRIMARY KEY (ID)
	);
	
	SELECT ParameterValue
	INTO lv_Batchsize
	FROM SystemParameter
	WHERE ParameterID = CONST_PARAMID_ARCHIVECUSTOMER_BATCHSIZE;
	
	SELECT ParameterValue
	INTO lv_MinID
	FROM SystemParameter
	WHERE ParameterID = CONST_PARAMID_ARCHIVECUSTOMER_ID;
	
	INSERT INTO Temp_History (ID, CategoryID_bk, ParentID, CategoryID_new)
	SELECT 	h.ID
		, 	h.CategoryID AS CategoryID_bk
		, 	cate.ParentID
		, 	cate.CategoryID AS CategoryID_new
	FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS h -- USE INDEX (PRIMARY)
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.OldCategoryID = h.CategoryID
	WHERE h.ID >= lv_MinID
		AND h.CategoryID IS NOT NULL
		AND h.ParentID IS NULL
	ORDER BY h.ID
	LIMIT lv_Batchsize;
	
	UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS h
		INNER JOIN Temp_History AS temp ON temp.ID = h.ID
	SET 	h.CategoryID_bk 	= temp.CategoryID_bk
		,	h.ParentID	 		= temp.ParentID	
		,	h.CategoryID_new 	= temp.CategoryID_new
	;
	
	SELECT MAX(ID)
	INTO lv_NextID
	FROM Temp_History;
	
	SET op_NextID = lv_NextID;
	
	UPDATE SystemParameter
	SET ParameterValue = lv_NextID
	WHERE ParameterID = CONST_PARAMID_ARCHIVECUSTOMER_ID;
	
END$$
DELIMITER ;