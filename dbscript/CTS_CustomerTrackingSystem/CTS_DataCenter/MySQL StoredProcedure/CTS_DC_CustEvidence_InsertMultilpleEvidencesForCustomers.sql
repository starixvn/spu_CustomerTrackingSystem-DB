/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers`(IN ip_CustIds varchar(4000),IN ip_EvidenceCodes varchar(4000),OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200610@Long.Luu
		Task:		Insert multiple evidences for multiple customers [Redmine ID: 135585]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20200610@Long.Luu: Created [Redmine ID: 135585] 
            - 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
            - 20201020@Irena.Vo [Redmine ID: #141756]: Enhance logic Remove all category (Detail & General) 
            - 20201111@Irena.Vo [Redmine ID: #145027]: Enhance logic Insert History for Evidence Category
            - 20201130@Irena.Vo [Redmine ID: #141563]: Enhance logic Insert new evidence (remove existed evidence category before)
              
            call CTS_DataCenter.CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers('43600693,43600889', '6.1', @op_ErrorMessage);
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEviCategories;    
	CREATE TEMPORARY TABLE Temp_ExistedEviCategories 
    (	  
			CustID		    BIGINT UNSIGNED
        ,   CategoryID      SMALLINT UNSIGNED
        ,   EvidenceID      SMALLINT UNSIGNED
        , 	INDEX 			IX_Temp_ExistedEviCategories_CustID_CategoryID_EvidenceID(CustID,CategoryID,EvidenceID)    
     );
	
	SET @sql = CONCAT("INSERT INTO Temp_CustomerList (CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET @sql = CONCAT("INSERT INTO Temp_EvidenceList (EvidenceCode) VALUES ('", REPLACE(ip_EvidenceCodes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
    /*GET CUSTOMER INFO*/
    UPDATE 		Temp_CustomerList AS t
	INNER JOIN 	CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID AND c.CustSubID = 0
    SET 		t.CTSCustID = c.CTSCustID
			,	t.SubscriberID = c.SubscriberID;
    
	/*GET EVIDENCE INFO*/
	UPDATE 		Temp_EvidenceList AS t
	INNER JOIN 	CTS_DataCenter.Evidence AS c ON t.EvidenceCode = c.EvidenceCode
    SET 		t.EvidenceID = c.EvidenceID;    
    
    /*INSERT NEW FLAGGED EVIDENCE FOR CUSTOMERS*/
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	e.EvidenceID
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDateTime
        ,	lv_CreatedBy
    FROM 	Temp_CustomerList AS t CROSS JOIN Temp_EvidenceList AS e;
    
    /*GET AFFECTED EVIDENCES FOR CUSTOMERS*/
    INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM 		CTS_DataCenter.AssociationByDevice AS a    
	INNER JOIN Temp_CustomerList AS t ON a.CTSCustID = t.CTSCustID;
    
    /*GET ASSOCIATED EXCEPTIONS FOR CUSTOMERS*/
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
	INNER JOIN Temp_CustomerList AS t ON e.LeastCTSCustID_Order = t.CTSCustID OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
    /*INSERT NEW AFFECTED EVIDENCES FOR  CUSTOMERS*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,EvidenceID, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, ev.EvidenceID, 2, t.CTSCustID, lv_CreatedDateTime, lv_CreatedBy
    FROM 		Temp_CustomerList AS t 
	INNER JOIN 	Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
	INNER JOIN 	CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
	LEFT JOIN  	CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID AND c.CustSubID = 0
	LEFT JOIN  	Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	CROSS JOIN  Temp_EvidenceList AS ev
	WHERE 		a.CTSCustID <> d.CTSCustID AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
    /*WRITE LOG*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customers - Evidences', lv_CreatedDateTime, lv_CreatedBy);
    
    /*SYNC EVIDENCE TO CATEGORY*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1') THEN
		DELETE a
        FROM Temp_CustomerList AS a
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS s ON a.CTSCustID = s.CTSCustID;
		
        DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
        INNER JOIN Temp_CustomerList AS a ON a.CustID = cate.CustID
			CROSS JOIN  Temp_EvidenceList AS ev  
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ev.EvidenceID
        WHERE cc.ParentID IN (1, 200);
        
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN Temp_CustomerList AS a ON pro.CustID = a.CustID 
			CROSS JOIN Temp_EvidenceList AS ev 
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ev.EvidenceID;
		
        -- Get existed Cust Category Evidences
        INSERT INTO Temp_ExistedEviCategories(CustID,EvidenceID,CategoryID)
        SELECT DISTINCT cate.CustID, ce.EvidenceID, cate.CategoryID
        FROM CTS_DataCenter.CustEvidence AS ce
        INNER JOIN Temp_CustomerList AS a ON a.CTSCustID = ce.FromCustID AND ce.Level = 0
			CROSS JOIN  Temp_EvidenceList AS ev ON ce.EvidenceID <> ev.EvidenceID
        INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = a.CustID
        INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND e.CategoryID = cate.CategoryID;
        
        -- Remove old Evidence Category
        DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN Temp_CustomerList AS t ON t.CustID = cate.CustID
              CROSS JOIN  Temp_EvidenceList AS ev
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ev.EvidenceID AND e.CategoryID = cate.CategoryID
        INNER JOIN Temp_ExistedEviCategories AS ex ON ex.CustID = cate.CustID AND cate.CategoryID = ex.CategoryID;
	
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
			CROSS JOIN (	SELECT DISTINCT ec.CategoryID
							FROM Temp_EvidenceList AS e
							INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec ON e.EvidenceID = ec.EvidenceID) AS a;
                            
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
		SELECT 	DISTINCT t.CustID
			, 	t.CTSCustID
			, 	a.CategoryID
			,   0
			,   lv_CreatedDateTime
			,   lv_CreatedBy
            ,   0
            ,   1
			,   DATE(lv_CreatedDateTime)
		FROM Temp_CustomerList AS t
			CROSS JOIN (	SELECT DISTINCT ec.CategoryID
							FROM Temp_EvidenceList AS e
							INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec ON e.EvidenceID = ec.EvidenceID) AS a;    
                            
    END IF;
    
	-- Return distinct CustID mapping CC to mainDB
    SELECT DISTINCT temp.CustId FROM  Temp_CustomerList AS temp;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEviCategories;    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceList;
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerList;
    
END$$

DELIMITER ;