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
			- 20201214@Irena.Vo: Move logic Sync to Category by new sp: SyncToCategory [RedmineID: #145951]
            
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

	-- Return CTSCustID, CustID, SubscriberID, EvidenceID, 0 (ActionType)
    SELECT DISTINCT temp.CustId
				,	temp.CTSCustId
                ,	temp.SubscriberId
                ,	temp.EvidenceId
                ,	0 AS ActionType
    FROM Temp_MultipleAccountEvidence AS temp;
  
END$$

DELIMITER ;