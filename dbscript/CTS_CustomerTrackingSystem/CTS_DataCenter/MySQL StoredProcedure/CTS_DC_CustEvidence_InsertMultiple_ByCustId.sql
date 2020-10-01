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
           - [20200807@Casey.Huynh]:[138925] Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster
		   - 20200824@Roger.Le[Redmine ID: 137551]: Evidence Upload - Overrite the data
	*/    
  
    DECLARE	vr_SPName 		VARCHAR(100) DEFAULT 'CTS_DC_CustEvidence_InsertMultiple_ByCustId';  
    DECLARE	vr_CreatedDate	DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET	vr_CreatedDate 		= CURRENT_TIME();
     
    DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccountEvidence;    
	CREATE TEMPORARY TABLE tmpMultipleAccountEvidence 
    (	 
			CTSCustID		BIGINT UNSIGNED     
		,	CustID			BIGINT UNSIGNED     
        , 	EvidenceID		SMALLINT UNSIGNED
        , 	Remark			VARCHAR(500)  
        , 	PRIMARY KEY	tmpMultipleAccountEvidence(CustID,CTSCustID,EvidenceID) 
    );      
    
	DROP TABLE IF EXISTS tmpAssociationException;
    CREATE TEMPORARY TABLE tmpAssociationException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY	tmpAssociationException(FromCTSCustID,ToCTSCustID)
	);
    
    DROP TABLE IF EXISTS tmpAffectedDevices;
    CREATE TEMPORARY TABLE tmpAffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
        , 	PRIMARY KEY	tmpAffectedDevices(CTSCustID,DCSDeviceID) 
	);
    
    INSERT INTO tmpMultipleAccountEvidence(CustID, EvidenceID, Remark)
	SELECT 	tmpTable.CustID
		, 	tmpTable.EvidenceID
		, 	tmpTable.Remark
	FROM JSON_TABLE(ip_NewAccountEvidences,
		 "$[*]" COLUMNS(
			  CustID 	BIGINT UNSIGNED		PATH "$.CustID"
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Comment"
		 )) AS tmpTable;  
         
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    UPDATE tmpMultipleAccountEvidence t
		INNER JOIN CTS_DataCenter.CTSCustomer cus ON t.CustID = cus.CustID AND cus.CustSubID = 0
    SET t.CTSCustID = cus.CTSCustID;
      
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,  EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	t.EvidenceID
        ,	t.Remark
        ,	0 
        ,	t.CTSCustID
        ,	vr_CreatedDate
        ,	ip_UserID
    FROM tmpMultipleAccountEvidence AS t;
	
    INSERT INTO tmpAffectedDevices(CTSCustID, DCSDeviceID)
    SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS a    
		INNER JOIN tmpMultipleAccountEvidence AS t ON a.CTSCustID = t.CTSCustID;

    INSERT INTO tmpAssociationException(FromCTSCustID, ToCTSCustID)
    SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException AS e
		INNER JOIN tmpMultipleAccountEvidence AS t ON e.LeastCTSCustID_Order = t.CTSCustID
													OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT a.CTSCustID, t.EvidenceID, t.Remark, 2, t.CTSCustID, vr_CreatedDate, ip_UserID
    FROM tmpMultipleAccountEvidence AS t
		INNER JOIN tmpAffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN tmpAssociationException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID		
    	AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, vr_SPName, 'Insert bunch of Customer Evidences by CustId', vr_CreatedDate, ip_UserID);

	DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccountEvidence;
	DROP TEMPORARY TABLE IF EXISTS tmpAssociationException;
	DROP TEMPORARY TABLE IF EXISTS tmpAffectedDevices;
    
END$$
DELIMITER ;