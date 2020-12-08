/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertMultiple_ByCustId`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertMultiple_ByCustId`(IN ip_NewAccountEvidences json,IN ip_UserID int,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20201001@Harvey.Nguyen
		Task:		Insert multiple customer-evidences by custId [Redmine ID: #134489]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20200608@Long.Luu: Created [Redmine ID: #134489]
			- 20200807@Casey.Huynh: Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster [Redmine ID: #138925]
			- 20200824@Roger.Le: Evidence Upload - Overrite the data [Redmine ID: #137551]
			- 20201013@Long.Luu: Sync Evidence to Category [Redmine ID: #141756]
            - 20201020@Irena.Vo: Enhance logic Remove all category (Detail & General) [Redmine ID: #141756]
            - 20201111@Irena.Vo: Enhance logic Insert History for Evidence Category [Redmine ID: #145027]
			- 20201130@Irena.Vo: Enhance logic Insert new evidence (remove existed evidence category before) [Redmine ID: #141563]
            - 20201207@Irena.Vo: Enhance logic write log [RedmineID: #145951]
            
        call CTS_DataCenter.CTS_DC_CustEvidence_InsertMultiple_ByCustId
			('[{"CustID": 43600693, "EvidenceID": 45, "Comment": "na test 1"},{"CustID":43600693, "EvidenceID": 46, "Comment":"na test 2"},
			{"CustID":43600889, "EvidenceID": 45, "Comment":"na test 3"}]', 8, @op_ErrorMessage);
    
	*/    
	DECLARE		lv_SPName 			VARCHAR(100) DEFAULT 'CTS_DC_CustEvidence_InsertMultiple_ByCustId';  
	DECLARE		lv_CreatedDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE 	lv_CreatedBy        BIGINT DEFAULT 10278938;
    
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
     
    DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence;    
	CREATE TEMPORARY TABLE Temp_MultipleAccountEvidence 
    (	 
			CustID			BIGINT UNSIGNED    
        ,   CTSCustID		BIGINT UNSIGNED     
        ,	SubscriberID	INT UNSIGNED
        , 	EvidenceID		SMALLINT UNSIGNED
        , 	Remark			VARCHAR(500)  
        , 	PRIMARY KEY	    PK_Temp_MultipleAccountEvidence_CustID_EvidenceID(CustID,EvidenceID) 
    );      
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
        , 	PRIMARY KEY	    PK_Temp_AffectedDevices_CTSCustID_DCSDeviceID(CTSCustID,DCSDeviceID) 
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
    CREATE TEMPORARY TABLE Temp_AssociatedException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY	    PK_Temp_AssociatedException_FromCTSCustID_ToCTSCustID(FromCTSCustID,ToCTSCustID)
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
    
    INSERT INTO Temp_MultipleAccountEvidence(CustID, EvidenceID, Remark)
	SELECT 	tmpTable.CustID
		, 	tmpTable.EvidenceID
		, 	tmpTable.Remark
	FROM JSON_TABLE(ip_NewAccountEvidences,
		 "$[*]" COLUMNS(
			  CustID 		BIGINT UNSIGNED		PATH "$.CustID"
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Comment"
		 )) AS tmpTable;  
  
    /*	GET CUSTOMER INFO	*/
    UPDATE Temp_MultipleAccountEvidence AS t
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON t.CustID = cus.CustID AND cus.CustSubID = 0
    SET t.CTSCustID = cus.CTSCustID, t.SubscriberID = cus.SubscriberID;
    
    /*	INSERT NEW FLAGGED EVIDENCE	*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,  EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	t.EvidenceID
        ,	t.Remark
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDateTime
        ,	ip_UserID
    FROM Temp_MultipleAccountEvidence AS t;
	
    /*	GET AFFECTED DEVICES	*/
    INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS a    
	INNER JOIN Temp_MultipleAccountEvidence AS t ON a.CTSCustID = t.CTSCustID;
    
     /*	GET ASSOCIATED EXCEPTIONS	*/
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
	INNER JOIN Temp_MultipleAccountEvidence AS t ON e.LeastCTSCustID_Order = t.CTSCustID OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
    /*	INSERT NEW AFFECTED EVIDENCES	*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, t.EvidenceID, t.Remark, 2, t.CTSCustID, lv_CreatedDateTime, ip_UserID
    FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
     /*	WRITE LOG	*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customer Evidences by CustId', lv_CreatedDateTime, ip_UserID);

	/*	GET EXISTED CATEGORY FROM NAP CM	*/
	INSERT INTO Temp_ExistedHistoryOfRecords (CustID, CategoryID, TargetCC)
	SELECT DISTINCT cate.CustID, cate.CategoryID, map.CustomerClass
    FROM Temp_MultipleAccountEvidence AS t
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
        FROM  Temp_MultipleAccountEvidence AS t
        INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin ON t.CustID = pin.CustID;
        
        -- Remove old General category
        DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
        INNER JOIN Temp_MultipleAccountEvidence AS t ON t.CustID = cate.CustID
        WHERE cc.ParentID = 200;
        
        -- Remove old Probation List
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN Temp_MultipleAccountEvidence AS t ON t.CustID = pro.CustID;
		
        -- Get category mapping by evidence
        INSERT INTO Temp_CustCategoryMapping(CustID,EvidenceID,CategoryID)
        SELECT DISTINCT t.CustID, t.EvidenceID, e.CategoryID
        FROM Temp_MultipleAccountEvidence AS t
        INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = t.EvidenceID;
        
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
			, 	temp.CategoryID
			,   0
			, 	'Synced by Evidence'
			, 	lv_CreatedDateTime
			,   lv_CreatedBy
			,   lv_CreatedDateTime
			,   lv_CreatedBy
			,   DATE(lv_CreatedDateTime)
		FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_CustCategoryMapping AS temp ON temp.CustID = t.CustID AND temp.EvidenceID = t.EvidenceID;
        
        -- Insert log        
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT 	DISTINCT t.CustID
			, 	t.CTSCustID
			, 	temp.CategoryID
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
		FROM Temp_MultipleAccountEvidence AS t
        INNER JOIN Temp_CustCategoryMapping AS temp ON temp.CustID = t.CustID AND temp.EvidenceID = t.EvidenceID
        INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON temp.CategoryID = map.CategoryID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = t.CustID
        LEFT JOIN Temp_ExistedHistoryOfRecords AS e ON e.CustID = t.CustID AND e.TargetCC = map.CustomerClass
        WHERE e.TargetCC IS NULL;  
        
    END IF;
    
	/*	GET LASTEST CUSTID LIST	*/
    SELECT DISTINCT t.CustId FROM  Temp_MultipleAccountEvidence AS t;
  
END$$

DELIMITER ;