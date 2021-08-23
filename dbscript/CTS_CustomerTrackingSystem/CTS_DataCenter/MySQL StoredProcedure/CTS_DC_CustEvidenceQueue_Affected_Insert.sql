/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidenceQueue_Affected_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_Affected_Insert`(
		IN 	ip_BatchSize 	INT
        
	,	OUT op_IsExist 	 	BIT
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210820@Aries.Nguyen
		Task:		Insert afected evidences from queue[Redmine ID: #160470]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #160470]
            
		Param's Explanation (filtered by):
		Example: 
			- CALL CTS_DataCenter.CTS_DC_CustEvidenceQueue_Affected_Insert(ip_BatchSize, @op_IsExist);
	*/    
    DECLARE lv_QueueID 			BIGINT UNSIGNED;
    DECLARE lv_QueueID_Next 	BIGINT UNSIGNED;
    DECLARE lv_LastCTSCustID 	BIGINT UNSIGNED;
    DECLARE lv_TotalAff 		INT DEFAULT 0;
    DECLARE lv_SecondBatchSize 	INT DEFAULT 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustAffectedEvidence;    
	CREATE TEMPORARY TABLE Temp_CustAffectedEvidence(
			QueueID				BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED    
		,	CTSCustID_Affected	BIGINT UNSIGNED 
        , 	EvidenceID			SMALLINT UNSIGNED       
        , 	Remark				VARCHAR(500)
		,	CreatedBy			INT UNSIGNED
        , 	INDEX				IX_Temp_CustAffectedEvidence_CTSCustID_Affected(CTSCustID,CTSCustID_Affected) 
        , 	INDEX				IX_Temp_CustAffectedEvidence_QueueID(QueueID) 
    );
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_AssociatedException;
    CREATE TEMPORARY TABLE Temp_AssociatedException(
			FromCTSCustID 	BIGINT UNSIGNED
        ,	ToCTSCustID 	BIGINT UNSIGNED
        , 	PRIMARY KEY		PK_Temp_AssociatedException_FromCTSCustID_ToCTSCustID(FromCTSCustID,ToCTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_AffectedExisted;
    CREATE TEMPORARY TABLE Temp_AffectedExisted(
			CTSCustID 		BIGINT UNSIGNED
		,	FromCustID		BIGINT UNSIGNED	
        ,	EvidenceID		SMALLINT
        , 	PRIMARY KEY(CTSCustID, FromCustID, EvidenceID)
	);
    
    SELECT ParameterValue 
    INTO lv_QueueID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 30; 
    
    SELECT ParameterValue 
    INTO lv_LastCTSCustID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 31; 

    SET lv_QueueID_Next = lv_QueueID + ip_BatchSize;
    
    INSERT INTO Temp_CustAffectedEvidence(QueueID, CTSCustID, CTSCustID_Affected, EvidenceID, Remark,CreatedBy)
    SELECT 	root.ID
		,	root.CTSCustID
		,  	aff.CTSCustID
		,	root.EvidenceID
		,	root.Remark
		,	root.CreatedBy
	FROM CTS_DataCenter.CustEvidenceAffectedQueueInsert AS root,
	LATERAL
		(SELECT DISTINCT
				ass.CTSCustID
		FROM CTS_DataCenter.AssociationByDevice as dv
		INNER JOIN CTS_DataCenter.AssociationByDevice AS ass ON ass.DCSDeviceID = dv.DCSDeviceID 
																	AND ass.CTSCustID <> root.CTSCustID   
																	AND ass.CTSCustID > lv_LastCTSCustID
		WHERE dv.CTSCustID = root.CTSCustID
		ORDER BY ass.CTSCustID ASC
		LIMIT ip_BatchSize) AS aff
	WHERE root.ID = lv_QueueID 
    ORDER BY  root.ID ASC
	LIMIT ip_BatchSize;
    
    SELECT COUNT(1)
    INTO lv_TotalAff
    FROM Temp_CustAffectedEvidence;
    
    IF ip_BatchSize > lv_TotalAff THEN
		SET lv_SecondBatchSize = ip_BatchSize - lv_TotalAff;
        
        INSERT INTO Temp_CustAffectedEvidence(QueueID, CTSCustID, CTSCustID_Affected, EvidenceID, Remark,CreatedBy)
		SELECT 	root.ID
			,	root.CTSCustID
			,  	aff.CTSCustID
			,	root.EvidenceID
			,	root.Remark
			,	root.CreatedBy
		FROM CTS_DataCenter.CustEvidenceAffectedQueueInsert AS root,
		LATERAL
			(SELECT DISTINCT
					ass.CTSCustID
			 FROM CTS_DataCenter.AssociationByDevice as dv
			 INNER JOIN CTS_DataCenter.AssociationByDevice AS ass ON ass.DCSDeviceID = dv.DCSDeviceID 
																 AND ass.CTSCustID <> root.CTSCustID   
             WHERE dv.CTSCustID = root.CTSCustID
			 ORDER BY ass.CTSCustID ASC
			 LIMIT lv_SecondBatchSize) AS aff
		WHERE root.ID between lv_QueueID + 1 AND lv_QueueID_Next
		ORDER BY root.ID ASC
		LIMIT lv_SecondBatchSize;
        
    END IF;

    SELECT COUNT(1)
    INTO lv_TotalAff
    FROM Temp_CustAffectedEvidence;
    
    IF lv_TotalAff  = 0 THEN
        IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidenceAffectedQueueInsert WHERE ID > lv_QueueID_Next) THEN
            UPDATE CTS_DataCenter.SystemParameter 
            SET ParameterValue = lv_QueueID_Next
            WHERE ParameterID = 30; 
	
            UPDATE CTS_DataCenter.SystemParameter 
            SET ParameterValue = 0
            WHERE ParameterID = 31; 

            DELETE 
	        FROM CustEvidenceAffectedQueueInsert
            WHERE ID < lv_QueueID_Next;

            SET op_IsExist = 1;
            LEAVE sp;
        END IF;
		SET op_IsExist = 0;
		LEAVE sp;
    END IF;
    
    SELECT MAX(QueueID)
    INTO lv_QueueID
    FROM Temp_CustAffectedEvidence;
    
    SELECT MAX(CTSCustID_Affected)
    INTO lv_LastCTSCustID
    FROM Temp_CustAffectedEvidence
    WHERE QueueID = lv_QueueID;
    
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT	ex.FromCTSCustID
		,	ex.ToCTSCustID
    FROM CTS_DataCenter.CustException AS ex
		INNER JOIN Temp_CustAffectedEvidence AS aff ON ex.FromCTSCustID = aff.CTSCustID AND ex.ToCTSCustID = aff.CTSCustID_Affected;
    
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT	ex.FromCTSCustID
		,	ex.ToCTSCustID
    FROM CTS_DataCenter.CustException AS ex
		INNER JOIN Temp_CustAffectedEvidence AS aff ON ex.FromCTSCustID = aff.CTSCustID_Affected AND ex.ToCTSCustID = aff.CTSCustID;
    
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT	ex.FromCTSCustID
		,	ex.ToCTSCustID
    FROM CTS_DataCenter.AssociationRemove AS ex
		INNER JOIN Temp_CustAffectedEvidence AS aff ON ex.FromCTSCustID = aff.CTSCustID_Affected AND ex.ToCTSCustID = aff.CTSCustID;
    
    INSERT INTO Temp_AssociatedException(FromCTSCustID, ToCTSCustID)
    SELECT	ex.FromCTSCustID
		,	ex.ToCTSCustID
    FROM CTS_DataCenter.AssociationRemove AS ex
		INNER JOIN Temp_CustAffectedEvidence AS aff ON ex.FromCTSCustID = aff.CTSCustID AND ex.ToCTSCustID = aff.CTSCustID_Affected;
    
    DELETE 
    FROM Temp_CustAffectedEvidence AS aff
    WHERE EXISTS (SELECT 1 FROM Temp_AssociatedException AS ex WHERE ex.FromCTSCustID = aff.CTSCustID AND ex.ToCTSCustID = aff.CTSCustID_Affected);
    
    DELETE 
    FROM Temp_CustAffectedEvidence AS aff
    WHERE EXISTS (SELECT 1 FROM Temp_AssociatedException AS ex WHERE ex.FromCTSCustID = aff.CTSCustID_Affected AND ex.ToCTSCustID = aff.CTSCustID);
    
    
    INSERT IGNORE INTO Temp_AffectedExisted(CTSCustID,FromCustID, EvidenceID)
    SELECT CTSCustID,FromCustID, EvidenceID
    FROM  CTS_DataCenter.CustEvidence AS ev
    WHERE EXISTS (SELECT 1 
				  FROM Temp_CustAffectedEvidence AS aff
				  WHERE aff.CTSCustID = ev.CTSCustID
					AND	aff.CTSCustID_Affected = ev.FromCustID
                    AND aff.EvidenceID = ev.EvidenceID);
    
    DELETE 
    FROM Temp_CustAffectedEvidence AS ev
    WHERE EXISTS (SELECT 1 
				  FROM Temp_AffectedExisted AS ex 
                  WHERE ev.CTSCustID = ex.CTSCustID 
					AND ev.CTSCustID_Affected = ex.FromCustID
                    AND ev.EvidenceID = ex.EvidenceID);
    
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT	DISTINCT 
			aff.CTSCustID_Affected
		,	aff.EvidenceID
		,	aff.Remark
		,	2
		,	aff.CTSCustID
		,	NOW()
		,	aff.CreatedBy
    FROM Temp_CustAffectedEvidence AS aff;
    
    UPDATE CTS_DataCenter.SystemParameter 
    SET ParameterValue = lv_QueueID
    WHERE ParameterID = 30; 
	
    UPDATE CTS_DataCenter.SystemParameter 
    SET ParameterValue = lv_LastCTSCustID
    WHERE ParameterID = 31; 
    
    DELETE 
	FROM CustEvidenceAffectedQueueInsert
    WHERE ID < lv_QueueID;
    
	SET op_IsExist = 1;
    
END$$

DELIMITER ;