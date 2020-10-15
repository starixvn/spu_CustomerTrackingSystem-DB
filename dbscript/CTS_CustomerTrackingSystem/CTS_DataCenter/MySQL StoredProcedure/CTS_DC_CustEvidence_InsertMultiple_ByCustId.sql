DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CustEvidence_InsertMultiple_ByCustId $$

CREATE DEFINER=`fps`@`%` PROCEDURE CTS_DC_CustEvidence_InsertMultiple_ByCustId (
		IN ip_NewAccountEvidences 	JSON    
    ,	IN ip_UserID 				INT
    
    , 	OUT op_ErrorMessage 		VARCHAR(200))
sp: BEGIN
	/*
		Created:	20201001@Harvey.Nguyen
		Task:		Insert multiple customer-evidences by custId [Redmine ID: 134489]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200608@Long.Luu [Redmine ID: 134489]: Created
			- 20200807@Casey.Huynh [Redmine ID: #138925]: Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster
			- 20200824@Roger.Le [Redmine ID: 137551]: Evidence Upload - Overrite the data
			- 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
            
        call CTS_DataCenter.CTS_DC_CustEvidence_InsertMultiple_ByCustId_Na
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
        ,	SubscriberID	SMALLINT UNSIGNED
        , 	EvidenceID		SMALLINT UNSIGNED
        , 	Remark			VARCHAR(500)  
        , 	PRIMARY KEY	    PK_Temp_MultipleAccountEvidence_CustID_EvidenceID(CustID,EvidenceID) 
    );      
    
    DROP TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
        , 	PRIMARY KEY	    PK_Temp_AffectedDevices_CTSCustID_DCSDeviceID(CTSCustID,DCSDeviceID) 
	);
    
	DROP TABLE IF EXISTS Temp_AssociatedException;
    CREATE TEMPORARY TABLE Temp_AssociatedException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY	    PK_Temp_AssociatedException_FromCTSCustID_ToCTSCustID(FromCTSCustID,ToCTSCustID)
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
         
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	SET SQL_SAFE_UPDATES = 0;
    
    /*GET CUSTOMER INFO*/
    UPDATE Temp_MultipleAccountEvidence t
	INNER JOIN CTS_DataCenter.CTSCustomer cus ON t.CustID = cus.CustID AND cus.CustSubID = 0
    SET t.CTSCustID = cus.CTSCustID, t.SubscriberID = cus.SubscriberID;
    
    /*INSERT NEW FLAGGED EVIDENCE*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,  EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	t.EvidenceID
        ,	t.Remark
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDateTime
        ,	ip_UserID
    FROM Temp_MultipleAccountEvidence AS t;
	
    /*GET AFFECTED DEVICES*/
    INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS a    
	INNER JOIN Temp_MultipleAccountEvidence AS t ON a.CTSCustID = t.CTSCustID;
    
     /*GET ASSOCIATED EXCEPTIONS*/
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
	INNER JOIN Temp_MultipleAccountEvidence AS t ON e.LeastCTSCustID_Order = t.CTSCustID OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
    /*INSERT NEW AFFECTED EVIDENCES*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, t.EvidenceID, t.Remark, 2, t.CTSCustID, lv_CreatedDateTime, ip_UserID
    FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
     /*WRITE LOG*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customer Evidences by CustId', lv_CreatedDateTime, ip_UserID);

	/*SYNC EVIDENCE TO CATEGORY*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1') THEN
		DELETE a
        FROM Temp_MultipleAccountEvidence AS a
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS s ON a.CTSCustID = s.CTSCustID;
        
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	t.CustID
			, 	t.CTSCustID
			, 	t.SubscriberID
			, 	ec.CategoryID
			,   0
			, 	'Synced from Evidence'
			, 	lv_CreatedDateTime
			,   lv_CreatedBy
			,   lv_CreatedDateTime
			,   lv_CreatedBy
			,   DATE(lv_CreatedDateTime)
		FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec ON t.EvidenceID = ec.EvidenceID;
    END IF;
    
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence;
    
END$$
DELIMITER ;