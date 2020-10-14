DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CustEvidence_InsertMultiple $$

CREATE PROCEDURE CTS_DC_CustEvidence_InsertMultiple (
		IN ip_NewAccountEvidences 	JSON    
    ,	IN ip_UserID 				INT
	, 	IN ip_IsOverride			BOOLEAN
    
    , 	OUT op_ErrorMessage 		VARCHAR(200))
    
sp: BEGIN
	/*
		Created:	20200608@Long.Luu
		Task:		Insert multiple customer-evidences [Redmine ID: 134489]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200608@Long.Luu [Redmine ID: 134489]: Created
			- 20200807@Casey.Huynh [Redmine ID: #138925]: Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster
			- 20200824@Roger.Le [Redmine ID: 137551]: Evidence Upload - Overrite the data
			- 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
	*/    
  
    DECLARE	lv_SPName 			VARCHAR(100) DEFAULT 'CTS_DC_CustEvidence_InsertMultiple'; 
    DECLARE	lv_CreatedDate		DATETIME;      
    DECLARE	lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET	lv_CreatedDate 		= CURRENT_TIME();
    SET @ip_UserID = 1027893;
     
    DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence;    
	CREATE TEMPORARY TABLE Temp_MultipleAccountEvidence 
    (	 
			CTSCustID		BIGINT UNSIGNED     
        , 	EvidenceID		SMALLINT UNSIGNED
        , 	Remark			VARCHAR(500)  
        , 	PRIMARY KEY	Temp_MultipleAccountEvidence(CTSCustID,EvidenceID) 
    );      
    
	DROP TABLE IF EXISTS Temp_AssociationException;
    CREATE TEMPORARY TABLE Temp_AssociationException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY	Temp_AssociationException(FromCTSCustID,ToCTSCustID)
	);
    
    DROP TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
        , 	PRIMARY KEY	Temp_AffectedDevices(CTSCustID,DCSDeviceID) 
	);
    
    INSERT INTO Temp_MultipleAccountEvidence(CTSCustID, EvidenceID, Remark)
	SELECT 	tmpTable.CTSCustID
		, 	tmpTable.EvidenceID
		, 	tmpTable.Remark
	FROM JSON_TABLE(ip_NewAccountEvidences,
		 "$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Comment"
		 )) AS tmpTable;  
         
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	IF (!ip_IsOverride AND EXISTS (	SELECT 1 
				FROM Temp_MultipleAccountEvidence AS t 
					LEFT JOIN CTS_DataCenter.CustEvidence AS ce ON t.CTSCustID = ce.CTSCustID AND t.EvidenceID = ce.EvidenceID
				WHERE ce.CTSCustID IS NOT NULL
					AND ce.EvidenceID IS NOT NULL
                    AND Level = 0)) THEN
		SET op_ErrorMessage = 'This Customer has already been flagged with this Evidence.';
		LEAVE sp;
	END IF;
      
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,  EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	t.EvidenceID
        ,	t.Remark
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDate
        ,	ip_UserID
    FROM Temp_MultipleAccountEvidence AS t;
	
    INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS a    
		INNER JOIN Temp_MultipleAccountEvidence AS t ON a.CTSCustID = t.CTSCustID;

    INSERT INTO Temp_AssociationException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
		INNER JOIN Temp_MultipleAccountEvidence AS t ON e.LeastCTSCustID_Order = t.CTSCustID
													OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, t.EvidenceID, t.Remark, 2, t.CTSCustID, lv_CreatedDate, ip_UserID
    FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN Temp_AssociationException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID		
    	AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customer Evidences', lv_CreatedDate, ip_UserID);
    
	# Sync Evidence to Category
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
        SELECT 	c.CustID
			, 	c.CTSCustID
			, 	c.SubscriberID
			, 	ec.CategoryID
			,   0
			, 	'Synced from Evidence'
			, 	CURRENT_TIMESTAMP()
			,   @ip_UserID
			,   CURRENT_TIMESTAMP()
			,   @ip_UserID
			,   CURRENT_DATE
		FROM Temp_MultipleAccountEvidence AS t
			INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec ON t.EvidenceID = ec.EvidenceID
			INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID;
    END IF;

	DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence;
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    
END$$
DELIMITER ;