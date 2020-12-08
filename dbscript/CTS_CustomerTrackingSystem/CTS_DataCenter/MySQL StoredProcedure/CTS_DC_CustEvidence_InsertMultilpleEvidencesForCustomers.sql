/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers`(IN ip_CustIds varchar(4000),IN ip_EvidenceCodes varchar(4000),OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200610@Long.Luu
		Task:		Insert multiple evidences for multiple customers [Redmine ID: #135585]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20200610@Long.Luu: Created [Redmine ID: #135585] 
            - 20201013@Long.Luu: Sync Evidence to Category [Redmine ID: #141756]
            - 20201020@Irena.Vo: Enhance logic Remove all category (Detail & General) [Redmine ID: #141756]
            - 20201111@Irena.Vo: Enhance logic Insert History for Evidence Category [Redmine ID: #145027]
            - 20201130@Irena.Vo: Enhance logic Insert new evidence (remove existed evidence category before) [Redmine ID: #141563]
            - 20201207@Irena.Vo: Update History Log  & Enhance logic  [Redmine ID: #145951]
            
		Param's Explanation(filered by):
		
		Example:
            -call CTS_DataCenter.CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers('43600693,43600889', '6.1', @op_ErrorMessage);
	*/    
   
    DECLARE		lv_SPName 			VARCHAR(100) DEFAULT 'CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers';  
	DECLARE		lv_CreatedDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE 	lv_CreatedBy        BIGINT DEFAULT 10278938;
    
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerList;
    CREATE TEMPORARY TABLE Temp_CustomerList (
			CustID			BIGINT UNSIGNED 
		,	CTSCustID		BIGINT UNSIGNED    
        ,	SubscriberID	INT
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceList;
    CREATE TEMPORARY TABLE Temp_EvidenceList (
			EvidenceID		SMALLINT UNSIGNED
        ,	EvidenceCode	VARCHAR(10)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
        , 	PRIMARY KEY		PK_Temp_AffectedDevices_CTSCustID_DCSDeviceID(CTSCustID,DCSDeviceID) 
	);
  
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
    CREATE TEMPORARY TABLE Temp_AssociatedException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY		PK_Temp_AssociatedException_FromCTSCustID_ToCTSCustID(FromCTSCustID,ToCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategoryMapping;    
	CREATE TEMPORARY TABLE Temp_CustCategoryMapping 
    (	  
			CustID		    BIGINT UNSIGNED
        ,   CategoryID      SMALLINT UNSIGNED
        ,   EvidenceID      SMALLINT UNSIGNED
        , 	INDEX 			IX_Temp_CustCategoryMapping_CustID_CategoryID_EvidenceID(CustID,CategoryID,EvidenceID)    
     );
	
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedHistoryOfRecords;    
	CREATE TEMPORARY TABLE Temp_ExistedHistoryOfRecords 
    (	  
			CustID				BIGINT UNSIGNED
        , 	CategoryID	        SMALLINT UNSIGNED 
        ,   TargetCC            TINYINT
        , 	INDEX 				IX_Temp_ExistedHistoryOfRecords_CustID(CustID)
        , 	INDEX 				IX_Temp_ExistedHistoryOfRecords_CategoryID_TargetCC(CategoryID,TargetCC)    
     );
     
	SET @sql = CONCAT("INSERT INTO Temp_CustomerList (CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET @sql = CONCAT("INSERT INTO Temp_EvidenceList (EvidenceCode) VALUES ('", REPLACE(ip_EvidenceCodes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
    /*	GET CUSTOMER INFO	*/
    UPDATE 		Temp_CustomerList AS t
	INNER JOIN 	CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID AND c.CustSubID = 0
    SET 		t.CTSCustID = c.CTSCustID
			,	t.SubscriberID = c.SubscriberID;
    
	/*	GET EVIDENCE INFO	*/
	UPDATE 		Temp_EvidenceList AS t
	INNER JOIN 	CTS_DataCenter.Evidence AS c ON t.EvidenceCode = c.EvidenceCode
    SET 		t.EvidenceID = c.EvidenceID;    
    
    /*	INSERT NEW FLAGGED EVIDENCE FOR CUSTOMERS	*/
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	e.EvidenceID
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDateTime
        ,	lv_CreatedBy
    FROM 	Temp_CustomerList AS t CROSS JOIN Temp_EvidenceList AS e;
    
    /*	GET AFFECTED EVIDENCES FOR CUSTOMERS	*/
    INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM 		CTS_DataCenter.AssociationByDevice AS a    
	INNER JOIN Temp_CustomerList AS t ON a.CTSCustID = t.CTSCustID;
    
    /*	GET ASSOCIATED EXCEPTIONS FOR CUSTOMERS	*/
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
	INNER JOIN Temp_CustomerList AS t ON e.LeastCTSCustID_Order = t.CTSCustID OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
    /*	INSERT NEW AFFECTED EVIDENCES FOR  CUSTOMERS	*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,EvidenceID, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, ev.EvidenceID, 2, t.CTSCustID, lv_CreatedDateTime, lv_CreatedBy
    FROM 		Temp_CustomerList AS t 
	INNER JOIN 	Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
	INNER JOIN 	CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
	LEFT JOIN  	CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID AND c.CustSubID = 0
	LEFT JOIN  	Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	CROSS JOIN  Temp_EvidenceList AS ev
	WHERE 		a.CTSCustID <> d.CTSCustID AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
    /*	WRITE LOG	*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customers - Evidences', lv_CreatedDateTime, lv_CreatedBy);
    
     /*	GET EXISTED CATEGORY FROM NAP CM	*/
	INSERT INTO Temp_ExistedHistoryOfRecords (CustID, CategoryID, TargetCC)
	SELECT DISTINCT cate.CustID, cate.CategoryID, map.CustomerClass
    FROM Temp_CustomerList AS t
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = t.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = cate.CategoryID
    WHERE cc.ParentID = 50 AND cate.CategoryID NOT BETWEEN 72 AND 80; 
    
    /*	SYNC EVIDENCE TO CATEGORY	*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1') THEN
		-- Ignore Pin category
        DELETE t
        FROM  Temp_CustomerList AS t
        INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin ON t.CustID = pin.CustID;
		
        -- Remove old General category
        DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
        INNER JOIN Temp_CustomerList AS t ON t.CustID = cate.CustID
        WHERE cc.ParentID = 200;
        
        -- Remove old Probation List
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN Temp_CustomerList AS t ON pro.CustID = t.CustID;
		
        -- Get category mapping by evidence
        INSERT INTO Temp_CustCategoryMapping(CustID,EvidenceID,CategoryID)
        SELECT DISTINCT t.CustID, ev.EvidenceID, e.CategoryID
        FROM Temp_CustomerList AS t CROSS JOIN  Temp_EvidenceList AS ev
        INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ev.EvidenceID;
        
        -- Remove old Evidence Category
        DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN Temp_CustCategoryMapping AS temp ON temp.CustID = cate.CustID AND temp.CategoryID = cate.CategoryID;
	    
        -- Insert new evidence category
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	DISTINCT t.CustID
			, 	t.CTSCustID
			, 	t.SubscriberID
			, 	a.CategoryID
			,   0
			, 	'Synced by Evidence'
			, 	lv_CreatedDateTime
			,   lv_CreatedBy
			,   lv_CreatedDateTime
			,   lv_CreatedBy
			,   DATE(lv_CreatedDateTime)
		FROM Temp_CustomerList AS t
			CROSS JOIN (	SELECT DISTINCT temp.CustID, temp.CategoryID
							FROM Temp_EvidenceList AS ev
							INNER JOIN Temp_CustCategoryMapping AS temp ON temp.EvidenceID = ev.EvidenceID) AS a ON a.CustID = t.CustID;
                            
        -- Insert log                    
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT 	DISTINCT t.CustID
			, 	t.CTSCustID
			, 	a.CategoryID
			,   0
			,   lv_CreatedDateTime
			,   lv_CreatedBy
            ,   0 -- insert
            ,   1 
			,   DATE(lv_CreatedDateTime)
            , 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass 
					 WHEN map.CategoryID IS NOT NULL THEN map.CustomerClass
					 ELSE -1 -- no mapping CC
				END
            ,   7 -- item name = Add from Evidence
		FROM Temp_CustomerList AS t
			CROSS JOIN (	SELECT DISTINCT temp.CustID, temp.CategoryID
							FROM Temp_EvidenceList AS ev
							INNER JOIN Temp_CustCategoryMapping AS temp ON temp.EvidenceID = ev.EvidenceID) AS a ON a.CustID = t.CustID
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON a.CategoryID = map.CategoryID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = t.CustID
        LEFT JOIN Temp_ExistedHistoryOfRecords AS e ON e.CustID = t.CustID AND e.TargetCC = map.CustomerClass
        WHERE e.TargetCC IS NULL;  
                            
    END IF;
    
    /*	GET LASTEST CUSTID LIST	*/
    SELECT DISTINCT t.CustId FROM Temp_CustomerList AS t;
 
END$$

DELIMITER ;