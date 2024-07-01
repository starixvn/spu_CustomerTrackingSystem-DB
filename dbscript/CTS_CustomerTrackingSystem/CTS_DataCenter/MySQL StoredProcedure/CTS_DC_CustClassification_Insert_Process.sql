/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_Process`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_Process`(
		IN	ip_InputFlowID			INT
)
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

	-- CALL CTS_DataCenter.CTS_DC_CustClassification_Remark_Get(ip_InputFlowID); 
	DECLARE CONST_CATEID_VVIP 				INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 	INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 	INT;
	DECLARE CONST_CATEID_LICBA 				INT;
	DECLARE CONST_PARENTID_VVIP 			INT;
	DECLARE CONST_PARENTID_WRAPPER 			INT;
	DECLARE CONST_PARENTID_PA 				INT;
    DECLARE CONST_PARENTID_POTENTIALPA      INT;
    DECLARE CONST_PARENTID_NORMAL		    INT;
	
	DECLARE	CONST_ACTIONTYPE_UPDATE 		INT DEFAULT 1;
	
	
    DECLARE lv_MaxCTSCustID					BIGINT UNSIGNED;
    DECLARE lv_LicVIPPriority				SMALLINT UNSIGNED;
    DECLARE lv_LicBAPriority				SMALLINT UNSIGNED;
	DECLARE	lv_CurrentDateTime				DATETIME DEFAULT CURRENT_TIME();
	
	SET CONST_CATEID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_PARENTID_VVIP 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_PARENTID_POTENTIALPA			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
	SET CONST_PARENTID_NORMAL	 			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
	
	/*TEMP OLD TABLE*/
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Old;
	CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Old (
			CustID					BIGINT UNSIGNED
		,	CTSCustID				BIGINT UNSIGNED
		,	SubscriberID			INT UNSIGNED
		,	ParentID				INT UNSIGNED
		,	CategoryID				INT
		,	CategoryGroupID			INT
		,	ExistCategoryID			INT
		,	RelevantCategoryID		INT
		,	Remark					VARCHAR(500)
		,	CreatedDate				DATETIME(3)
		,	CreatedBy				INT UNSIGNED
		,	LastModifiedDate		DATETIME(3)
		,	LastModifiedBy			INT UNSIGNED
		,	LastScannedDate			DATETIME
		,	IsFromTVS				BIT(1) 
		,	IsFromTW				BIT(1) 
		,	IsFromCTS				BIT(1) 
		,	IsFromAI				BIT(1) 
		,	IsMarkedDirect	BIT(1)
		,	InsertTime				DATETIME
		,	TVSRequestID			BIGINT UNSIGNED			
		,	IsTVSParlay				BIT(1) 
		,	SportType				SMALLINT DEFAULT NULL 
		,	IssueTypeID				TINYINT DEFAULT NULL 
		,	IsMarkedDirect	BIT(1)
		,	SpecialCC	       		SMALLINT 
		,	CustomerClass			SMALLINT 
		,	CategoryPriority		SMALLINT UNSIGNED
		,	IsPAProbation			BIT(1)
		,	IsNew					BIT(1) DEFAULT 1
		,	IsRemove				BIT(1) DEFAULT NULL
		,	INDEX IDX_Temp_CC_Old (CustID,CategoryID)
	);

	
	DROP TEMPORARY TABLE IF EXISTS Temp_PAWinlossStatus;    
	CREATE TEMPORARY TABLE Temp_PAWinlossStatus(	
			CustID					BIGINT UNSIGNED PRIMARY KEY
        , 	WinlossStatus			SMALLINT /*LOSING  = 0 (PROBATION), WINNING = 2 (NOT PROBATION);*/
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustProbationStatus ;
    CREATE TEMPORARY TABLE Temp_CustProbationStatus(
			CustID 					INT UNSIGNED PRIMARY KEY
		,	CTSCustID 				BIGINT UNSIGNED
        ,	IsPAProbation			BIT(1)
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT
        ,	WinlossStatus			TINYINT
		,	IsLicensee				BIT(1)
	);   
	
	
	IF ip_InputFlowID = 8 THEN
		/* 6: GENERATE CATEGORY */
		/* 6.1: UPDATE DW CATEGORY */
		UPDATE Temp_NewClassification AS temp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryGroupID = temp.DWCategoryGroupID 
																AND cate.TaggingType = temp.TaggingType 
																AND tag.TaggingID = temp.TaggingID
		SET temp.DWCategoryID = IFNULL(cate.CategoryID,temp.DWCategoryGroupID);

	
	
	ELSEIF ip_InputFlowID IN (50,51,6,7) THEN
		INSERT INTO Temp_PAWinlossStatus(CustID, WinlossStatus)
		SELECT DISTINCT 
				temp.CustID
			,	CASE WHEN cc.IsDangerProbation = 1 THEN 0 ELSE 2 END AS WinlossStatus
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID
            INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cls.CategoryID = cc.CategoryID
		WHERE cls.ParentID IN (CONST_SPORTGROUP_PA, CONST_SPORTGROUP_POTENTIALPA);
		
		UPDATE Temp_NewClassification AS temp
			INNER JOIN Temp_PAWinlossStatus AS r ON temp.CustID = r.CustID
		SET temp.WinlossStatus = r.WinlossStatus,
			temp.IsPAProbation = (CASE WHEN r.WinlossStatus = 0 THEN 1 ELSE 0 END)
		WHERE temp.WinlossStatus = 1;
		
		UPDATE Temp_NewClassification AS temp
            ,	LATERAL(SELECT 	cat.CategoryGroupID
							,	cat.CustomerClass
							,	cat.Ext_ABIDangerLevel_Licensee
							,	cat.Ext_ABIDangerLevel_Credit
							,	cat.Ext_EvidenceID_Licensee
							,	cat.Ext_EvidenceID_Credit
							,	cat.RelevantCategoryID
						FROM CTS_DataCenter.CustomerCategory AS cat 
						WHERE cat.CategoryID IN (temp.DWCategoryID, temp.RelevantCategoryID) 
							AND cat.IsPAProbation = temp.IsPAProbation LIMIT 1) AS tmpCat
		SET 	temp.NewCategoryGroupID = tmpCat.CategoryGroupID	
			,	temp.NewCategoryID = tmpCat.CategoryGroupID
			,	temp.TargetCC = (CASE 	WHEN temp.SpecialCC IS NOT NULL THEN temp.SpecialCC 
										ELSE IFNULL(tmpCat.CustomerClass,-99) END)
			,	temp.TargetDangerLevel = (CASE  WHEN temp.IsLicensee = 1 THEN tmpCat.Ext_ABIDangerLevel_Licensee
												WHEN temp.IsLicensee = 0 THEN tmpCat.Ext_ABIDangerLevel_Credit END) 
			,	temp.ToEvidenceID = (CASE 	WHEN temp.IsLicensee = 1 THEN tmpCat.Ext_EvidenceID_Licensee
											WHEN temp.IsLicensee = 0 THEN tmpCat.Ext_EvidenceID_Credit
											ELSE NULL END)
			,	temp.RelevantCategoryID = tmpCat.RelevantCategoryID;
	
		UPDATE Temp_NewClassification AS temp
			,	LATERAL(SELECT 	cat.CategoryGroupID
							,	cat.IsPAProbation
						FROM CTS_DataCenter.CustomerCategory  AS cat 
						WHERE cat.CategoryID = temp.RelevantCategoryID LIMIT 1) AS tmpCat
		SET 	temp.RelevantCategoryGroupID = tmpCat.CategoryGroupID	
			,	temp.RelevantCategoryID = tmpCat.CategoryGroupID
			,	temp.RelevantIsPAProbation = tmpCat.IsPAProbation;   
		
		/*Insert cust has pin/vvip into CTSCustomerClassification*/
		INSERT IGNORE INTO Temp_CTSCustomerClassification_Old(
				CustID, CTSCustID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate
			, 	CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsFromTVS
			, 	IsFromTW, IsFromCTS, IsFromAI, InsertTime, TVSRequestID, IsTVSParlay
			, 	SportType, TVSIssueTypeID, IsMarkedDirect) 
		SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	ccs.ParentID
			,	temp.NewCategoryID
			,	temp.Remark
			,	lv_CurrentDateTime AS CreatedDate
			,	temp.CreatedBy
			,	lv_CurrentDateTime AS LastModifiedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	DATE(lv_CurrentDateTime) AS LastScannedDate
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	lv_CurrentDateTime AS InsertTime
			,	temp.TVSRequestID
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
			,	temp.IsMarkedDirect
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = temp.NewCategoryID 
																			AND ccs.IsKeepOldCateID = 1
		WHERE temp.IsExistVVIP = 1;
		
		/*clear temp for these cust*/
		DELETE FROM Temp_NewClassification AS temp
    	WHERE temp.IsExistVVIP = 1;
		
		INSERT IGNORE INTO Temp_CTSCustomerClassification_Old(
				CustID, CTSCustID, SubscriberID, ParentID, CategoryID, CategoryGroupID, ExistCategoryID, RelevantCategoryID
			, 	Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsFromTVS
			, 	IsFromTW, IsFromCTS, IsFromAI, InsertTime, TVSRequestID, IsTVSParlay
			, 	SportType, TVSIssueTypeID, IsMarkedDirect, SpecialCC, CustomerClass
			,	CategoryPriority, IsPAProbation, IsNew, IsRemove) 
		SELECT	cls.CustID
			,	cls.CTSCustID
			,	cls.SubscriberID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN NULL ELSE cc.ParentID END AS ParentID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN cc.CategoryID ELSE cc.CategoryGroupID END AS CategoryID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN NULL ELSE cc.CategoryGroupID END AS CategoryGroupID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN NULL ELSE cls.CategoryID END AS ExistCategoryID
			,	cc.RelevantCategoryID
			,	cls.Remark
			,	cls.CreatedDate
			,	cls.CreatedBy
			,	cls.LastModifiedDate
			,	cls.LastModifiedBy
			,	cls.LastScannedDate
			,	cls.IsFromTVS
			,	cls.IsFromTW
			,	cls.IsFromCTS
			,	cls.IsFromAI
			,	lv_CurrentDateTime AS InsertTime
			,	cls.TVSRequestID
			,	cls.IsTVSParlay
			,	cls.SportType
			,	cls.TVSIssueTypeID
			,	cls.IsMarkedDirect
			,	temp.SpecialCC
			,	IFNULL(temp.SpecialCC,cc.CustomerClass)
			,	cc.CategoryPriority
			,	cc.IsPAProbation
			,	0 AS IsNew
			,	CASE WHEN cc.CategoryPriority > temp.CategoryPriority 
							THEN (CASE 	WHEN ccs.IsMultiCateIDSameParentID = 0 AND ccs.IsKeepOldCateID = 1 THEN 0
										WHEN ccs.IsMultiCateIDSameParentID = 0 AND ccs.IsKeepOldCateID = 0 THEN 1
										WHEN ccs.IsMultiCateIDSameParentID = 1 THEN 0 END)
					 ELSE NULL END AS IsRemove
		FROM CTS_DataCenter.CTSCustomerClassification AS cls
			INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cls.CustID
			INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = cls.CategoryID 
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID 
		WHERE cls.ParentID IN (CONST_PARENTID_PA,PARENTID_POTENTIALPA,CONST_PARENTID_NORMAL)
		;

		DELETE temp
		FROM Temp_NewClassification AS temp 
			INNER JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp.CustID = temp_old.CustID		
		WHERE temp_old.IsNew = 0 AND temp_old.IsRemove IS NULL;
		
		UPDATE Temp_NewClassification AS temp 
			LEFT JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp.CustID = temp_old.CustID	
																			AND temp.NewCategoryGroupID = temp_old.CategoryGroupID
																			AND temp_old.ParentID IS NOT NULL
																			AND temp_old.IsNew = 0
																			AND temp_old.IsRemove = 0
		SET temp.IsDataChanged = 1
		WHERE temp.IsDataChanged = 0 AND temp_old.CustID IS NULL;
		
		UPDATE Temp_NewClassification AS temp 
			INNER JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp.CustID = temp_old.CustID	
																			AND temp.RelevantCategoryGroupID = temp_old.CategoryGroupID
																			AND temp_old.ParentID IS NOT NULL
																			AND temp_old.IsNew = 0
																			AND temp_old.IsRemove = 0
		SET 	temp.DataChangeType = 1 
			,	temp.IsDataChanged = 1 
			,	temp.OldCategoryID = temp_old.ExistCategoryID
			,	temp.LastModifiedDate = IFNULL(temp.LastModifiedDate, temp_old.LastModifiedDate)
			,	temp.ActionType = CONST_ACTIONTYPE_UPDATE
			,	temp.CreatedBy = temp_old.CreatedBy;  
		
		
		DELETE temp_old
		FROM Temp_CTSCustomerClassification_Old AS temp_old
			INNER JOIN Temp_NewClassification AS temp ON temp.RelevantCategoryGroupID = temp_old.CategoryGroupID
															AND temp_old.ParentID IS NOT NULL
															AND temp_old.IsNew = 0
															AND temp_old.IsRemove = 0
															AND temp.WinlossStatus <> 1 
															AND temp.IsFromOldPA = 0;
		
		INSERT IGNORE INTO Temp_CustProbationStatus(CustID, CTSCustID, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsPAProbation, WinlossStatus, IsLicensee)
		SELECT DISTINCT 
				temp.CustID
			,	temp.CTSCustID
			,	temp.TurnoverRM
			,	temp.WinlossRM
			,	temp.BetCount
			,	temp.ActiveDays
			,	(CASE WHEN temp.WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsPAProbation
			,	temp.WinlossStatus
			,	temp.IsLicensee
		FROM Temp_NewClassification AS temp;
		
		INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, DWCategoryID, OldCategoryID, NewCategoryID, TargetCC,  TargetDangerLevel
			, 	ToEvidenceID, Remark, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsMarkedDirect
			, 	IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsDataChanged, DataChangeType
			, 	LastModifiedDate, CreatedBy, IsPAProbation, TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID)
		SELECT 		temp_old.CustID
				,	temp_old.CTSCustID
				,	temp_old.ExistCategoryID AS DWCategoryID
				,	temp_old.ExistCategoryID AS OldCategoryID
				,	tmpLtr.CategoryGroupID AS NewCategoryID
				,	(CASE 	WHEN temp_old.SpecialCC IS NOT NULL THEN temp_old.SpecialCC 
							ELSE IFNULL(tmpLtr.CustomerClass,-99) END) AS TargetCC
				, 	(CASE 	WHEN tmpCp.IsLicensee = 1 THEN tmpLtr.Ext_ABIDangerLevel_Licensee
							WHEN tmpCp.IsLicensee = 0 THEN tmpLtr.Ext_ABIDangerLevel_Credit END) AS TargetDangerLevel
				,	(CASE 	WHEN tmpCp.IsLicensee = 1 THEN tmpLtr.Ext_EvidenceID_Licensee
							WHEN tmpCp.IsLicensee = 0 THEN tmpLtr.Ext_EvidenceID_Credit 
							ELSE NULL END) AS ToEvidenceID
				,	temp_old.Remark
				,	tmpCp.TurnoverRM
				,	tmpCp.WinlossRM
				,	tmpCp.BetCount
				,	tmpCp.ActiveDays
				,	temp_old.IsMarkedDirect
				,	temp_old.IsFromTVS
				,	temp_old.IsFromTW
				,	temp_old.IsFromCTS
				,	temp_old.IsFromAI
				,	1 AS IsDataChanged
				,	(CASE WHEN tmpCp.WinlossStatus = NULL THEN NULL ELSE 1 END) AS DataChangeType
				,	temp_old.LastModifiedDate
				,	temp_old.CreatedBy
				,	temp_old.IsPAProbation
				,	temp_old.TVSRequestID
				,	temp_old.IsTVSParlay
				,	temp_old.SportType
				,	temp_old.TVSIssueTypeID
			FROM Temp_CTSCustomerClassification_Old AS temp_old
				INNER JOIN Temp_CustProbationStatus AS tmpCp ON tmpCp.CustID = temp_old.CustID 
																AND tmpCp.IsPAProbation <> temp_old.IsPAProbation
																AND tmpCp.WinlossStatus <> 1 
			, 	LATERAL (SELECT cat.CategoryGroupID
							,	cat.CustomerClass
							,	cat.Ext_ABIDangerLevel_Licensee
							,	cat.Ext_ABIDangerLevel_Credit
							,	cat.Ext_EvidenceID_Licensee
							,	cat.Ext_EvidenceID_Credit
						FROM CTS_DataCenter.CustomerCategory AS cat 
						WHERE temp_old.RelevantCategoryID = cat.CategoryID 
						LIMIT 1) AS tmpLt
			WHERE temp_old.ParentID IS NOT NULL
				AND temp_old.IsNew = 0
				AND temp_old.IsRemove = 0
			;    

		
	END IF;
	
END$$
DELIMITER ;