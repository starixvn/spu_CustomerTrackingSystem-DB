/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidenceQueue_Affected_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_Affected_Remove`(
		IN 	ip_BatchSize 	INT
        
	,	OUT op_IsExist 	 	SMALLINT
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210820@Aries.Nguyen
		Task:		Insert afected evidences from queue[Redmine ID: #160470]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210622@Aries.Nguyen:  Created [Redmine ID: #160470]
            
		Param's Explanation (filtered by):
		Example: 
			- CALL CTS_DataCenter.CTS_DC_CustEvidenceQueue_Affected_Remove(ip_BatchSize, @op_ErrorMessage);
	*/    
	DECLARE lv_QueueID 		BIGINT UNSIGNED;
    DECLARE lv_QueueID_Next BIGINT UNSIGNED;
    DECLARE lv_TotalAff 	INT DEFAULT 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustAffectedEvidence;    
	CREATE TEMPORARY TABLE Temp_CustAffectedEvidence(
			QueueID				BIGINT UNSIGNED
		,	CustEvidID			BIGINT UNSIGNED  
        ,	INDEX 				IX_Temp_CustAffectedEvidence_QueueID(QueueID)
        ,	INDEX 				IX_Temp_CustAffectedEvidence_CustEvidID(CustEvidID)
    );

    SELECT ParameterValue 
    INTO lv_QueueID
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 32; 

    SELECT MAX(tbl.ID)
    INTO lv_QueueID_Next
    FROM (SELECT ID
		  FROM CTS_DataCenter.CustEvidenceAffectedQueueRemove
		  WHERE ID >= lv_QueueID
		  ORDER BY ID ASC
		  LIMIT ip_BatchSize) AS tbl;

    IF lv_QueueID_Next IS NULL THEN
        SET op_IsExist = 0;
        LEAVE sp;
    END IF;

    IF lv_QueueID_Next = lv_QueueID THEN
        SET lv_QueueID_Next = lv_QueueID + 1;
    END IF;
    
    
    INSERT INTO Temp_CustAffectedEvidence(QueueID, CustEvidID)
    SELECT 	root.ID
		,	aff.CustEvidID
	FROM CTS_DataCenter.CustEvidenceAffectedQueueRemove AS root,
	LATERAL(
        SELECT ev.CustEvidID
		FROM CTS_DataCenter.CustEvidence AS ev
		WHERE ev.FromCustID = root.CTSCustID 
            AND (root.EvidenceID IS NULL OR ev.EvidenceID = root.EvidenceID)
            AND ev.Level =  2
		LIMIT ip_BatchSize) AS aff
	WHERE root.ID BETWEEN  lv_QueueID AND lv_QueueID_Next
    ORDER BY root.ID ASC 
	LIMIT ip_BatchSize;
    
    SELECT COUNT(1)
    INTO lv_TotalAff
    FROM Temp_CustAffectedEvidence;

    IF lv_TotalAff = 0 THEN
         UPDATE CTS_DataCenter.SystemParameter 
         SET ParameterValue = 0
         WHERE ParameterID = 32; 

         DELETE 
	     FROM CustEvidenceAffectedQueueRemove
         WHERE ID < lv_QueueID_Next;

        IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidenceAffectedQueueRemove WHERE ID > lv_QueueID_Next) THEN
            SET op_IsExist = 1;
            LEAVE sp;
        END IF;
        
		SET op_IsExist = 0;
		LEAVE sp;
    END IF;
    
    DELETE 
    FROM CTS_DataCenter.CustEvidence AS ev
    WHERE EXISTS (SELECT 1 FROM Temp_CustAffectedEvidence AS aff WHERE aff.CustEvidID = ev.CustEvidID);
    
    SELECT MAX(QueueID)
    INTO lv_QueueID
    FROM Temp_CustAffectedEvidence;
    
    UPDATE CTS_DataCenter.SystemParameter 
    SET ParameterValue = lv_QueueID
    WHERE ParameterID = 32; 
    
    DELETE 
	FROM CTS_DataCenter.CustEvidenceAffectedQueueRemove
    WHERE ID < lv_QueueID;
    
	SET op_IsExist = 1;	
    
END$$

DELIMITER ;