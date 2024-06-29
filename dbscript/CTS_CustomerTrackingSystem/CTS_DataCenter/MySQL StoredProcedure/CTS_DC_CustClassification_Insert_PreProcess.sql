*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_PreProcess`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_PreProcess`(
    	IN ip_InputFlowID 	INT
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240620@Thomas.Nguyen
		Task:		
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20240620@Thomas.Nguyen: Created [Redmine ID: #205317]

		Param's Explanation (filtered by):
        
        Example:
				CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_PreProcess(6);
*/ 
	/* DECLARE Variable */
    DECLARE CONST_CATEGROUPID_PROBATION     			INT;
    DECLARE CONST_CATEGROUPID_SMART         			INT;
    DECLARE CONST_CATEGROUPID_RISKY         			INT;

    DECLARE CONST_PARENTID_PA               			INT;
    DECLARE CONST_PARENTID_POTENTIALPA      			INT;
    DECLARE CONST_CATETYPEID_NORMAL		      			INT;
	
    DECLARE CONST_CATEID_PROBATION		      			INT;

    DECLARE CONST_ACTIONTYPE_INSERT 					INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 					INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 					INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_EXISTEDPA 					INT DEFAULT 3;
    DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 			INT DEFAULT 5;

    DECLARE CONST_SCANTAGGINGTYPE_NOTEXIST  			TINYINT DEFAULT 0;
	DECLARE	CONST_SCANTAGGINGTYPE_EXIST	   				TINYINT DEFAULT 1;
	DECLARE	CONST_SCANTAGGINGTYPE_EXISTONLY 			TINYINT DEFAULT 2;

	DECLARE lv_ProbationCatePriority					SMALLINT;
	DECLARE lv_FromProbationLastDay 					DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY);
	DECLARE lv_ToProbationLastDay 						DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY);

	/* GET Variable */
    SET CONST_CATEGROUPID_PROBATION 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_PROBATION');
    SET CONST_CATEGROUPID_SMART 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SMART');
    SET CONST_CATEGROUPID_RISKY 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_RISKY');

    SET CONST_PARENTID_PA 				    			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
    SET CONST_PARENTID_POTENTIALPA 						= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
    SET CONST_CATETYPEID_NORMAL	 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_NORMAL');
	
	SET CONST_CATEID_PROBATION							= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_PROBATION');

	/* SETP 0: EXCLUDE INTERNAL CUSTOMERS */      
	CALL CTS_DC_ExcludeCustByCondition('Temp_NewClassification');
	
	/* SETP 1: SpecialCC */ 
	UPDATE Temp_NewClassification AS temp
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON temp.SpecialCC = cc.CustomerClass
															AND c.IsActive = 1
	SET 	temp.SpecialCCName = cc.CustomerClassName
		,	temp.SpecialCCCatePriority = cc.CategoryPriority
		,	temp.SpecialCCDangerProbation = cc.IsDangerProbation
	WHERE temp.SpecialCC <> 0;

	IF ip_InputFlowID = 8 THEN /* Normal */
		 
		/* TEMPORARY TABLE */
		DROP TEMPORARY TABLE IF EXISTS Temp_ProbationCustomer;    
		CREATE TEMPORARY TABLE Temp_ProbationCustomer(	  	
				CustID					BIGINT UNSIGNED	PRIMARY KEY
			, 	ScanDate				DATE   
			,	IsPassProbationRule		BIT(1)
		);

		DROP TEMPORARY TABLE IF EXISTS Temp_CustIgnoranceAction;    
		CREATE TEMPORARY TABLE Temp_CustIgnoranceAction(	  	
				CustID					BIGINT UNSIGNED	PRIMARY KEY
			, 	ActionType				SMALLINT      
		); 

		DROP TEMPORARY TABLE IF EXISTS Temp_NotEnoughDayProbation; 
		CREATE TEMPORARY TABLE Temp_NotEnoughDayProbation(	  
				CustID					BIGINT UNSIGNED	PRIMARY KEY
			,   ScanTaggingType			TINYINT DEFAULT 0
		); 
		
		SELECT cat.CategoryPriority
		INTO lv_ProbationCatePriority
		FROM CTS_DataCenter.CustomerCategory AS cat
		WHERE cat.CategoryID = CONST_CATEID_PROBATION;
		
		 /*4: GET PROBATION CUSTOMERS */
		INSERT IGNORE INTO Temp_ProbationCustomer(CustID, ScanDate, ScanTaggingType, IsPassProbationRule)
		SELECT 	cls.CustID
			, 	cls.LastScannedDate
			, 	temp.ScanTaggingType
			, 	CASE WHEN cls.LastScannedDate >= lv_ToProbationLastDay THEN 0 ELSE 1 END AS IsPassProbationRule
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID
		WHERE cls.CategoryID = CONST_CATEID_PROBATION;
		
		/*DWCategoryGroupID IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK,CONST_CATEGORY_PROBATION)*/
		UPDATE Temp_ProbationCustomer AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.DWCategoryGroupID = temp.CategoryGroupID
		SET temp.IsPassProbationRule = CASE WHEN temp.ScanDate > lv_FromProbationLastDay THEN 0 ELSE 1 END
		WHERE cate.ParentID = CONST_CATETYPEID_NORMAL
			cate.CategoryPriority <= lv_ProbationCatePriority;
		
		INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
		SELECT	temp.CustID, CONST_ACTIONTYPE_IGNOREPROBATION
		FROM 	Temp_ProbationCustomer AS temp 
		WHERE 	temp.IsPassProbationRule = 0
			AND temp.ScanTaggingType = CONST_SCANTAGGINGTYPE_NOTEXIST;

        INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
		SELECT DISTINCT temp.CustID, CONST_ACTIONTYPE_EXISTEDPA
		FROM Temp_NewClassification AS temp
		WHERE temp.ParentID IN (CONST_PARENTID_PA,CONST_PARENTID_POTENTIALPA);
		
		/* 5.4: UPDATE BACK TO Temp_NewClassification */
		/* 5.4.1: HAS ACTION + NO VIEW LOG FAIL PROBATION FOR > 20 LAST DAYS */ 
		UPDATE Temp_NewClassification AS temp
			INNER JOIN  Temp_ProbationCustomer AS pro ON pro.CustID = temp.CustID
		SET temp.IsDataChanged = 0
		WHERE temp.DWCategoryGroupID = CONST_CATEGROUPID_PROBATION 
			AND pro.ScanDate < lv_FromProbationLastDay;
		
		/* 5.4.2: NO ACTION + VIEW LOG FOR IGNORE CASES */ 
		UPDATE Temp_NewClassification AS temp 
			INNER JOIN Temp_CustIgnoranceAction AS ig ON temp.CustID = ig.CustID
		SET 	temp.ActionType = ig.ActionType
			, 	temp.IsDataChanged = 0;

        /* 5.4.3: HAS ACTION + VIEW LOG FOR PROBATION NOT ENOUGH DAY WITH NEW TAGGING */ 
        UPDATE Temp_NewClassification AS tmp 
            INNER JOIN Temp_ProbationCustomer AS pro ON temp.CustID = pro.CustID AND pro.IsPassProbationRule = 0
        SET 	temp.ScanTaggingType = CONST_SCANTAGGINGTYPE_EXISTONLY
        WHERE 	pro.ScanTaggingType <> CONST_SCANTAGGINGTYPE_NOTEXIST;
		
		/* 6: GENERATE CATEGORY */
		/* 6.1: UPDATE DW CATEGORY */
		UPDATE Temp_NewClassification AS temp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryGroupID = temp.DWCategoryGroupID 
																AND cate.TaggingType = temp.TaggingType 
																AND tag.TaggingID = temp.TaggingID
		SET temp.DWCategoryID = IFNULL(cate.CategoryID,temp.DWCategoryGroupID);

	ELSEIF ip_InputFlowID IN (7,51) THEN	   
		CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest();
	ELSEIF ip_InputFlowID IN (6,50,51) THEN
		/*Insert cust has pin/vvip into CTSCustomerClassification*/
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate
		, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsDirect, InsertTime, TVSRequestID, IsParlay, SportType, IssueTypeID, IsAffectToDownline, RoleID) 
		SELECT	tmp.CustID
			,	tmp.CTSCustID
			,	tmp.SubscriberID
			,	CONST_PARENTID_PA
			,	tmp.CategoryID
			,	tmp.Remark
			,	NOW() AS CreatedDate
			,	tmp.CreatedBy
			,	NOW() AS LastModifiedDate
			,	tmp.CreatedBy AS LastModifiedBy
			,	NOW() AS LastScannedDate
			,	tmp.IsFromTVS
			,	tmp.IsFromTW
			,	tmp.IsFromCTS
			,	tmp.IsFromAI
			,	tmp.IsDirect
			,	CURRENT_TIMESTAMP(3) AS InsertTime
			,	tmp.TVSRequestID
			,	tmp.IsTVSParlay
			,	tmp.SportType
			,	tmp.TVSIssueTypeID
			,	0 AS IsAffectToDownline
			,	tmp.RoleID
		FROM Temp_NewClassification AS tmp
		INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = tmp.CategoryID AND ccs.IsKeepOldCateID = 1;
		WHERE tmp.IsExistVVIP = 1;
		
		/*clear temp for these cust*/
		DELETE tmp
    	FROM Temp_NewClassification AS tmp
    	WHERE tmp.IsExistVVIP = 1;

    END IF;   
END$$
DELIMITER ;