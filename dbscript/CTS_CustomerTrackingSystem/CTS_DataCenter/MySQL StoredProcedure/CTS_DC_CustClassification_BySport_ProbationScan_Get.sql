/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_ProbationScan_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE  `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_ProbationScan_Get`(
		OUT	op_LastCustID			INT
	,	OUT	op_LastCategoryID		INT
)
    SQL SECURITY INVOKER 
sp: BEGIN
	/*
		Created:	20220907@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- [20200923@Irena.Vo][141755]: Enhance SP.
			- 202230426@Long.Luu: Adjust Probation's period from 20 to 15 [Redmine ID: #187433]
            - 20230707@Jonas.Huynh: Normal Renovation [Redmine ID: #189875]
            - 20240124@Jonas.Huynh: Exclude inactive customer within 30days [Redmine ID: #199632]
            - 20240718@Jonas.Huynh: Renovate CC [Redmine ID: #205317]
            
		Param's Explanation (filtered by):
			- CALL CTS_DC_CustClassification_BySport_ProbationScan_Get (@op_LastCustID, @op_LastCategoryID);
	*/
    
	DECLARE	CONST_PARENTID_NORMAL			INT;
    DECLARE	CONST_CATEGROUPID_PROBATION		INT;
    DECLARE CONST_PARENTID_WRAPPER			INT;   
    
	DECLARE lv_BatchSize 					INT;
    DECLARE lv_LastCustID					BIGINT UNSIGNED;
    DECLARE lv_NextCustID 					BIGINT UNSIGNED;
    DECLARE lv_LastCategoryID				BIGINT UNSIGNED;
    DECLARE lv_NextCategoryID 				BIGINT UNSIGNED;
    DECLARE lv_CurrentDate 					DATE DEFAULT CURRENT_DATE();
    DECLARE lv_ToLastDay 					DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 2 DAY); /*Up to 3 Last Day*/
    DECLARE lv_From30Date 					DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 29 DAY);
    
    SET CONST_PARENTID_NORMAL 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
    SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_CATEGROUPID_PROBATION 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_PROBATION');
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
	CREATE TEMPORARY TABLE Temp_Category(
			CategoryID		INT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID 			BIGINT UNSIGNED
       ,	SportID			SMALLINT
       ,	PRIMARY KEY (CustID, SportID)
    );
    
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 168; 
    
    SELECT ParameterValue 
    INTO lv_LastCategoryID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 169;
    
	SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 170; 
    
 	INSERT INTO Temp_Category(CategoryID)
	SELECT ca.CategoryID
	FROM CTS_DataCenter.CustomerCategorySettings AS s
		INNER JOIN CTS_DataCenter.CustomerCategory AS ca ON ca.CategoryID = s.CategoryID
	WHERE ca.CategoryGroupID = CONST_CATEGROUPID_PROBATION 
		AND ca.IsActive = 1;
        
	IF lv_LastCategoryID IS NULL OR lv_LastCategoryID = 0 THEN
		SELECT CategoryID 
		INTO lv_LastCategoryID
		FROM Temp_Category
		ORDER BY CategoryID ASC
        LIMIT 1;
	END IF;
    
    INSERT INTO Temp_Cust(CustID, SportID)
    SELECT 	tmplc.CustID, tmplc.SportID
    FROM	CTS_DataCenter.CTSCustomerClassification_BySport AS clss
		,	LATERAL	
				(	SELECT cc.CustID, cc.SportID, cc.CategoryID, ca.CategoryGroupID, cc.LastScannedDate, cc.CreatedDate
					FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cc 
						INNER JOIN CTS_DataCenter.CustomerCategory AS ca ON ca.CategoryID = cc.CategoryID
					WHERE cc.CustID = clss.CustID
						AND cc.SportID = clss.SportID
						AND ca.IsActive = 1
                        AND ca.ParentID <> CONST_PARENTID_WRAPPER
					ORDER BY ca.CategoryPriority ASC, cc.CreatedDate DESC
					LIMIT 1
			   ) AS tmplc
	WHERE clss.CustID > lv_LastCustID
		AND clss.CategoryID = lv_LastCategoryID
		AND tmplc.CategoryID = lv_LastCategoryID
		AND (tmplc.LastScannedDate IS NULL OR tmplc.LastScannedDate < lv_CurrentDate)
		AND (tmplc.CreatedDate < lv_ToLastDay)
		AND EXISTS (SELECT 1
			FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
			WHERE arc.CustID = clss.CustID AND arc.LastTicketDate >= lv_From30Date)
	ORDER BY clss.CategoryID ASC
		,	 clss.CustID ASC
	LIMIT	lv_BatchSize;
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Cust) THEN
		SELECT tmplc.CategoryID
        INTO   lv_NextCategoryID
		FROM Temp_Category AS cate
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS clss ON clss.CategoryID = cate.CategoryID
			, LATERAL	
				(	SELECT cc.CategoryID, cc.LastScannedDate, cc.CreatedDate
					FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cc 
						INNER JOIN CTS_DataCenter.CustomerCategory AS ca ON ca.CategoryID = cc.CategoryID
					WHERE cc.CustID = clss.CustID
						AND cc.SportID = clss.SportID
						AND ca.IsActive = 1
						AND ca.ParentID <> CONST_PARENTID_WRAPPER 
					ORDER BY ca.CategoryPriority ASC, cc.CreatedDate DESC
					LIMIT 1
			    ) AS tmplc
		WHERE cate.CategoryID > lv_LastCategoryID
			AND tmplc.CategoryID > lv_LastCategoryID
			AND (tmplc.LastScannedDate IS NULL OR tmplc.LastScannedDate < lv_CurrentDate)
			AND (tmplc.CreatedDate < lv_ToLastDay)
            AND EXISTS (SELECT 1
				FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
				WHERE arc.CustID = clss.CustID AND arc.LastTicketDate >= lv_From30Date)
		ORDER BY cate.CategoryID ASC
		LIMIT 1; 
     END IF;
     
     IF lv_NextCategoryID IS NOT NULL THEN
		INSERT IGNORE INTO Temp_Cust (CustID, SportID)
		SELECT 	tmplc.CustID, tmplc.SportID
		FROM	CTS_DataCenter.CTSCustomerClassification AS clss
			,	LATERAL	
					(	SELECT cc.CustID, cc.SportID, cc.CategoryID, ca.CategoryGroupID, cc.LastScannedDate, cc.CreatedDate 
						FROM CTS_DataCenter.CTSCustomerClassification AS cc 
							INNER JOIN CTS_DataCenter.CustomerCategory AS ca ON ca.CategoryID = cc.CategoryID
						WHERE cc.CustID = clss.CustID
							AND cc.SportID = clss.SportID
							AND ca.IsActive = 1
							AND ca.ParentID <> CONST_PARENTID_WRAPPER 
						ORDER BY ca.CategoryPriority ASC, cc.CreatedDate DESC
						LIMIT 1
				   ) AS tmplc
		WHERE clss.CustID > 0
			AND clss.CategoryID = lv_NextCategoryID
			AND tmplc.CategoryID = lv_NextCategoryID
			AND (tmplc.LastScannedDate IS NULL OR tmplc.LastScannedDate < lv_CurrentDate)
			AND (tmplc.CreatedDate < lv_ToLastDay)
            AND EXISTS (SELECT 1
				FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
				WHERE arc.CustID = clss.CustID AND arc.LastTicketDate >= lv_From30Date)
		ORDER BY clss.CategoryID ASC
			,	 clss.CustID ASC
		LIMIT	lv_BatchSize;
	ELSE
		SET lv_NextCategoryID = lv_LastCategoryID;
	END IF;
	
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_Cust;
    
    IF lv_NextCustID IS NOT NULL THEN
        SET op_LastCategoryID = lv_NextCategoryID;
		SET op_LastCustID = lv_NextCustID;
	ELSE 
		SELECT CategoryID
        INTO lv_NextCategoryID
		FROM Temp_Category
		ORDER BY CategoryID ASC 
		LIMIT 1;
	
        SET op_LastCategoryID = lv_NextCategoryID;
        SET op_LastCustID = 0;
    END IF;
    
    SELECT DISTINCT	tmp.CustID AS CustId
		,	tmp.SportID AS SportGroup
    FROM Temp_Cust AS tmp;
END$$
DELIMITER ;