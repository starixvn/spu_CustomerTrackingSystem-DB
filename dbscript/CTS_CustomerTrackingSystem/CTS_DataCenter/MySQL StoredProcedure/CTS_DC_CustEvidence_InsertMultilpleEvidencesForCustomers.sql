DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers $$

CREATE PROCEDURE CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers (
		IN ip_CustIds 				VARCHAR(4000)
    ,   IN ip_EvidenceCodes 		VARCHAR(4000)
    
    , 	OUT op_ErrorMessage 		VARCHAR(200))
    
sp: BEGIN
	/*
		Created:	20200610@Long.Luu
		Task:		Insert multiple evidences for multiple customers [Redmine ID: 135585]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200610@Long.Luu: Created [Redmine ID: 135585]
            - 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
	*/    
   
    DECLARE	lv_SPName 			VARCHAR(100) DEFAULT 'CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers';  
    DECLARE	lv_CreatedDate		DATETIME;      
    DECLARE	lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET	lv_CreatedDate 			= CURRENT_TIME(); 
    SET @ip_UserID = 1027893;
     
    DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccountEvidence;    
	CREATE TEMPORARY TABLE tmpMultipleAccountEvidence 
    (	 
			CTSCustID		BIGINT UNSIGNED    
        , 	EvidenceID		SMALLINT UNSIGNED
        , 	Remark			VARCHAR(500)  
        , 	PRIMARY KEY	tmpMultipleAccountEvidence(CTSCustID,EvidenceID) 
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountList;
    CREATE TEMPORARY TABLE Temp_AccountList (
			CustID			BIGINT UNSIGNED    
		,	CTSCustID		BIGINT UNSIGNED    
        ,	SubscriberID	SMALLINT
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_AccountList (CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_EvidenceList;
    CREATE TEMPORARY TABLE Temp_EvidenceList (
			EvidenceID		SMALLINT UNSIGNED    
        ,	EvidenceCode	VARCHAR(10)
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_EvidenceList (EvidenceCode) VALUES ('", REPLACE(ip_EvidenceCodes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    # START
    SET SQL_SAFE_UPDATES = 0;
    UPDATE Temp_AccountList AS t
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID AND c.CustSubID = 0
    SET t.CTSCustID = c.CTSCustID
		,	t.SubscriberID = c.SubscriberID;
        
	UPDATE Temp_EvidenceList AS t
		INNER JOIN CTS_DataCenter.Evidence AS c ON t.EvidenceCode = c.EvidenceCode
    SET t.EvidenceID = c.EvidenceID;    
    
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	e.EvidenceID
        ,	''
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDate
        ,	@ip_UserID
    FROM Temp_AccountList AS t
		CROSS JOIN Temp_EvidenceList AS e;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;       
    INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS a    
		INNER JOIN Temp_AccountList AS t ON a.CTSCustID = t.CTSCustID;

    INSERT INTO Temp_AssociationException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
		INNER JOIN Temp_AccountList AS t ON e.LeastCTSCustID_Order = t.CTSCustID
													OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, ev.EvidenceID, '', 2, t.CTSCustID, lv_CreatedDate, @ip_UserID
    FROM Temp_AccountList AS t
		INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID AND c.CustSubID = 0
        LEFT JOIN Temp_AssociationException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
        CROSS JOIN Temp_EvidenceList AS ev
	WHERE a.CTSCustID <> d.CTSCustID		
    	AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customers - Evidences', lv_CreatedDate, @ip_UserID);
    
    # Sync Evidence to Category
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1') THEN
		DELETE a
        FROM Temp_AccountList AS a
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS s ON a.CTSCustID = s.CTSCustID;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	t.CustID
			, 	t.CTSCustID
			, 	t.SubscriberID
			, 	a.CategoryID
			,   0
			, 	'Synced from Evidence'
			, 	CURRENT_TIMESTAMP()
			,   @ip_UserID
			,   CURRENT_TIMESTAMP()
			,   @ip_UserID
			,   CURRENT_DATE
		FROM Temp_AccountList AS t
			CROSS JOIN (	SELECT DISTINCT ec.CategoryID
							FROM Temp_EvidenceList AS e
								INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec ON e.EvidenceID = ec.EvidenceID) AS a;
    END IF;
END$$
DELIMITER ;