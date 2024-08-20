/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_Insert_Process`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Insert_Process`()
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
			
		Param's Expanation:
			- 
		
		Example:
			- CALL CTS_DC_CustClassification_BySport_Insert_Process();
				
		Revisions: 
			- 20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
*/
	DECLARE CONST_CATEID_NEW			 				INT;
	DECLARE CONST_CATEID_SPECIALCC 						INT;
	DECLARE CONST_PARENTID_NORMAL		 				INT;
	DECLARE CONST_ACTIONTYPE_INSERT 					INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 					INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 			INT DEFAULT 5;
	DECLARE CONST_SOURCETYPE_SAMECATEGORY 				INT DEFAULT 0;
	DECLARE CONST_SOURCETYPE_LESSTHAN10TICKETS			INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_RESCAN_CHANGECC 			INT DEFAULT 6;

	SET CONST_CATEID_NEW		 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_NEW');
	SET CONST_CATEID_SPECIALCC	 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
	SET CONST_PARENTID_NORMAL	 						= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');

	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Old;    
	CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Old(	  
			CustID										BIGINT UNSIGNED
		,	SportID										SMALLINT UNSIGNED
        ,	OldCategoryID 								INT UNSIGNED
        ,	OldCategoryGroupID							INT UNSIGNED
        ,	PRIMARY KEY (CustID, SportID)
	); 
	
	DROP TEMPORARY TABLE IF EXISTS Temp_UpdateCustomerClass;    
	CREATE TEMPORARY TABLE Temp_UpdateCustomerClass(	  
			CustID										BIGINT UNSIGNED	
		,	SportID										SMALLINT UNSIGNED
		,	CustomerClass 								INT
		,	PRIMARY KEY (CustID, SportID)
	); 

	DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;
	CREATE TEMPORARY TABLE Temp_LastHistory(
			CustID					BIGINT UNSIGNED 
		,	SportID					SMALLINT UNSIGNED
		,	CategoryID				INT 
		,	TargetCC				INT
		,	PRIMARY KEY (CustID, SportID)
	);

	INSERT IGNORE INTO Temp_LastHistory(CustID, SportID, CategoryID, TargetCC)
	SELECT temp.CustID, tmpHis.SportID, tmpHis.CategoryID, tmpHis.TargetCC
	FROM Temp_NewClassification AS temp,
	LATERAL (	SELECT h.SportID, h.CategoryID, IFNULL(h.TargetCC,-1) AS TargetCC
				FROM CTS_DataCenter.CTSCustomerClassification_BySport_History AS h
				WHERE h.CustID = temp.CustID AND h.SportID = temp.SportID
				ORDER BY ID DESC
				LIMIT 1) AS tmpHis
	;
	
	UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_LastHistory AS h ON temp.CustID = h.CustID AND temp.SportID = h.SportID 
	SET temp.ActionType = CONST_ACTIONTYPE_RESCAN_CHANGECC /*Remove SpecialCC*/
	WHERE h.TargetCC = -1 OR h.CategoryID = CONST_CATEID_SPECIALCC;

	UPDATE Temp_NewClassification AS temp 
	SET 	temp.NewCategoryGroupID = temp.DWCategoryID 
		,	temp.NewCategoryID 		= temp.DWCategoryID 
	WHERE temp.IsDataChanged = 1
		OR (temp.IsDataChanged = 0 AND temp.ActionType = CONST_ACTIONTYPE_RESCAN_CHANGECC);
	
	INSERT IGNORE INTO Temp_CTSCustomerClassification_Old(CustID, SportID, OldCategoryGroupID, OldCategoryID)
    SELECT DISTINCT temp.CustID, temp.SportID, cc.CategoryGroupID, cate.CategoryID
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cate ON temp.CustID = cate.CustID AND cate.ParentID = CONST_PARENTID_NORMAL
																				AND temp.SportID = cate.SportID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID 
	WHERE temp.IsDataChanged = 1 
		OR (temp.IsDataChanged = 0 AND temp.ActionType IN (CONST_ACTIONTYPE_RESCAN_CHANGECC,CONST_ACTIONTYPE_IGNOREPROBATION));
	
	UPDATE Temp_NewClassification AS temp
		LEFT JOIN Temp_CTSCustomerClassification_Old AS o ON temp.CustID = o.CustID AND temp.SportID = o.SportID
	SET 	temp.OldCategoryGroupID 	= CASE WHEN o.CustID IS NULL THEN CONST_CATEID_NEW ELSE o.OldCategoryGroupID END
		,	temp.OldCategoryID 			= CASE WHEN o.CustID IS NULL THEN CONST_CATEID_NEW ELSE o.OldCategoryID END
        ,	temp.ActionType 			= CASE 	WHEN temp.ActionType = CONST_ACTIONTYPE_INSERT AND o.CustID IS NULL THEN CONST_ACTIONTYPE_INSERT 
												WHEN temp.IsDataChanged = 1 AND temp.ActionType IN (CONST_ACTIONTYPE_INSERT,CONST_ACTIONTYPE_RESCAN_CHANGECC) AND o.CustID IS NOT NULL AND temp.NewCategoryID <> o.OldCategoryID
													THEN CONST_ACTIONTYPE_INSERT
												WHEN temp.IsDataChanged = 1 AND temp.ActionType IN (CONST_ACTIONTYPE_INSERT,CONST_ACTIONTYPE_RESCAN_CHANGECC) AND o.CustID IS NOT NULL AND temp.NewCategoryID = o.OldCategoryID
													THEN CONST_ACTIONTYPE_UPDATE
												ELSE temp.ActionType
										  END
	WHERE temp.IsDataChanged = 1 
		OR (temp.IsDataChanged = 0 AND temp.ActionType IN (CONST_ACTIONTYPE_RESCAN_CHANGECC,CONST_ACTIONTYPE_IGNOREPROBATION));

	UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.SourceTypeID = (CASE 
									WHEN (temp.OldCategoryGroupID IS NULL OR temp.OldCategoryGroupID = CONST_CATEID_NEW) 
											AND temp.NewCategoryGroupID = CONST_CATEID_NEW 
										THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
                                    WHEN temp.OldCategoryGroupID = temp.NewCategoryGroupID THEN CONST_SOURCETYPE_SAMECATEGORY
								END)
	WHERE temp.IsDataChanged = 1;
	
	UPDATE Temp_NewClassification AS temp
	SET 	temp.IsDataChanged = 0
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_UPDATE,CONST_ACTIONTYPE_RESCAN_CHANGECC)
		AND temp.NewCategoryID = temp.OldCategoryID;
	
	UPDATE Temp_NewClassification AS temp 
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = temp.NewCategoryID
	SET 	temp.TargetCC = IFNULL(temp.SpecialCC, cate.CustomerClass);
	
	INSERT IGNORE INTO Temp_UpdateCustomerClass(CustID, SportID, CustomerClass)
	SELECT 	temp.CustID
		,	h.SportID
		,	h.TargetCC
	FROM Temp_NewClassification AS temp
		INNER JOIN Temp_LastHistory AS h ON temp.CustID = h.CustID AND temp.SportID = h.SportID
	WHERE temp.IsDataChanged  = 0;
	
	UPDATE Temp_UpdateCustomerClass AS c
		INNER JOIN Temp_NewClassification AS temp ON c.CustID = temp.CustID AND c.SportID = temp.SportID
	SET temp.OldTargetCC = c.CustomerClass;
	
	UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = temp.OldCategoryID
    SET 	temp.TargetCC 			= IFNULL(temp.SpecialCC, cate.CustomerClass)
		,	temp.NewCategoryID		= temp.OldCategoryID
        , 	temp.NewCategoryGroupID = temp.OldCategoryGroupID
    WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_IGNOREPROBATION,CONST_ACTIONTYPE_RESCAN_CHANGECC);
	
	UPDATE Temp_NewClassification AS temp
    SET 	temp.IsDataChanged 	= 1
		,	temp.ActionType 	= CONST_ACTIONTYPE_UPDATE
    WHERE 	temp.IsDataChanged 	= 0 
		AND ((temp.TargetCC <> temp.OldTargetCC) OR (temp.OldCategoryID <> temp.NewCategoryID))
		AND (temp.ActionType IN (CONST_ACTIONTYPE_IGNOREPROBATION,CONST_ACTIONTYPE_RESCAN_CHANGECC)
				OR temp.SourceTypeID IN (CONST_SOURCETYPE_SAMECATEGORY, CONST_SOURCETYPE_LESSTHAN10TICKETS));
	
END$$
DELIMITER ;