/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_RemoveAllEvidenceByCTSCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_RemoveAllEvidenceByCTSCustIDs`(
		IN ip_CTSCustIDs		JSON
	,	IN ip_CreatedBy			INT
	,	IN ip_SessionId			BIGINT
	,	IN ip_IsRollback		TINYINT
	,	IN ip_IsClearLog		TINYINT
	
	,	OUT op_ErrorMessage		VARCHAR(200)
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200825@Roger.Le
		Task:		Evidence Upload - Overrite the data
		DB:			CTS_DataCenter
		Original:

		Revisions: 
		   - 20200825@Roger.Le: Created [Redmine ID: #137551]
		   - 20201111@Irena.Vo: Enhance logic Insert History for Evidence Category [Redmine ID: #145027]
		   - 20201125@Irena.Vo: Move flow sync Evidence to Category [Redmine ID: #141563]
		   - 20201130@Irena.Vo: Enhance logic Insert new evidence (remove existed evidence category before) [Redmine ID: #141563]
		   - 20201222-20210107@Irena.Vo: Insert Error Log [RedmineID: #145951]
		   - 20210622@Aries.Nguyen: Update coding convention and inprove locking [Redmine ID: #157203]
		   - 20210823@Aries.Nguyen: Enhannce  Affected Evidence flow [Redmine ID: #160470]
           - 20220421@Irena.Vo: Rename select CustId -> CustID [Redmine ID: #170468]
           - 20220426@Casey.Huynh: Return CreatedBy [Redmine ID: #171512]
           
	*/
    DECLARE lv_CurrentDateTime	DATETIME DEFAULT CURRENT_TIME();
    
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
        VALUES(8, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_CTSCustIDs));
    END;
    
    IF(ip_IsClearLog) THEN
		BEGIN
			# Remove log data
            DELETE FROM CTS_DataCenter.CustEvidenceLog
			WHERE SessionId = ip_SessionId;
            
            LEAVE sp;
        END;
    END IF;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccount;    
	CREATE TEMPORARY TABLE Temp_MultipleAccount(	 
			CTSCustID		BIGINT UNSIGNED
		,   CustID          BIGINT UNSIGNED
        ,   SubscriberID    INT UNSIGNED
		, 	PRIMARY KEY		PK_Temp_MultipleAccount_CTSCustID(CTSCustID) 
	);      		
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceList;
	CREATE TEMPORARY TABLE Temp_CustEvidenceList(
			CTSCustID 	BIGINT UNSIGNED
		,	EvidenceID 	BIGINT UNSIGNED
		,   INDEX		IX_Temp_CustEvidenceList_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustID;
	CREATE TEMPORARY TABLE Temp_CTSCustID(
			CTSCustID 	BIGINT UNSIGNED
		,   INDEX		IX_Temp_CTSCustID_CTSCustID(CTSCustID)
	);
	
	INSERT INTO Temp_CTSCustID(CTSCustID)
	SELECT 	temp.CTSCustID
	FROM JSON_TABLE(ip_CTSCustIDs,
		 "$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
		 )) AS temp;

	/*GET CUSTOMER INFO*/
	INSERT INTO Temp_MultipleAccount(CustID, CTSCustID, SubscriberID)
	SELECT	c.CustID
		,	t.CTSCustID
		,	c.SubscriberID
	FROM Temp_CTSCustID AS t
		LEFT JOIN 	CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID AND c.CustSubID = 0;
       	
    IF(!ip_IsRollback) THEN
		BEGIN
			 # Save log
            INSERT IGNORE INTO CTS_DataCenter.CustEvidenceLog(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, SessionId)
			SELECT	cus.CTSCustID
				,	cus.EvidenceID
				,	cus.Remark
				,	cus.Level
				,	cus.FromCustID
				,	cus.CreatedDate
				,	cus.CreatedBy
				,	ip_SessionId
			FROM Temp_MultipleAccount AS tmp
				INNER JOIN CTS_DataCenter.CustEvidence as cus ON tmp.CTSCustID = cus.CTSCustID AND cus.Level = 0;
                    
        END;
    END IF;
    
    -- Get Evidence List for customers before remove
	INSERT INTO Temp_CustEvidenceList
    SELECT	DISTINCT 
			temp.CTSCustID
		,	evd.EvidenceID
    FROM Temp_MultipleAccount AS temp 
		INNER JOIN CustEvidence AS evd ON temp.CTSCustID = evd.FromCustID AND Level = 0;
    
   INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID)
   SELECT 	ev.CTSCustID
   FROM Temp_MultipleAccount AS ev;

	DELETE evd
    FROM  CustEvidence AS evd
    INNER JOIN  Temp_MultipleAccount AS temp ON temp.CTSCustID = evd.FromCustID AND Level = 0;
    
    IF(ip_IsRollback) THEN
		BEGIN
            # Rollback data
            INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
			SELECT	log.CTSCustID
				,	log.EvidenceID
				,	log.Remark
				,	log.Level
				,	log.FromCustID
				,	log.CreatedDate
				,	log.CreatedBy
			FROM CTS_DataCenter.CustEvidenceLog log
            WHERE log.SessionId = ip_SessionId;

			INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueInsert(CTSCustID,  EvidenceID, Remark, CreatedBy)
			SELECT 	log.CTSCustID
				,	log.EvidenceID
				,	log.Remark
				,	log.CreatedBy
			FROM CTS_DataCenter.CustEvidenceLog log
            WHERE log.SessionId = ip_SessionId;
                
            # Remove log data
            DELETE 
			FROM CTS_DataCenter.CustEvidenceLog
			WHERE SessionId = ip_SessionId;
        END;
    END IF;
    
	-- Return CTSCustID, CustID, SubscriberID, EvidenceID, 2 (ActionType) TO Remove Classication 
    SELECT	DISTINCT 
			temp.CTSCustID
		,	temp.CustID
		,	temp.SubscriberID
		,	evd.EvidenceID
		,	2 AS ActionType-- remove
        ,	ip_CreatedBy AS CreatedBy
	FROM Temp_MultipleAccount AS temp
		INNER JOIN Temp_CustEvidenceList AS evd ON evd.CTSCustID = temp.CTSCustID;
END$$
DELIMITER ;