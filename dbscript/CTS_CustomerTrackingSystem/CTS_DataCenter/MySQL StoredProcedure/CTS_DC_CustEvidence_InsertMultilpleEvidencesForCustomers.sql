/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers`(IN ip_CustIds varchar(4000),IN ip_EvidenceCodes varchar(4000),OUT op_ErrorMessage VARCHAR(200))
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
			- 20201214-20210105@Irena.Vo: Move logic Sync to Category by new sp: SyncToCategory. Insert Error Log. Remove User Log [RedmineID: #145951] 
            
		Param's Explanation(filered by):
		
		Example:
            -call CTS_DataCenter.CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers('43600693,43600889', '6.1', @op_ErrorMessage);
	*/    
	DECLARE		lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE 	lv_CreatedBy        BIGINT DEFAULT 10278938;
  
	DECLARE 	op_ErrorNo 			INT DEFAULT 0;
    DECLARE 	op_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS @op_No = NUMBER;
		GET DIAGNOSTICS CONDITION @op_No 
			op_ErrorNo 			= 	MYSQL_ERRNO
        ,	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description, CreatedDate)
        VALUES(5, op_ErrorMessage, JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter1',ip_CustIds,'parameter2',ip_EvidenceCodes),lv_CurrentDateTime);
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

	SET @sql = CONCAT("INSERT INTO Temp_CustomerList (CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET @sql = CONCAT("INSERT INTO Temp_EvidenceList (EvidenceCode) VALUES ('", REPLACE(ip_EvidenceCodes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	
    /*	GET CUSTOMER INFO	*/
    UPDATE 		Temp_CustomerList AS t
	INNER JOIN 	CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID AND c.CustSubID = 0
    SET 		t.CTSCustID = c.CTSCustID,	t.SubscriberID = c.SubscriberID;
    
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
        ,	lv_CurrentDateTime
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
    SELECT DISTINCT a.CTSCustID, ev.EvidenceID, 2, t.CTSCustID, lv_CurrentDateTime, lv_CreatedBy
    FROM 		Temp_CustomerList AS t 
	INNER JOIN 	Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
	INNER JOIN 	CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
	LEFT JOIN  	CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID AND c.CustSubID = 0
	LEFT JOIN  	Temp_AssociatedException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	CROSS JOIN  Temp_EvidenceList AS ev
	WHERE 		a.CTSCustID <> d.CTSCustID AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
   
    -- Return CTSCustID, CustID, SubscriberID, EvidenceID, 0 (ActionType)
    SELECT DISTINCT cust.CustId
				,	cust.CTSCustId
                ,	cust.SubscriberId
                ,	ev.EvidenceId
                ,	0 AS ActionType
    FROM Temp_CustomerList AS cust CROSS JOIN  Temp_EvidenceList AS ev;
END$$

DELIMITER ;