/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService,ctsAPIAdmin,ctsAPI,ctsWebAdmin,ctsWeb" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_MappingPACategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_MappingPACategory`(
		IN 		ip_CustInfo 	JSON
	,	IN 		ip_SourceType	VARCHAR(20)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created: 20220328@Aries.Nguyen
		Task: Add new category/class for PA Probation [Redmine ID: #170468]
		DB: CTS_DataCenter
        
		Original:
		Revisions:
			- 20220328@Aries.Nguyen: Created [Redmine ID: #170468]
            - 20220505@Aries.Nguyen: Classification History - Wrong store Source Type for mark/remove PA [Redmine ID: #172401]

		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_MappingCategory ('[{"CustID": 123,"ReasonID": -1,"WinlossStatus": 1,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10}]','NAP');
*/ 
    DECLARE	CONST_CATEGORYID_ROBOTUSERS 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYID_BADROBOTUSERS 		INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_GOODROBOTUSERS 	INT DEFAULT 164;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    
    DECLARE CONST_ACTIONTYPE_INSERT 			INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 			INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_IGNOREPIN 			INT DEFAULT 4;
    
    DECLARE CONST_SOURCETYPE_INSERTNAPPA 		INT DEFAULT 6;
    DECLARE CONST_SOURCETYPE_ADDEVIDENCE 		INT DEFAULT 7;
    DECLARE	CONST_SOURCETYPE_REMOVENAPPA 		INT DEFAULT 8;
    DECLARE CONST_SOURCETYPE_INSERTROBOTUSERS	INT DEFAULT 11;
    DECLARE CONST_SOURCETYPE_RESCANBYNAPPA 		INT DEFAULT 15;
    
	/* Only use for IsRescan = 1 */
    DECLARE CONST_SOURCETYPE_REMOVEEVIDENCE 	INT DEFAULT 9;
    DECLARE CONST_SOURCETYPE_RESCANBYEVIDENCE 	INT DEFAULT 16;
	DECLARE CONST_SOURCETYPE_REMOVEVVIP 		INT DEFAULT 14;
    DECLARE CONST_SOURCETYPE_REMOVESPECIALCC 	INT DEFAULT 12;
	DECLARE CONST_SOURCETYPE_EXCLUDEASSWITHPA	INT DEFAULT 20;
    DECLARE CONST_SOURCETYPE_INCLUDEASSWITHPA	INT DEFAULT 21;
	DECLARE CONST_SOURCETYPE_RESCANBYPA 		INT DEFAULT 23;
    
    DECLARE lv_CreatedBy 						INT DEFAULT 10278938;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
		/*Cust info*/
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID			INT DEFAULT 0 
        ,	CurrencyID				INT
        ,	IsLicensee				BIT
		,	IsRobotException 		BIT DEFAULT 0 
        ,	CreatedBy 				INT UNSIGNED
        
        /*Data warehouse, mainDB  info*/
        , 	WinlossStatus			SMALLINT /*LOSING  = 0,KEEPSTATE = 1, WINNING = 2;*/
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        , 	RobotCounter			SMALLINT 
        
        /*Modify category info */
        , 	ReasonID				SMALLINT 
        , 	EvidenceID				SMALLINT 
        
        /*Mapping value*/
        ,	IsProbation				BIT DEFAULT 0	
        , 	CategoryID		    	SMALLINT
        ,	CategoryGroup     		SMALLINT    
		,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
        ,	SourceTypeID			SMALLINT
        , 	ActionType		    	SMALLINT DEFAULT 0 /* 0: Insert, 1: Update, 2: Remove, 4: Ignore PIN */
        ,	IsDataChanged			BIT DEFAULT 1 /*0: No change category => No Action*/
        ,	IsExisted 				BIT DEFAULT 0
        ,	IsExistedEvi			BIT DEFAULT 0
        , 	PRIMARY KEY     		PK_Temp_PA(CustID,CategoryID)  
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CateInfo;    
	CREATE TEMPORARY TABLE Temp_CateInfo(	  
			CustID					BIGINT UNSIGNED 
        , 	CategoryID		    	SMALLINT
		,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
        , 	PRIMARY KEY     		PK_Temp_CateInfo(CustID,CategoryID)  
     );
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification(	  
			CustID				BIGINT UNSIGNED 
		,	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	RelevantCategoryID  SMALLINT UNSIGNED
        ,	CategoryGroup     	SMALLINT UNSIGNED    
        ,	IsProbation			BIT DEFAULT 0
        ,	IsChangeByWinloss	BIT DEFAULT 0
        ,	SourceType			VARCHAR(50)
        ,	CreatedBy 			INT UNSIGNED
        ,	IsRemoveFromNAP 	BIT DEFAULT 0
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification(CustID, CategoryID)     
     );
	
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEvidence;    
	CREATE TEMPORARY TABLE Temp_ExistedEvidence(	  
			CustID			BIGINT UNSIGNED 
		,	CategoryID	    SMALLINT UNSIGNED
		, 	PRIMARY KEY		PK_Temp_ExistedEvidence(CustID, CategoryID)
    );
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, SubscriberID, CurrencyID, IsLicensee, IsRobotException,CreatedBy,
							   RobotCounter, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays,
							   ReasonID, EvidenceID,
                               CategoryID,CategoryGroup, ActionType, TargetCC)
	SELECT 	DISTINCT 
			cust.CustID
		,	cust.CTSCustID
        , 	cust.SubscriberID
        ,	cust.CurrencyID
        ,	(CASE WHEN mss.SubscriberGroupID = 2 THEN 1 ELSE 0 END) AS IsLicensee
        ,   CASE WHEN (mss.SubscriberGroupID <> 2 AND cust.SubscriberID IN (2,130)) OR (mss.SubscriberGroupID = 2 AND cust.CurrencyID IN (13,78)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        ,	IFNULL(pa.CreatedBy,lv_CreatedBy) AS CreatedBy
        
        , 	pa.RobotCounter
        , 	pa.WinlossStatus 
        , 	pa.TurnoverRM
        , 	pa.WinlossRM 
        , 	pa.BetCount 
        , 	pa.ActiveDays
        
        , 	pa.ReasonID 
        , 	pa.EvidenceID 
        
        ,	IFNULL(cate.CategoryID,pa.ReasonID) AS CategoryID
        ,	IFNULL(cate.CategoryGroup,pa.ReasonID)  AS CategoryGroup
        ,	CASE WHEN pin.CTSCustID IS NOT NULL THEN CONST_ACTIONTYPE_IGNOREPIN 
				 WHEN pa.ActionType IS NOT NULL THEN pa.ActionType 
				 WHEN pa.ReasonID = -1 THEN CONST_ACTIONTYPE_REMOVE
                 ELSE 0 END AS ActionType
		,	CASE WHEN sp.CTSCustID IS NOT NULL THEN sp.CustomerClass ELSE 0 END AS TargetCC
        
	FROM JSON_TABLE(ip_CustInfo,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED		PATH "$.CustID"
			,	ReasonID		SMALLINT 			PATH "$.ReasonID"	
			,	EvidenceID		SMALLINT 			PATH "$.EvidenceID"	
            ,	ActionType		SMALLINT 			PATH "$.ActionType"	
            
            ,	RobotCounter	SMALLINT 			PATH "$.RobotCounter"
            ,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
			,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
			,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
			, 	BetCount		BIGINT 				PATH "$.BetCount"
			, 	ActiveDays		INT 				PATH "$.ActiveDays"
            , 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
	)) AS pa
		INNER JOIN CTSCustomer AS cust ON pa.CustID = cust.CustID AND cust.CustSubID = 0
		INNER JOIN MappingSubscriberSite AS mss ON cust.SiteID = mss.SiteID
        LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = cust.CTSCustID
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cust.CustID = sp.CustID 
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON (pa.ReasonID IS NOT NULL 
																AND cate.ReasonID = pa.ReasonID 
																AND cate.SourceType = ip_SourceType
																AND ((pa.WinlossStatus = 0 AND cate.IsProbation = 1) OR 
																	 (pa.WinlossStatus <> 0 AND cate.IsProbation = 0) OR
                                                                     (pa.WinlossStatus IS NULL AND cate.IsProbation = 0)))  /*Map Cate <=> NAP*/
															  OR (pa.ReasonID IS NOT NULL 
																	AND cate.ReasonID = pa.ReasonID 
																	AND cate.SourceType = 'AI') /*Map Cate <=> AI*/
															  OR (pa.EvidenceID IS NOT NULL 
																	AND (cate.EvidenceID_Licensee = pa.EvidenceID OR cate.EvidenceID_Credit = pa.EvidenceID)
																	AND cate.SourceType = ip_SourceType
																	AND ((pa.WinlossStatus = 0 AND cate.IsProbation = 1) OR 
																		(pa.WinlossStatus <> 0 AND cate.IsProbation = 0) OR
																		(pa.WinlossStatus IS NULL AND cate.IsProbation = 0) OR
                                                                        (pa.ActionType = 2 ))); /*Map Cate <=> Evidence*/
 
                
	/*	2: EXCLUDE CUSTOMER */    
    CALL CTS_DC_ExcludeCustByCondition('Temp_PA');
    
    INSERT IGNORE INTO Temp_ExistedClassification (CustID,CTSCustID,CategoryID,CategoryGroup,IsProbation,RelevantCategoryID,SourceType,IsRemoveFromNAP,CreatedBy)
	SELECT 	clss.CustID
		,	clss.CTSCustID
		, 	clss.CategoryID  
        , 	cate.CategoryGroup
        ,	cate.IsProbation
        ,	cate.RelevantCategoryID
        ,	cate.SourceType
        ,	CASE WHEN ip_SourceType = 'NAP' AND temp. ActionType = CONST_ACTIONTYPE_REMOVE AND cate.SourceType = 'NAP' THEN 1
			ELSE 0 END AS IsRemoveFromNAP
		,	temp.CreatedBy
	FROM  Temp_PA AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON temp.CustID = clss.CustID AND clss.SportGroupID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = clss.CategoryID;
	
	UPDATE IGNORE Temp_PA AS pa 
	INNER JOIN	Temp_ExistedClassification AS ex ON ex.CustID = pa.CustID AND ex.CategoryID = pa.CategoryID
	SET		pa.ActionType = CONST_ACTIONTYPE_UPDATE
		,	pa.IsExisted = 1
	WHERE pa.ActionType = CONST_ACTIONTYPE_INSERT;
     
	UPDATE Temp_PA AS pa
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON pa.CategoryID = cate.CategoryID
	SET pa.TargetCC	= CASE  WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOTUSERS AND pa.IsRobotException = 1 THEN cate.CustomerClassException
							WHEN pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND pa.TargetCC > 0 THEN pa.TargetCC
							WHEN pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND pa.TargetCC  = 0 THEN IFNULL(cate.CustomerClass, -99) 
							WHEN pa.ActionType = CONST_ACTIONTYPE_REMOVE THEN -1
							ELSE  -99
							END 
            
	,	pa.CategoryID = CASE WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOTUSERS AND pa.IsRobotException = 1 THEN CONST_CATEGORYID_ROBOTUSERS
							 ELSE pa.CategoryID
							 END
            
            
	,	pa.TargetDangerLevel = CASE WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOTUSERS AND pa.IsRobotException = 1 AND pa.IsLicensee = 1 THEN cate.ABIDangerLevelException_Licensee
									WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOTUSERS AND pa.IsRobotException = 1 AND pa.IsLicensee = 0 THEN cate.ABIDangerLevelException_Credit
									WHEN pa.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
									WHEN pa.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit				
								END
	,	pa.IsProbation = cate.IsProbation;
	
    UPDATE Temp_PA AS pa 
    SET	pa.SourceTypeID = (CASE WHEN pa.CategoryID IN (CONST_CATEGORYID_ROBOTUSERS,CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_BADROBOTUSERS) THEN CONST_SOURCETYPE_INSERTROBOTUSERS /* Insert Robot User */
								  WHEN  pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) THEN IF(ip_SourceType = 'NAP', CONST_SOURCETYPE_INSERTNAPPA, CONST_SOURCETYPE_ADDEVIDENCE)  /* Insert & Update */
								  ELSE IF(ip_SourceType = 'NAP', CONST_SOURCETYPE_REMOVENAPPA, CONST_SOURCETYPE_REMOVEEVIDENCE)  /* Remove */
							 END)
	WHERE pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
    
    DELETE pa
    FROM Temp_PA AS pa
	INNER JOIN Temp_ExistedClassification AS e ON pa.CustID = e.CustID 
												AND pa.CategoryID = CONST_CATEGORYID_ROBOTUSERS 
												AND e.CategoryID IN (CONST_CATEGORYID_BADROBOTUSERS,CONST_CATEGORYID_GOODROBOTUSERS);
                                                     
    UPDATE Temp_ExistedClassification AS ex  
    SET ex.IsChangeByWinloss = 1
    WHERE  ex.RelevantCategoryID IS NOT NULL
		AND	EXISTS (SELECT 1 
				  FROM Temp_PA AS pa
                  WHERE pa.CustID = ex.CustID AND pa.IsProbation <> ex.IsProbation);
	
    UPDATE Temp_PA AS pa
    SET pa.IsDataChanged = 0
    WHERE EXISTS (SELECT 1 
				  FROM Temp_ExistedClassification AS ex
                  WHERE pa.CustID = ex.CustID AND (pa.CategoryGroup = ex.CategoryGroup OR pa.CategoryID = ex.CategoryID));
	
    DELETE 
    FROM Temp_PA
    WHERE ActionType = CONST_ACTIONTYPE_REMOVE AND ip_SourceType = 'NAP';
    
	INSERT INTO Temp_PA(CustID,CTSCustID,CategoryID,CategoryGroup,ActionType,IsDataChanged,TargetCC,SourceTypeID,CreatedBy)
    SELECT 	ex.CustID
		,	ex.CTSCustID
        ,	ex.CategoryID
        ,	ex.CategoryGroup
        ,	CONST_ACTIONTYPE_REMOVE AS ActionType
        ,	1 AS IsDataChanged
        ,	-1 AS TargetCC
        ,	CONST_SOURCETYPE_REMOVENAPPA AS SourceTypeID
        ,	ex.CreatedBy
	FROM Temp_ExistedClassification AS ex
    WHERE ex.IsRemoveFromNAP = 1;
    
    IF ip_SourceType = 'Evidence' THEN
		INSERT INTO Temp_ExistedEvidence(CustID,CategoryID)
		SELECT  pa.CustID
			,	pa.CategoryID
		FROM Temp_PA AS pa
		WHERE EXISTS (SELECT 1 
					  FROM  CTS_DataCenter.CustEvidence AS ce
					  WHERE pa.CTSCustID = ce.CTSCustID 
						AND pa.EvidenceID = ce.EvidenceID
						AND ce.Level = 0);
		UPDATE Temp_PA AS pa
        SET pa.IsExistedEvi = 1
        WHERE EXISTS (SELECT 1 
					  FROM  Temp_ExistedEvidence AS temp
					  WHERE temp.CustID = pa.CustID 
						AND temp.CategoryID = pa.CategoryID);
    END IF;
END$$
DELIMITER ;