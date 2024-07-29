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
	DECLARE CONST_CATEID_VVIP 							INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 				INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 				INT;
	DECLARE CONST_CATEID_LICBA 							INT;
	DECLARE CONST_CATEID_INACTIVENORMAL 				INT;
	DECLARE CONST_CATEID_INACTIVESMART	 				INT;
	DECLARE CONST_CATEID_NEW			 				INT;
	
	DECLARE CONST_CATEGROUPID_INACTIVE					INT;
	DECLARE CONST_CATEGROUPID_NEW						INT;
	DECLARE CONST_CATEGROUPID_NORMAL					INT;
	DECLARE CONST_CATEGROUPID_GOOD						INT;
	DECLARE CONST_CATEGROUPID_PROBATION					INT;
	DECLARE CONST_CATEGROUPID_SMART						INT;
	DECLARE CONST_CATEGROUPID_RISKY						INT;
	
	
	DECLARE CONST_PARENTID_VVIP 						INT;
	DECLARE CONST_PARENTID_WRAPPER 						INT;
	DECLARE CONST_PARENTID_PA 							INT;
    DECLARE CONST_PARENTID_POTENTIALPA      			INT;
    DECLARE CONST_PARENTID_NORMAL		    			INT;
	
	DECLARE CONST_CC_VVIP			 					INT;
	DECLARE CONST_CC_LICVIPSUSPICIOUS 					INT;
	DECLARE CONST_CC_LICVIPDANGEROUS 					INT;
	DECLARE CONST_CC_LICBA			 					INT;
	
    DECLARE CONST_ACTIONTYPE_INSERT 					INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 					INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 					INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_EXISTEDPA 					INT DEFAULT 3;
    DECLARE CONST_ACTIONTYPE_EXISTEDVVIP				INT DEFAULT 4;
    DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 			INT DEFAULT 5;
	
    DECLARE CONST_SOURCETYPE_SAMECATEGORY 				INT DEFAULT 0;
    DECLARE CONST_SOURCETYPE_LESSTHAN10TICKETS 			INT DEFAULT 1;
	DECLARE	CONST_SOURCETYPE_AFTER10TICKETS 			INT DEFAULT 2;
	DECLARE CONST_SOURCETYPE_SCANONSCHEDULE				INT DEFAULT 3;
    DECLARE CONST_SOURCETYPE_PASSPROBATION 				INT DEFAULT 4;
    DECLARE CONST_SOURCETYPE_INACTIVENORMAL 			INT DEFAULT 18;
    DECLARE CONST_SOURCETYPE_INACTIVEPROPUNTER			INT DEFAULT 19;
	
    DECLARE lv_LicBAPriority							SMALLINT UNSIGNED;
	DECLARE	lv_CurrentDateTime							DATETIME DEFAULT CURRENT_TIME();
	
	-- --------------------------------------------
	SET CONST_CATEID_VVIP 								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_CATEID_INACTIVENORMAL 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INACTIVENORMAL');
	SET CONST_CATEID_INACTIVESMART 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INACTIVESMART');
	SET CONST_CATEID_NEW		 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_NEW');
	
	SET CONST_CATEGROUPID_INACTIVE						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_INACTIVE');
	SET CONST_CATEGROUPID_NEW							= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_NEW');
	SET CONST_CATEGROUPID_NORMAL						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_NORMAL');
	SET CONST_CATEGROUPID_GOOD							= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_GOOD');
	SET CONST_CATEGROUPID_PROBATION						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_PROBATION');
	SET CONST_CATEGROUPID_SMART							= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_SMART');
	SET CONST_CATEGROUPID_RISKY							= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_RISKY');
	
	SET CONST_PARENTID_VVIP 							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 								= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_PARENTID_POTENTIALPA						= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
	SET CONST_PARENTID_NORMAL	 						= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
	
	SET CONST_CC_VVIP			 						= CTS_DC_CategoryTypeParent_Get ('CONST_CC_VVIP');
	SET CONST_CC_LICVIPSUSPICIOUS 						= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICVIPSUSPICIOUS');
	SET CONST_CC_LICVIPDANGEROUS	 					= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICVIPDANGEROUS');
	SET CONST_CC_LICBA				 					= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICBA');

	-- -------------------------------------
	-- SELECT CategoryPriority
	SELECT CustomerClassPriority
    INTO lv_LicBAPriority
    FROM CTS_DataCenter.CustomerCategory 
	WHERE CategoryID = CONST_CATEID_LICBA;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Old;
	CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Old (
			CustID					BIGINT UNSIGNED
		,	CTSCustID				BIGINT UNSIGNED
		,	SubscriberID			INT UNSIGNED
		,	RoleID					INT
		,	ParentID				INT UNSIGNED
		,	CategoryID				INT UNSIGNED
		,	CategoryGroupID			INT UNSIGNED
		,	ExistCategoryID			INT UNSIGNED
		,	RelevantCategoryID		INT UNSIGNED
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
		,	IsFromImperva			BIT(1)
		,	InsertTime				DATETIME
		,	TVSRequestID			BIGINT UNSIGNED			
		,	IsTVSParlay				BIT(1) 
		,	SportType				SMALLINT DEFAULT NULL 
		,	TVSIssueTypeID			TINYINT DEFAULT NULL 
		,	IsMarkedDirectly		BIT(1)
		,	TWRobotCounter			INT
		,	SpecialCC	       		SMALLINT 
		,	CustomerClass			SMALLINT 
		,	CategoryPriority		SMALLINT UNSIGNED
		,	IsPAProbation			BIT(1)
		,	IsNew					BIT(1) DEFAULT 1
		,	IsRemove				BIT(1) DEFAULT NULL
		,	INDEX IX_Temp_CC_Old (CustID,CategoryID)
	);
	
	
	DROP TEMPORARY TABLE IF EXISTS Temp_UpdateCustomerClass;    
	CREATE TEMPORARY TABLE Temp_UpdateCustomerClass(	  
			CustID					BIGINT UNSIGNED	PRIMARY KEY
		,	CustomerClass 			SMALLINT
	); 
	
	
	DROP TEMPORARY TABLE IF EXISTS Temp_LicVIPCust;
	CREATE TEMPORARY TABLE Temp_LicVIPCust(
			CustID					BIGINT UNSIGNED PRIMARY KEY
		,	CategoryID 				INT UNSIGNED
		,	CustomerClass 			INT UNSIGNED
	); 
	
	DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;
	CREATE TEMPORARY TABLE Temp_LastHistory(
			CustID					BIGINT UNSIGNED PRIMARY KEY
		,	CategoryID				INT UNSIGNED
		,	TargetCC				INT UNSIGNED
	);

	IF ip_InputFlowID = 9 THEN
		INSERT IGNORE INTO Temp_LastHistory(CustID, CategoryID, TargetCC)
		SELECT temp.CustID, tmpHis.CategoryID, tmpHis.TargetCC
		FROM Temp_NewClassification AS temp,
		LATERAL (	SELECT h.CategoryID, h.TargetCC
					FROM CTS_DataCenter.CTSCustomerClassification_History AS h
					WHERE h.CustID = temp.CustID 
					ORDER BY ID DESC
					LIMIT 1) AS tmpHis
		;
	
		INSERT IGNORE INTO Temp_CTSCustomerClassification_Old (
				CustID, CTSCustID, SubscriberID, RoleID, CategoryID, CategoryGroupID, IsNew)
		SELECT 	temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.RoleID, ccs.CategoryID, ccs.CategoryGroupID
			, 	0 AS IsNew
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																			AND cls.ParentID = CONST_PARENTID_NORMAL
			INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = cls.CategoryID
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION);

		UPDATE Temp_NewClassification AS temp
			LEFT JOIN Temp_CTSCustomerClassification_Old AS o ON temp.CustID = o.CustID
		SET 	temp.OldCategoryGroupID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGROUPID_NEW ELSE o.CategoryGroupID END
			,	temp.OldCategoryID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGROUPID_NEW ELSE o.CategoryID END
			-- ,	temp.ActionType = CASE 	WHEN o.CustID IS NULL OR (o.IsNew = 1 AND o.IsRemove = 0) OR (o.IsNew = 0 AND o.IsRemove = 1)
			,	temp.ActionType = CASE 	WHEN o.CustID IS NULL /* OR (o.IsNew = 0 AND o.IsRemove = 1)*/
											THEN CONST_ACTIONTYPE_INSERT 
										ELSE CONST_ACTIONTYPE_UPDATE END
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		UPDATE Temp_NewClassification AS temp
			LEFT JOIN Temp_CTSCustomerClassification_Old AS o ON temp.CustID = o.CustID
		SET 	temp.OldCategoryGroupID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGROUPID_NEW ELSE o.CategoryGroupID END
			,	temp.OldCategoryID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGROUPID_NEW ELSE o.CategoryID END
		WHERE temp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;
		
		UPDATE Temp_NewClassification AS temp 
		SET temp.NewCategoryGroupID = temp.DWCategoryGroupID 
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
		
		UPDATE 	Temp_NewClassification AS temp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS tag ON tag.CategoryGroupID = temp.NewCategoryGroupID
																	AND tag.TaggingType = temp.TaggingType 
																	AND tag.TaggingID = temp.TaggingID
		SET temp.NewCategoryID = IFNULL(tag.CategoryID, temp.NewCategoryGroupID)
		 WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) 
			AND temp.DWCategoryGroupID <> CONST_CATEGROUPID_INACTIVE; /*Exclude Inactive category*/
			
		UPDATE Temp_NewClassification AS temp 
		SET temp.NewCategoryID = DWCategoryID
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) 
			AND temp.DWCategoryGroupID = CONST_CATEGROUPID_INACTIVE; 

		/* UPDATE NewIsDangerProbation */    
    	UPDATE 	Temp_NewClassification AS temp 
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON temp.NewCategoryID = cate.CategoryID
    	SET temp.NewIsDangerProbation = cate.IsDangerProbation;

		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsDataChanged = 0
			/*,	temp.ActionType = CONST_ACTIONTYPE_UPDATE */
		WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE/*CONST_ACTIONTYPE_INSERT*/
			AND (temp.NewCategoryID = temp.OldCategoryID) /*OR temp.NewCategoryGroupID = temp.OldCategoryGroupID);*/
			AND NOT EXISTS (SELECT 1 
							FROM Temp_LastHistory AS h 
							WHERE h.CustID = temp.CustID 
								AND h.CategoryID IS NULL 
								AND h.TargetCC IS NULL); /*Unmark PA*/
								
		UPDATE Temp_NewClassification AS temp 
		SET temp.SourceTypeID = (CASE	WHEN (temp.OldCategoryGroupID IS NULL 
													OR temp.OldCategoryGroupID = CONST_CATEGROUPID_NEW) 
												AND temp.NewCategoryGroupID = CONST_CATEGROUPID_NEW 
													THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
										WHEN temp.OldCategoryGroupID IN (CONST_CATEGROUPID_NEW,CONST_CATEGROUPID_INACTIVE) 
												AND temp.NewCategoryGroupID NOT IN (CONST_CATEGROUPID_NEW,CONST_CATEGROUPID_INACTIVE) 
													THEN CONST_SOURCETYPE_AFTER10TICKETS 
										WHEN temp.OldCategoryGroupID = CONST_CATEGROUPID_PROBATION 
												AND temp.NewCategoryGroupID IN (CONST_CATEGROUPID_SMART, CONST_CATEGROUPID_RISKY) 
													THEN CONST_SOURCETYPE_PASSPROBATION
										WHEN (temp.OldCategoryGroupID IS NULL 
													OR temp.OldCategoryGroupID IN (CONST_CATEGROUPID_NEW,CONST_CATEGROUPID_NORMAL,CONST_CATEGROUPID_GOOD)) 
												AND temp.NewCategoryGroupID = CONST_CATEGROUPID_INACTIVE 
													THEN CONST_SOURCETYPE_INACTIVENORMAL 
										WHEN temp.OldCategoryGroupID IN (CONST_CATEGROUPID_SMART,CONST_CATEGROUPID_RISKY,CONST_CATEGROUPID_PROBATION) 
												AND temp.NewCategoryGroupID = CONST_CATEGROUPID_INACTIVE 
													THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
										WHEN temp.OldCategoryGroupID = temp.NewCategoryGroupID 
													THEN CONST_SOURCETYPE_SAMECATEGORY
										ELSE CONST_SOURCETYPE_SCANONSCHEDULE
									END)
		WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
		/*	
		UPDATE Temp_NewClassification AS tmp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.NewCategoryID
		SET tmp.TargetCC = CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCCatePriority <> -1)
									THEN CASE
											WHEN cate.CustomerClass = CONST_CC_VVIP 
												THEN CONST_CC_VVIP                                                
											WHEN tmp.IsLicenseeVIP = 1 AND cate.CategoryPriority > tmp.SpecialCCCatePriority 
													AND tmp.SpecialCCDangerProbation = 1 
												THEN CONST_CC_LICVIPSUSPICIOUS
											WHEN tmp.IsLicenseeVIP = 1 AND cate.CategoryPriority > tmp.SpecialCCCatePriority 
													AND tmp.SpecialCCDangerProbation IS NOT NULL 
												THEN CONST_CC_LICVIPDANGEROUS
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 
												THEN CONST_CC_LICVIPSUSPICIOUS
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 
												THEN CONST_CC_LICVIPDANGEROUS                                                
											WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCCatePriority <> -1 
													AND tmp.SpecialCCCatePriority < lv_LicBAPriority 
												THEN tmp.SpecialCC  
											WHEN tmp.IsLicenseeBA = 1 AND cate.CategoryPriority > lv_LicBAPriority 
												THEN CONST_CC_LICBA                                            
											WHEN tmp.SpecialCCCatePriority <> -1 AND cate.CategoryPriority > tmp.SpecialCCCatePriority 
												THEN tmp.SpecialCC
											ELSE cate.CustomerClass
										END
								ELSE tmp.SpecialCC
							END
		WHERE 	tmp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_IGNOREPROBATION);*/
	
		UPDATE Temp_NewClassification AS tmp 
			LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.NewCategoryID
		SET tmp.TargetCC = CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCCatePriority <> -1)
									THEN CASE
											WHEN cate.CustomerClass = CONST_CC_VVIP 
												THEN CONST_CC_VVIP                                                
											WHEN tmp.IsLicenseeVIP = 1 AND cate.CustomerClassPriority > tmp.SpecialCCCatePriority 
													AND tmp.SpecialCCDangerProbation = 1 
												THEN CONST_CC_LICVIPSUSPICIOUS
											WHEN tmp.IsLicenseeVIP = 1 AND cate.CustomerClassPriority > tmp.SpecialCCCatePriority 
													AND tmp.SpecialCCDangerProbation IS NOT NULL 
												THEN CONST_CC_LICVIPDANGEROUS
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 
												THEN CONST_CC_LICVIPSUSPICIOUS
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 
												THEN CONST_CC_LICVIPDANGEROUS                                                
											WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCCatePriority <> -1 
													AND tmp.SpecialCCCatePriority < lv_LicBAPriority 
												THEN tmp.SpecialCC  
											WHEN tmp.IsLicenseeBA = 1 AND cate.CustomerClassPriority > lv_LicBAPriority 
												THEN CONST_CC_LICBA                                            
											WHEN tmp.SpecialCCCatePriority <> -1 AND cate.CustomerClassPriority > tmp.SpecialCCCatePriority 
												THEN tmp.SpecialCC
											ELSE cate.CustomerClass
										END
								ELSE tmp.SpecialCC
							END
		WHERE 	tmp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_IGNOREPROBATION);
		
		INSERT IGNORE INTO Temp_UpdateCustomerClass(CustID, CustomerClass)
		WITH CTE_LatestLog AS (
			SELECT h.CustID, MAX(h.LastModifiedDate) AS LatestInsertDate
			FROM Temp_NewClassification AS temp
				INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON temp.CustID = h.CustID
			WHERE temp.IsDataChanged  = 0
			GROUP BY h.CustID
		),CTE_LatestHistory AS (
			SELECT h.CustID, h.TargetCC
			FROM CTE_LatestLog AS l
				INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON l.CustID = h.CustID 
																					AND l.LatestInsertDate = h.LastModifiedDate
		)
		SELECT 	cte.CustID
			,	cte.TargetCC
		FROM CTE_LatestHistory AS cte;
		
		UPDATE Temp_UpdateCustomerClass AS c
			INNER JOIN Temp_NewClassification AS temp ON c.CustID = temp.CustID
		SET temp.OldTargetCC = c.CustomerClass;
		/*
		UPDATE Temp_NewClassification AS tmp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON tmp.OldCategoryID = cate.CategoryID
		SET tmp.TargetCC = 	CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCCatePriority <> -1)
										THEN CASE
												WHEN cate.CustomerClass = CONST_CC_VVIP 
													THEN CONST_CC_VVIP
												WHEN tmp.IsLicenseeVIP = 1 AND cate.CategoryPriority > tmp.SpecialCCCatePriority 
														AND tmp.SpecialCCDangerProbation = 1 
													THEN CONST_CC_LICVIPSUSPICIOUS
												WHEN tmp.IsLicenseeVIP = 1 AND cate.CategoryPriority > tmp.SpecialCCCatePriority 
														AND tmp.SpecialCCDangerProbation IS NOT NULL 
													THEN CONST_CC_LICVIPDANGEROUS
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 
													THEN CONST_CC_LICVIPSUSPICIOUS
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 
													THEN CONST_CC_LICVIPDANGEROUS
												WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCCatePriority <> -1 
														AND tmp.SpecialCCCatePriority < lv_LicBAPriority 
													THEN tmp.SpecialCC    
												WHEN tmp.IsLicenseeBA = 1 AND cate.CategoryPriority > lv_LicBAPriority 
													THEN CONST_CC_LICBA                                            
												WHEN tmp.SpecialCCCatePriority <> -1 AND cate.CategoryPriority > tmp.SpecialCCCatePriority 
													THEN tmp.SpecialCC
												ELSE cate.CustomerClass
											END
								ELSE tmp.SpecialCC
							END
			,	tmp.NewCategoryID = tmp.OldCategoryID
			, 	tmp.NewCategoryGroupID = tmp.OldCategoryGroupID
			,	tmp.NewIsDangerProbation = cate.IsDangerProbation
		WHERE tmp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;*/
		
		UPDATE Temp_NewClassification AS tmp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON tmp.OldCategoryID = cate.CategoryID
		SET tmp.TargetCC = 	CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCCatePriority <> -1)
										THEN CASE
												WHEN cate.CustomerClass = CONST_CC_VVIP 
													THEN CONST_CC_VVIP
												WHEN tmp.IsLicenseeVIP = 1 AND cate.CustomerClassPriority > tmp.SpecialCCCatePriority 
														AND tmp.SpecialCCDangerProbation = 1 
													THEN CONST_CC_LICVIPSUSPICIOUS
												WHEN tmp.IsLicenseeVIP = 1 AND cate.CustomerClassPriority > tmp.SpecialCCCatePriority 
														AND tmp.SpecialCCDangerProbation IS NOT NULL 
													THEN CONST_CC_LICVIPDANGEROUS
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 
													THEN CONST_CC_LICVIPSUSPICIOUS
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 
													THEN CONST_CC_LICVIPDANGEROUS
												WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCCatePriority <> -1 
														AND tmp.SpecialCCCatePriority < lv_LicBAPriority 
													THEN tmp.SpecialCC    
												WHEN tmp.IsLicenseeBA = 1 AND cate.CustomerClassPriority > lv_LicBAPriority 
													THEN CONST_CC_LICBA                                            
												WHEN tmp.SpecialCCCatePriority <> -1 AND cate.CustomerClassPriority > tmp.SpecialCCCatePriority 
													THEN tmp.SpecialCC
												ELSE cate.CustomerClass
											END
								ELSE tmp.SpecialCC
							END
			,	tmp.NewCategoryID = tmp.OldCategoryID
			, 	tmp.NewCategoryGroupID = tmp.OldCategoryGroupID
			,	tmp.NewIsDangerProbation = cate.IsDangerProbation
		WHERE tmp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;
		
		UPDATE Temp_NewClassification
		SET 	IsDataChanged = 1
			,	SourceTypeID = (CASE 
									WHEN  NewCategoryGroupID IN (CONST_CATEGROUPID_SMART, CONST_CATEGROUPID_RISKY) 
										THEN CONST_SOURCETYPE_PASSPROBATION
									WHEN NewCategoryGroupID = CONST_CATEGROUPID_INACTIVE AND NewCategoryID = CONST_CATEID_INACTIVENORMAL 
										THEN CONST_SOURCETYPE_INACTIVENORMAL 
									WHEN NewCategoryGroupID = CONST_CATEGROUPID_INACTIVE AND NewCategoryID = CONST_CATEID_INACTIVESMART 
										THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
									ELSE CONST_SOURCETYPE_SCANONSCHEDULE
								END)
			,	ActionType = CONST_ACTIONTYPE_UPDATE
		WHERE IsDataChanged = 0 
			AND ((TargetCC <> OldTargetCC) OR (OldCategoryID <> NewCategoryID))
			AND (SourceTypeID IN (CONST_SOURCETYPE_SAMECATEGORY, CONST_SOURCETYPE_LESSTHAN10TICKETS )
				OR ActionType = CONST_ACTIONTYPE_IGNOREPROBATION);    
		
		UPDATE Temp_NewClassification AS temp 
			INNER JOIN CTS_DataCenter.CustomerCategory AS d ON d.CategoryID = temp.NewCategoryID 
		SET 	temp.TargetDangerLevel = CASE WHEN temp.IsLicensee = 1 THEN d.Ext_ABIDangerLevel_Licensee ELSE d.Ext_ABIDangerLevel_Credit END
		WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE); 
	
	ELSEIF (ip_InputFlowID IN (5,6,7,8) OR ip_InputFlowID IN (115,116,117,118)) THEN 
	/*ip_InputFlowID IN (5,6,7,8) - Insert
	ip_InputFlowID IN (115,116,117,118) - Rescan*/
		
		DROP TEMPORARY TABLE IF EXISTS Temp_PAWinlossStatus;    
		CREATE TEMPORARY TABLE Temp_PAWinlossStatus(	
				CustID					BIGINT UNSIGNED PRIMARY KEY
			, 	WinlossStatus			SMALLINT /*LOSING  = 0 (PROBATION), WINNING = 2 (NOT PROBATION);*/
		);
		
		DROP TEMPORARY TABLE IF EXISTS Temp_CustProbationStatus ;
		CREATE TEMPORARY TABLE Temp_CustProbationStatus(
				CustID 					BIGINT UNSIGNED PRIMARY KEY
			,	CTSCustID 				BIGINT UNSIGNED
			,	IsPAProbation			TINYINT(1)
			,	TurnoverRM				DECIMAL(20,4)
			,	WinlossRM				DECIMAL(20,4)
			, 	BetCount				BIGINT 
			, 	ActiveDays				INT
			,	WinlossStatus			TINYINT
			,	IsLicensee				TINYINT(1)
		); 
		
		/*delete: existing VVIP */
		DELETE temp
		FROM Temp_NewClassification AS temp
		WHERE temp.IsExistVVIP 	= 1;

		INSERT INTO Temp_PAWinlossStatus(CustID, WinlossStatus)
		SELECT DISTINCT 
				temp.CustID
			,	CASE WHEN cc.IsDangerProbation = 1 THEN 0 ELSE 2 END AS WinlossStatus
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID
            INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cls.CategoryID = cc.CategoryID
		WHERE cls.ParentID IN (CONST_PARENTID_PA, CONST_PARENTID_POTENTIALPA);
		
		UPDATE Temp_NewClassification AS temp
			INNER JOIN Temp_PAWinlossStatus AS r ON temp.CustID = r.CustID
		SET temp.WinlossStatus 		= r.WinlossStatus,
			temp.IsPAProbation 		= (CASE WHEN r.WinlossStatus = 0 THEN 1 ELSE 0 END)
		WHERE temp.WinlossStatus 	= 1;
		
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
							AND cat.IsPAProbation = temp.IsPAProbation 
						LIMIT 1) AS tmpCat
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
						WHERE cat.CategoryID = temp.RelevantCategoryID 
						LIMIT 1) AS tmpCat
		SET 	temp.RelevantCategoryGroupID 	= tmpCat.CategoryGroupID	
			,	temp.RelevantCategoryID 		= tmpCat.CategoryGroupID
			,	temp.RelevantIsPAProbation 		= tmpCat.IsPAProbation;   
		
		/*Insert into CTSCustomerClassification*/
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsFromOldPA 	= 1
		--	,	temp.IsDataChanged 	= 1
			,	temp.DataChangeType	= 1
		WHERE 	temp.IsExistVVIP 	= 1 
			AND temp.ParentID = CONST_PARENTID_PA;
		
		INSERT IGNORE INTO Temp_CTSCustomerClassification_Old(
				CustID, CTSCustID, SubscriberID, ParentID, CategoryID, CategoryGroupID, ExistCategoryID, RelevantCategoryID
			, 	Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsFromTVS
			, 	IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, InsertTime, TVSRequestID, IsTVSParlay
			, 	SportType, TVSIssueTypeID, IsMarkedDirectly, SpecialCC, CustomerClass, CategoryPriority, IsPAProbation
			, 	IsNew, IsRemove) 
		SELECT	cls.CustID
			,	cls.CTSCustID
			,	cls.SubscriberID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN NULL ELSE cc.ParentID END AS ParentID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN cc.CategoryID ELSE cc.CategoryGroupID END AS CategoryID
			,	CASE WHEN cls.ParentID = CONST_PARENTID_NORMAL THEN NULL ELSE cc.CategoryGroupID END AS CategoryGroupID /*NORMAL NOT CONSIDER TO WIN/LOSE >> SET NULL*/
			,	cls.CategoryID AS ExistCategoryID
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
			,	cls.IsFromImperva
			,	lv_CurrentDateTime AS InsertTime
			,	cls.TVSRequestID
			,	cls.IsParlay
			,	cls.SportType
			,	cls.IssueTypeID
			,	cls.IsMarkedDirectly
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
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID AND cc.IsActive = 1
		WHERE cls.ParentID IN (CONST_PARENTID_PA,CONST_PARENTID_POTENTIALPA,CONST_PARENTID_NORMAL)
			AND temp.IsExistVVIP = 0;

		/*delete: priority existing < new */
		DELETE temp
		FROM Temp_NewClassification AS temp 
			INNER JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp.CustID = temp_old.CustID		
		WHERE temp_old.IsNew = 0 AND temp_old.IsRemove IS NULL;
		
		/*delete: priority existing < new */
		/*delete: normal - smart/risky*/
		DELETE temp_old
		FROM Temp_CTSCustomerClassification_Old AS temp_old 
		WHERE (temp_old.IsNew = 0 AND temp_old.IsRemove IS NULL)
			OR (temp_old.ParentID IS NULL AND temp_old.IsNew = 0 AND temp_old.IsRemove = 0);
			
		/*existing PotentialPA + PA - existing and new: not the same CateGroup*/
		UPDATE Temp_NewClassification AS temp 
			LEFT JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp.CustID = temp_old.CustID	
																			AND temp_old.ParentID IS NOT NULL
																			AND temp_old.IsNew = 0
																			AND temp.NewCategoryGroupID = temp_old.CategoryGroupID
		SET 	temp.IsDataChanged 		= 1
		WHERE 	temp.IsDataChanged 		= 0
			AND temp_old.CustID IS NULL;
		
		/*existing PotentialPA + PA - existing and new: the same CateGroup*/
		UPDATE Temp_NewClassification AS temp 
			INNER JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp.CustID = temp_old.CustID	
																			AND temp_old.ParentID IS NOT NULL
																			AND temp_old.IsNew = 0
																			AND temp.RelevantCategoryGroupID = temp_old.CategoryGroupID
		SET 	temp.DataChangeType 	= 1 
			,	temp.IsDataChanged 		= 1 
			,	temp.OldCategoryID 		= temp_old.ExistCategoryID
			,	temp.LastModifiedDate 	= IFNULL(temp.LastModifiedDate, temp_old.LastModifiedDate)
			,	temp.ActionType 		= CONST_ACTIONTYPE_UPDATE
			,	temp.CreatedBy 			= temp_old.CreatedBy;  
		
		/*existing PotentialPA + PA - existing and new: the same CateGroup - not change WinlossStatus (KEEP)*/
		DELETE temp_old
		FROM Temp_CTSCustomerClassification_Old AS temp_old
			INNER JOIN Temp_NewClassification AS temp ON temp_old.ParentID IS NOT NULL AND temp_old.IsNew = 0
															AND temp.RelevantCategoryGroupID = temp_old.CategoryGroupID
															AND temp.WinlossStatus <> 1;
		
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
		
		/*existing PotentialPA + PA - existing and new: the same CateGroup - WinlossStatus <> KEEP*/
		INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, ParentID, DWCategoryID, DWCategoryGroupID, OldCategoryID, NewCategoryID, NewCategoryGroupID
			, 	TargetCC,  TargetDangerLevel, ToEvidenceID, Remark, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsMarkedDirectly
			, 	IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, IsDataChanged, DataChangeType
			, 	LastModifiedDate, CreatedBy, IsPAProbation, TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID)
		SELECT 		temp_old.CustID
			,	temp_old.CTSCustID
			,	temp_old.SubscriberID
			,	temp_old.ParentID
			,	temp_old.ExistCategoryID AS DWCategoryID
			,	temp_old.ExistCategoryID AS DWCategoryGroupID
			,	temp_old.ExistCategoryID AS OldCategoryID
			,	tmpLt.CategoryGroupID AS NewCategoryID
			,	tmpLt.CategoryGroupID AS NewCategoryGroupID
			,	(CASE 	WHEN temp_old.SpecialCC IS NOT NULL THEN temp_old.SpecialCC 
						ELSE IFNULL(tmpLt.CustomerClass,-99) END) AS TargetCC
			, 	(CASE 	WHEN tmpCp.IsLicensee = 1 THEN tmpLt.Ext_ABIDangerLevel_Licensee
						WHEN tmpCp.IsLicensee = 0 THEN tmpLt.Ext_ABIDangerLevel_Credit END) AS TargetDangerLevel
			,	(CASE 	WHEN tmpCp.IsLicensee = 1 THEN tmpLt.Ext_EvidenceID_Licensee
						WHEN tmpCp.IsLicensee = 0 THEN tmpLt.Ext_EvidenceID_Credit ELSE NULL END) AS ToEvidenceID
			,	temp_old.Remark
			,	tmpCp.TurnoverRM
			,	tmpCp.WinlossRM
			,	tmpCp.BetCount
			,	tmpCp.ActiveDays
			,	temp_old.IsMarkedDirectly
			,	temp_old.IsFromTVS
			,	temp_old.IsFromTW
			,	temp_old.IsFromCTS
			,	temp_old.IsFromAI
			,	temp_old.IsFromImperva
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
			INNER JOIN Temp_CustProbationStatus AS tmpCp ON temp_old.ParentID IS NOT NULL AND temp_old.IsNew = 0 AND temp_old.IsRemove <> 1
																AND tmpCp.CustID = temp_old.CustID 
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
		;        
		
		INSERT IGNORE INTO Temp_LicVIPCust(CustID, CategoryID, CustomerClass)
		SELECT	temp.CustID
			,	CASE WHEN cat.IsDangerProbation = 1 THEN CONST_CATEID_LICVIPSUSPICIOUS ELSE CONST_CATEID_LICVIPDANGEROUS END
			,	CASE WHEN cat.IsDangerProbation = 1 THEN CONST_CC_LICVIPSUSPICIOUS ELSE CONST_CC_LICVIPDANGEROUS END
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = temp.NewCategoryID
		WHERE temp.IsExistVVIP 	= 0
			AND temp.IsLicenseeVIP = 1;

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
					LIMIT 1) AS tmpHis
		WHERE temp.IsExistVVIP 	= 0;
					
		UPDATE Temp_NewClassification AS temp
			INNER JOIN Temp_LastHistory AS tmpHis ON temp.CustID = tmpHis.CustID
		SET temp.IsDataChanged = 1
		WHERE temp.NewCategoryGroupID <> tmpHis.CategoryID 
			OR temp.TargetCC <> tmpHis.TargetCC; 
		
	END IF;
	
END$$
DELIMITER ;