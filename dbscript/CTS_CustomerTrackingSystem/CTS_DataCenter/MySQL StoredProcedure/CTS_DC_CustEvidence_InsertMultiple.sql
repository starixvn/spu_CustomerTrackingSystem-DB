/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertMultiple`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertMultiple`(
		IN ip_NewAccountEvidences	JSON
	,	IN ip_UserID				INT
	,	IN ip_IsOverride			TINYINT
	
	,	OUT op_ErrorMessage			VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200608@Long.Luu
		Task:		Insert multiple customer-evidences [Redmine ID: #134489]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200608@Long.Luu: Created [Redmine ID: #134489]
			- 20200807@Casey.Huynh: Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster [Redmine ID: #138925]
			- 20200824@Roger.Le: Evidence Upload - Overrite the data [Redmine ID: #137551]
			- 20201013@Long.Luu: Sync Evidence to Category [Redmine ID: #141756]
            - 20201020@Irena.Vo: Enhance logic Remove all category (Detail & General) [Redmine ID: #141756]
            - 20201111@Irena.Vo: Enhance logic Insert History for Evidence Category [Redmine ID: #145027]
			- 20201116@Adam.Tran: Implement Cust Evidence from file [Redmine ID: #141563]
			- 20210107@Irena.Vo: Insert Error Log [RedmineID: #145951] 
			- 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]
		Param's Explanation (filtered by):
		Example:
            - CALL CTS_DataCenter.CTS_DC_CustEvidence_InsertMultiple('[{"CTSCustID": 221882500, "EvidenceID": 45, "Comment": "na test 1"},{"CTSCustID":221882500, "EvidenceID": 46, "Comment":"na test 2"}, {"CTSCustID":221882532, "EvidenceID": 45, "Comment":"na test 3"}]', 8, 1, @op_ErrorMessage);
	*/    
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_InsertMultiple';    
    DECLARE		lv_CreatedDateTime 	DATETIME DEFAULT CURRENT_TIME();   
    
	DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			TEXT         DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(6, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_NewAccountEvidences));
    END;
     
    DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccountEvidence;    
	CREATE TEMPORARY TABLE Temp_MultipleAccountEvidence(	 
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

	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceExist;
    CREATE TEMPORARY TABLE Temp_CustEvidenceExist(
			CTSCustID 		BIGINT UNSIGNED
        ,	EvidenceID 		INT
        , 	INDEX			IX_Temp_CustEvidenceExist_CTSCustID(CTSCustID,EvidenceID)
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
		 )
	) AS tmpTable;  
   
    /*IGNORE CUSTOMERS HAS NOT Override AND EXISTED EVIDENCE BEFORE*/
	IF (!ip_IsOverride) THEN
		INSERT INTO Temp_CustEvidenceExist(CTSCustID, EvidenceID)
		SELECT	t.CTSCustID
			,	t.EvidenceID
		FROM Temp_MultipleAccountEvidence AS t
			INNER JOIN CTS_DataCenter.CustEvidence AS ce ON t.CTSCustID = ce.CTSCustID AND t.EvidenceID = ce.EvidenceID
		WHERE ce.Level = 0;

		DELETE t
		FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_CustEvidenceExist AS ce ON t.CTSCustID = ce.CTSCustID AND t.EvidenceID = ce.EvidenceID;

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
    SELECT	DISTINCT 
			t.CTSCustID
		,	a.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice AS a    
		INNER JOIN Temp_MultipleAccountEvidence AS t ON a.CTSCustID = t.CTSCustID;
    
     /*GET ASSOCIATED EXCEPTIONS*/
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT	DISTINCT 
			t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order 
				 ELSE e.LeastCTSCustID_Order 
			END
    FROM CTS_DataCenter.CustException AS e
		INNER JOIN Temp_MultipleAccountEvidence AS t ON e.LeastCTSCustID_Order = t.CTSCustID OR e.GreatestCTSCustID_Order = t.CTSCustID;
    
    /*INSERT NEW AFFECTED EVIDENCES*/
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT	DISTINCT 
			a.CTSCustID
		,	t.EvidenceID
		,	t.Remark
		,	2
		,	t.CTSCustID
		,	lv_CreatedDateTime
		,	t.CreatedBy
    FROM Temp_MultipleAccountEvidence AS t
		INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
		INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
        LEFT JOIN Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID 
		AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
    /*WRITE LOG*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, 'Insert bunch of Customer Evidences', lv_CreatedDateTime, ip_UserID);              
    
END$$
DELIMITER ;