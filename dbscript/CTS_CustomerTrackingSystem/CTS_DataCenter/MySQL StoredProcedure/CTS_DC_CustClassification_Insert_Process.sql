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
	DECLARE CONST_CC_LICVIPSUSPICIOUS 		INT;
	DECLARE CONST_CC_LICVIPDANGEROUS 		INT;
	
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
	SET CONST_CC_LICVIPSUSPICIOUS 			= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICVIPSUSPICIOUS');
	SET CONST_CC_LICVIPDANGEROUS	 		= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICVIPDANGEROUS');
	
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
		,	INDEX IX_Temp_CC_Old (CustID,CategoryID)
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
	
	DROP TEMPORARY TABLE IF EXISTS Temp_LicVIPCust;
    CREATE TEMPORARY TABLE Temp_LicVIPCust(
			CustID					INT UNSIGNED PRIMARY KEY
		,	CategoryID 				INT UNSIGNED
        ,	CustomerClass 			INT UNSIGNED
	); 
	
	DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;
    CREATE TEMPORARY TABLE Temp_LastHistory(
			CustID					INT UNSIGNED PRIMARY KEY
        ,	CategoryID				INT UNSIGNED
        ,	TargetCC				INT UNSIGNED
	);
	
	IF ip_InputFlowID = 8 THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_OldClassification;    
		CREATE TEMPORARY TABLE Temp_OldClassification(	  
				CustID					BIGINT UNSIGNED	PRIMARY KEY
			,	OldCateGroupID 			INT
			,	OldCateID 				INT
			,	OldIsDangerProbation	BIT(1) DEFAULT 0
			,	FromOldCategory			BIT(1) DEFAULT 0	
		); 
		
		DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassificationOldCategory;
		CREATE TEMPORARY TABLE Temp_CTSCustomerClassificationOldCategory(
				CustID					BIGINT UNSIGNED
			,	CategoryID				INT
		);
		
		DROP TEMPORARY TABLE IF EXISTS Temp_OldCustomerClass;    
		CREATE TEMPORARY TABLE Temp_OldCustomerClass(	  
				CustID					BIGINT UNSIGNED	PRIMARY KEY
			,	CustomerClass 			SMALLINT
		); 
		
		-- ----------------------------------------------
		INSERT IGNORE INTO Temp_OldClassification (
			CustID, OldCateGroupID, OldCateID, OldIsDangerProbation)
		SELECT DISTINCT temp.CustID, cc.CategoryGroupID, cls.CategoryID, cc.IsDangerProbation
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																			AND cls.ParentID = CONST_PARENTID_NORMAL
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID 
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION);
		
		INSERT IGNORE INTO Temp_OldClassification (
			CustID, OldCateGroupID, OldCateID, OldIsDangerProbation, FromOldCategory)
		SELECT DISTINCT temp.CustID, cc.CategoryGroupID, cls.CategoryID, cc.IsDangerProbation, 1 AS FromOldCategory
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																			AND cls.ParentID = CONST_PARENTID_NORMAL
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID 
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION)
			AND temp.IsExistWrapper = 1;
			
		UPDATE Temp_NewClassification AS n
			LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID
		SET n.OldCategoryGroupID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroupID END,
			n.OldCategoryID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END,
			n.OldIsDangerProbation = CASE WHEN o.CustID IS NULL THEN 1 ELSE o.OldIsDangerProbation END,
			n.ActionType = CASE WHEN o.CustID IS NULL OR FromOldCategory = 1 THEN CONST_ACTIONTYPE_INSERT ELSE CONST_ACTIONTYPE_UPDATE END
		WHERE n.ActionType IN (CONST_ACTIONTYPE_INSERT);
		
		UPDATE Temp_NewClassification AS n
			LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID
		SET n.OldCategoryGroupID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroupID END,
			n.OldCategoryID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END
		WHERE n.ActionType IN (CONST_ACTIONTYPE_IGNOREPROBATION);
		
		UPDATE Temp_NewClassification AS temp 
		SET temp.NewCategoryGroupID = (CASE WHEN temp.OldCateGroupID IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_NORMALMEMBER,CONST_CATEGORY_VIP,CONST_CATEGORY_INACTIVE) 
												AND temp.DWCategoryGroupID IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK) THEN CONST_CATEGORY_PROBATION 
										  ELSE temp.DWCategoryGroupID 
									  END)
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
		
		UPDATE 	Temp_NewClassification AS temp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS tag ON tag.CategoryGroupID = temp.NewCategoryGroupID
																	AND tag.TaggingType = temp.TaggingType 
																	AND tag.TaggingID = temp.TaggingID
		SET temp.NewCategoryID = IFNULL(tag.CategoryID, temp.NewCategoryGroupID)
		 WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) 
			AND temp.DWCategoryGroupID <> CONST_CATEGORY_INACTIVE; /*Exclude Inactive category*/
			
		UPDATE Temp_NewClassification AS temp 
		SET temp.NewCategoryID = (CASE WHEN temp.OldCateGroupID IS NULL OR temp.OldCateGroupID IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_NORMALMEMBER,CONST_CATEGORY_VIP) 
											THEN CONST_CATEGORY_NORMALINACTIVE
									   WHEN temp.OldCateGroupID IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK,CONST_CATEGORY_PROBATION) 
											THEN CONST_CATEGORY_PROPUNTERINACTIVE
									   ELSE temp.OldCateID
								  END)
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) 
			AND temp.DWCategoryGroupID = CONST_CATEGORY_INACTIVE; 
			
		UPDATE 	Temp_NewClassification AS temp 
			INNER JOIN CTS_DataCenter.CustomerCategory AS c ON temp.NewCategoryID = c.CategoryID
		SET temp.NewIsDangerProbation = c.IsDangerProbation;
		
		UPDATE Temp_NewClassification AS temp 
		SET temp.SourceTypeID = (CASE	WHEN (temp.OldCategoryGroupID IS NULL 
													OR temp.OldCategoryGroupID = CONST_CATEGORY_NEWMEMBER) 
												AND temp.NewCategoryGroupID = CONST_CATEGORY_NEWMEMBER 
													THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
										WHEN temp.OldCategoryGroupID IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_INACTIVE) 
												AND temp.NewCategoryGroupID NOT IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_INACTIVE) 
													THEN CONST_SOURCETYPE_AFTER10TICKETS 
										WHEN temp.OldCategoryGroupID = CONST_CATEGORY_PROBATION 
												AND temp.NewCategoryGroupID IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK) 
													THEN CONST_SOURCETYPE_PASSPROBATION
										WHEN (temp.OldCategoryGroupID IS NULL 
													OR temp.OldCategoryGroupID IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_NORMALMEMBER,CONST_CATEGORY_VIP)) 
												AND temp.NewCategoryGroupID = CONST_CATEGORY_INACTIVE 
													THEN CONST_SOURCETYPE_INACTIVENORMAL 
										WHEN temp.OldCategoryGroupID IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK,CONST_CATEGORY_PROBATION) 
												AND temp.NewCategoryGroupID = CONST_CATEGORY_INACTIVE 
													THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
										WHEN temp.OldCategoryGroupID = temp.NewCategoryGroupID 
													THEN CONST_SOURCETYPE_SAMECATEGORY
										ELSE CONST_SOURCETYPE_SCANONSCHEDULE
									END)
		WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);     
		
		UPDATE Temp_NewClassification AS temp
		SET temp.IsDataChanged = 0
		WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE 
			AND temp.NewCategoryID = temp.OldCategoryID;
			
		UPDATE Temp_NewClassification AS tmp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.NewCategoryID
		SET tmp.TargetCC = CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCPriority <> -1)
									THEN CASE
											WHEN cate.CustomerClass = lv_VVIPCC 
												THEN lv_VVIPCC                                                
											WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority 
													AND tmp.SpecialCCDangerProbation = 1 
												THEN lv_LicVIPCC_Suspicious
											WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority 
													AND tmp.SpecialCCDangerProbation IS NOT NULL 
												THEN lv_LicVIPCC_Danger
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 
												THEN lv_LicVIPCC_Suspicious
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 
												THEN lv_LicVIPCC_Danger                                                
											WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCPriority <> -1 
													AND tmp.SpecialCCPriority < lv_LicBAPriority 
												THEN tmp.SpecialCC  
											WHEN tmp.IsLicenseeBA = 1 AND cate.Priority > lv_LicBAPriority 
												THEN lv_LicBACC                                            
											WHEN tmp.SpecialCCPriority <> -1 AND cate.Priority > tmp.SpecialCCPriority 
												THEN tmp.SpecialCC
											ELSE cate.CustomerClass
										END
								ELSE tmp.SpecialCC
							END
		WHERE 	tmp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_IGNOREPROBATION);
		
		INSERT INTO Temp_OldCustomerClass(CustID)
		SELECT DISTINCT temp.CustID
		FROM Temp_NewClassification AS temp
		WHERE temp.IsDataChanged  = 0;
		
		INSERT IGNORE INTO Temp_UpdateCustomerClass(CustID,CustomerClass)
		WITH CTE_LatestLog AS (
			SELECT h.CustID, MAX(h.LastModifiedDate) AS LatestInsertDate
			FROM Temp_OldCustomerClass AS t
				INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON t.CustID = h.CustID
			GROUP BY h.CustID
		),
		CTE_LatestHistory AS (
			SELECT h.CustID, h.TargetCC
			FROM CTE_LatestLog AS l
				INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON l.CustID = h.CustID 
																					AND l.LatestInsertDate = h.LastModifiedDate
		)
		SELECT 	cte.CustID
			,	cte.TargetCC
		FROM CTE_LatestHistory AS cte;
		
		UPDATE Temp_UpdateCustomerClass AS c
			INNER JOIN Temp_NewClassification AS t ON c.CustID = t.CustID
		SET t.OldTargetCC = c.CustomerClass;
		
		UPDATE Temp_NewClassification AS tmp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON tmp.OldCategoryID = cate.CategoryID
		SET tmp.TargetCC = 	CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCPriority <> -1)
										THEN CASE
												WHEN cate.CustomerClass = lv_VVIPCC 
													THEN lv_VVIPCC
												WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority 
														AND tmp.SpecialCCDangerProbation = 1 
													THEN lv_LicVIPCC_Suspicious
												WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority 
														AND tmp.SpecialCCDangerProbation IS NOT NULL 
													THEN lv_LicVIPCC_Danger
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 
													THEN lv_LicVIPCC_Suspicious
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 
													THEN lv_LicVIPCC_Danger
												WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCPriority <> -1 
														AND tmp.SpecialCCPriority < lv_LicBAPriority 
													THEN tmp.SpecialCC    
												WHEN tmp.IsLicenseeBA = 1 AND cate.Priority > lv_LicBAPriority 
													THEN lv_LicBACC                                            
												WHEN tmp.SpecialCCPriority <> -1 AND cate.Priority > tmp.SpecialCCPriority 
													THEN tmp.SpecialCC
												ELSE cate.CustomerClass
											END
								ELSE tmp.SpecialCC
							END
			,	tmp.NewCateID = tmp.OldCategoryID
			, 	tmp.NewCateGroup = tmp.OldCategoryGroupID
			,	tmp.NewIsDangerProbation = cate.IsDangerProbation
		WHERE tmp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;
	
		UPDATE Temp_NewClassification
		SET 	IsDataChanged = 1
			,	SourceTypeID = (CASE 
									WHEN  NewCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK) 
										THEN CONST_SOURCETYPE_PASSPROBATION
									WHEN NewCateGroup = CONST_CATEGORY_INACTIVE AND NewCateID = CONST_CATEGORY_NORMALINACTIVE 
										THEN CONST_SOURCETYPE_INACTIVENORMAL 
									WHEN NewCateGroup = CONST_CATEGORY_INACTIVE AND NewCateID = CONST_CATEGORY_PROPUNTERINACTIVE 
										THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
									ELSE CONST_SOURCETYPE_SCANONSCHEDULE
								END)
			,	ActionType = CONST_ACTIONTYPE_UPDATE
		WHERE IsDataChanged = 0 
			AND ((TargetCC <> OldTargetCC) OR (OldCateID <> NewCateID))
			AND (SourceTypeID IN (CONST_SOURCETYPE_SAMECATEGORY, CONST_SOURCETYPE_LESSTHAN10TICKETS )
				OR ActionType = CONST_ACTIONTYPE_IGNOREPROBATION);    
		/*		
		UPDATE Temp_NewClassification AS temp 
			INNER JOIN CTS_DataCenter.CategoryToDangerLevel AS d ON d.CategoryID = temp.NewCateID 
																	AND d.IsLicensee = temp.IsLicensee 
																	AND d.TypeID = 1
		SET 	temp.TargetDangerLevel = d.DangerLevel
		WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);   
		*/
	
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
		
		INSERT IGNORE INTO Temp_LicVIPCust(CustID, CategoryID, CustomerClass)
		SELECT	temp.CustID
			,	CASE WHEN cat.IsDangerProbation = 1 THEN CONST_CATEID_LICVIPSUSPICIOUS ELSE CONST_CATEID_LICVIPDANGEROUS END
			,	CASE WHEN cat.IsDangerProbation = 1 THEN CONST_CC_LICVIPSUSPICIOUS ELSE CONST_CC_LICVIPDANGEROUS END
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = temp.NewCategoryID
		WHERE temp.IsLicenseeVIP = 1;
		;    

		UPDATE Temp_NewClassification AS temp
			INNER JOIN Temp_LicVIPCust AS tmpVip ON temp.CustID = tmpVip.CustID
		SET temp.TargetCC = IFNULL(temp.SpecialCC, tmpVip.CustomerClass)
		WHERE temp.SpecialCC IS NULL; 
		
		INSERT IGNORE INTO Temp_LastHistory(CustID, CategoryID, TargetCC)
		SELECT temp.CustID, tmpHis.CategoryID, tmpHis.TargetCC
		FROM Temp_NewClassification AS temp,
		LATERAL (	SELECT h.CategoryID, h.TargetCC
					FROM CTS_DataCenter.CTSCustomerClassification_History AS h
					WHERE h.CustID = temp.CustID 
					ORDER BY ID DESC
					LIMIT 1) AS tmpHis;
					
		UPDATE Temp_NewClassification AS temp
			INNER JOIN Temp_LastHistory AS tmpHis ON temp.CustID = tmpHis.CustID
		SET temp.IsDataChanged = 1
		WHERE temp.NewCategoryGroupID <> tmpHis.CategoryID 
			OR temp.TargetCC <> tmpHis.TargetCC; 
		
		
	END IF;
	
END$$
DELIMITER ;