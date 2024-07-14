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
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- 
*/
	DECLARE CONST_CATEID_NEW			 				INT;

	DECLARE CONST_ACTIONTYPE_INSERT 					INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 					INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 			INT DEFAULT 5;
	
	DECLARE CONST_SOURCETYPE_SAMECATEGORY 				INT DEFAULT 0;
	DECLARE CONST_SOURCETYPE_LESSTHAN10TICKETS			INT DEFAULT 1;

	SET CONST_CATEID_NEW		 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_NEW');

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
		,	CustomerClass 								SMALLINT
		,	PRIMARY KEY (CustID, SportID)
	); 
	
	INSERT IGNORE INTO Temp_CTSCustomerClassification_Old(CustID, SportID, OldCategoryGroupID, OldCategoryID)
    SELECT DISTINCT temp.CustID, temp.SportID, cc.CategoryGroupID, cate.CategoryID
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cate ON temp.CustID = cate.CustID 
																				AND temp.SportID = cate.SportID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION);
	
	UPDATE Temp_NewClassification AS temp
		LEFT JOIN Temp_CTSCustomerClassification_Old AS o ON temp.CustID = o.CustID AND temp.SportID = o.SportID
	SET 	temp.OldCategoryGroupID 	= CASE WHEN o.CustID IS NULL THEN CONST_CATEID_NEW ELSE o.OldCategoryGroupID END
		,	temp.OldCategoryID 			= CASE WHEN o.CustID IS NULL THEN CONST_CATEID_NEW ELSE o.OldCategoryID END
        ,	temp.ActionType 			= CASE WHEN o.CustID IS NULL THEN CONST_ACTIONTYPE_INSERT ELSE CONST_ACTIONTYPE_UPDATE END
	WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
	
	UPDATE Temp_NewClassification AS temp
		LEFT JOIN Temp_CTSCustomerClassification_Old AS o ON temp.CustID = o.CustID AND temp.SportID = o.SportID
	SET 	temp.OldCategoryGroupID 	= CASE WHEN o.CustID IS NULL THEN CONST_CATEID_NEW ELSE o.OldCategoryGroupID END
		,	temp.OldCategoryID 			= CASE WHEN o.CustID IS NULL THEN CONST_CATEID_NEW ELSE o.OldCategoryID END
	WHERE temp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;
	
	UPDATE Temp_NewClassification AS temp 
	SET 	temp.NewCategoryGroupID = temp.DWCategoryGroupID 
		,	temp.NewCategoryID 		= temp.DWCategoryID 
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
	
	UPDATE 	Temp_NewClassification AS temp
	SET 	temp.IsDataChanged = 0
	WHERE 	temp.ActionType = CONST_ACTIONTYPE_UPDATE 
		AND temp.NewCategoryID = temp.OldCategoryID ;
    
	UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.SourceTypeID = (CASE 
									WHEN (temp.OldCategoryGroupID IS NULL OR temp.OldCategoryGroupID = CONST_CATEID_NEW) 
											AND temp.NewCategoryGroupID = CONST_CATEID_NEW 
										THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
                                    WHEN temp.OldCategoryGroupID = temp.NewCategoryGroupID THEN CONST_SOURCETYPE_SAMECATEGORY
								END)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
	
	UPDATE Temp_NewClassification AS temp 
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = temp.NewCategoryID
	SET 	temp.TargetCC = IFNULL(temp.SpecialCC, cate.CustomerClass)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_IGNOREPROBATION);
	
	INSERT IGNORE INTO Temp_UpdateCustomerClass(CustID, SportID, CustomerClass)
	WITH CTE_LatestLog AS (
		SELECT h.CustID, h.SportID, MAX(h.LastModifiedDate) AS LatestInsertDate
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON temp.CustID = h.CustID
																							AND temp.SportID = h.SportID
		WHERE temp.IsDataChanged  = 0
		GROUP BY h.CustID, h.SportID
	),CTE_LatestHistory AS (
		SELECT h.CustID, h.SportID, h.TargetCC
		FROM CTE_LatestLog AS l
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON l.CustID = h.CustID 
																						AND l.SportID = h.SportID
																						AND l.LatestInsertDate = h.LastModifiedDate
	)
	SELECT 	cte.CustID
		,	cte.SportID
		,	cte.TargetCC
	FROM CTE_LatestHistory AS cte;
	
	UPDATE Temp_UpdateCustomerClass AS c
		INNER JOIN Temp_NewClassification AS temp ON c.CustID = temp.CustID AND c.SportID = temp.SportID
	SET temp.OldTargetCC = c.CustomerClass;
	
	UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = temp.OldCategoryID
    SET 	temp.TargetCC 			= IFNULL(temp.SpecialCC, cate.CustomerClass)
		,	temp.NewCategoryID		= temp.OldCategoryID
        , 	temp.NewCategoryGroupID = temp.OldCateGroup
    WHERE 	temp.ActionType 		= CONST_ACTIONTYPE_IGNOREPROBATION;
	
	UPDATE Temp_NewClassification AS temp
    SET 	temp.IsDataChanged 	= 1
		,	temp.ActionType 	= CONST_ACTIONTYPE_UPDATE
    WHERE 	temp.IsDataChanged 	= 0 
		AND ((temp.TargetCC <> temp.OldTargetCC) OR (temp.OldCategoryID <> temp.NewCategoryID))
		AND (temp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION 
				OR temp.SourceTypeID IN (CONST_SOURCETYPE_SAMECATEGORY, CONST_SOURCETYPE_LESSTHAN10TICKETS));
	
END$$
DELIMITER ;