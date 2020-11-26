/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertMultiple`(IN ip_NewAccountEvidences json,IN ip_UserID int,IN ip_IsOverride tinyint,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
BEGIN
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
            - 20201020@Irena.Vo [Redmine ID: #141756]: Enhance logic Remove all category (Detail & General)
            - 20201111@Irena.Vo [Redmine ID: #145027]: Enhance logic Insert History for Evidence Category
			- 20201116@Adam.Tran[Redmine ID: 141563]: Implement Cust Evidence from file
            
            call CTS_DataCenter.CTS_DC_CustEvidence_InsertMultiple
			('[{"CTSCustID": 221882500, "EvidenceID": 45, "Comment": "na test 1"},{"CTSCustID":221882500, "EvidenceID": 46, "Comment":"na test 2"},
			{"CTSCustID":221882532, "EvidenceID": 45, "Comment":"na test 3"}]', 8, 1, @op_ErrorMessage);
	*/    
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_InsertMultiple';    
    DECLARE		lv_CreatedDateTime 	DATETIME DEFAULT CURRENT_TIME();   

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
     
    DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence;    
	CREATE TEMPORARY TABLE Temp_MultipleAccountEvidence 
    (	 
			CTSCustID		BIGINT UNSIGNED     
        , 	EvidenceID		SMALLINT UNSIGNED       
        , 	Remark			VARCHAR(500)
		,	CreatedBy		INT UNSIGNED
        , 	PRIMARY KEY		PK_Temp_MultipleAccountEvidence_CTSCustID_EvidenceID(CTSCustID,EvidenceID) 
    );      
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
        , 	PRIMARY KEY		PK_Temp_AffectedDevices_CTSCustID_DCSDeviceID(CTSCustID,DCSDeviceID) 
	);
    
	DROP TEMPORARY TABLE IF EXISTS   Temp_AssociatedException;
    CREATE TEMPORARY TABLE Temp_AssociatedException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY		PK_Temp_AssociatedException_FromCTSCustID_ToCTSCustID(FromCTSCustID,ToCTSCustID)
	);
    
    INSERT INTO Temp_MultipleAccountEvidence(CTSCustID, EvidenceID, Remark, CreatedBy)
	SELECT 	tmpTable.CTSCustID
		, 	tmpTable.EvidenceID
		, 	tmpTable.Remark
		,	tmpTable.CreatedBy
	FROM JSON_TABLE(ip_NewAccountEvidences,
		 "$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"			 
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Remark"
			, CreatedBy		INT	UNSIGNED		PATH "$.CreatedBy"	
		 )) AS tmpTable;  
         
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  	
    
    /*IGNORE CUSTOMERS HAS NOT Override AND EXISTED EVIDENCE BEFORE*/
	
	IF (!ip_IsOverride) THEN
		DELETE t
		FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN CTS_DataCenter.CustEvidence AS ce ON t.CTSCustID = ce.CTSCustID AND t.EvidenceID = ce.EvidenceID
		WHERE ce.Level = 0;
	END IF; 
    
    /*INSERT NEW FLAGGED EVIDENCE HAS Override*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,  EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	t.CTSCustID
		,	t.EvidenceID
        ,	t.Remark
        ,	0 
        ,	t.CTSCustID
        ,	lv_CreatedDateTime
        ,	t.CreatedBy
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
    SELECT DISTINCT a.CTSCustID, t.EvidenceID, t.Remark, 2, t.CTSCustID, lv_CreatedDateTime, t.CreatedBy
    FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
    /*WRITE LOG*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customer Evidences', lv_CreatedDateTime, ip_UserID);              
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence; 
        
END$$

DELIMITER ;
