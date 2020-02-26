DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_TransformData_MoveTransaction$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_TransformData_MoveTransaction(IN ip_NoOfTickets INT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Archive Data
	DB: DCS_DataCenter
	Original:

	Revisions:
			[20200226@CaseyHuynh: Move Archive Data to New Table Transaction_BK01 and RawTransaction_BK01]
	Param's Explanation (filtered by):
	*/
	DECLARE	vr_FromID 	BIGINT	UNSIGNED;
	DECLARE	vr_MaxToID	BIGINT	UNSIGNED;

    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    
    DROP Temporary TABLE IF EXISTS Temp_RemoveTrans;
    CREATE Temporary TABLE Temp_RemoveTrans
    (
		TransID		BIGINT	UNSIGNED
    );
    
	SET vr_FromID = (SELECT LastTransID FROM DCS_DataCenter.MoveTransaction);    
    
    SET vr_MaxToID = (SELECT MAX(TransID) FROM DCS_RawTransaction.RawTransaction WHERE IsProcessed = 2) + 1;
    
	TRUNCATE TABLE Temp_RemoveTrans;
	INSERT INTO Temp_RemoveTrans(TransID)
	SELECT TransID 
	FROM   DCS_RawTransaction.RawTransaction WHERE IsProcessed = 2
	LIMIT  ip_NoOfTickets; 
    
    SET vr_FromID = (SELECT MIN(TransID) FROM Temp_RemoveTrans);    
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    
    WHILE (vr_FromID < vr_MaxToID)
    DO        
		# ======================MOVE Transaction==========================================================
        SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		INSERT IGNORE INTO  DCS_DataCenter.Transaction_BK01(TransID, LoginName, TransTime, SubscriberID, AccountID
        , URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
		, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)        
        SELECT 	ts.TransID, LoginName, TransTime, SubscriberID, AccountID
				, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
				, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime
        FROM		DCS_DataCenter.Transaction AS ts
        INNER JOIN	Temp_RemoveTrans	AS tmp_rm
					ON	ts.TransID = tmp_rm.TransID;
                    
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        
        DELETE	ts
        FROM		DCS_DataCenter.Transaction AS ts
        INNER JOIN	Temp_RemoveTrans	AS tmp_rm
					ON	ts.TransID = 	tmp_rm.TransID;
        
        # ======================MOVE RawTransaction========================================================== 
        SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
        INSERT IGNORE INTO DCS_RawTransaction.RawTransaction_BK01
		(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent
        , IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, IsProcessed, TransID)
		SELECT
		LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent
        , IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, IsProcessed, rt.TransID
        FROM 	DCS_RawTransaction.RawTransaction AS rt
        INNER JOIN	Temp_RemoveTrans	AS tmp_rm
					ON	rt.TransID = tmp_rm.TransID;
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
        
		DELETE	rt
        FROM 	DCS_RawTransaction.RawTransaction AS rt
        INNER JOIN	Temp_RemoveTrans	AS tmp_rm
					ON	rt.TransID = tmp_rm.TransID;
        #=====================================================================       
		UPDATE	DCS_DataCenter.MoveTransaction
		SET		LastTransID = (SELECT MAX(TransID) FROM Temp_RemoveTrans);        
        
        #============================================
        TRUNCATE TABLE Temp_RemoveTrans;
		INSERT INTO Temp_RemoveTrans(TransID)
		SELECT TransID 
		FROM   DCS_RawTransaction.RawTransaction WHERE IsProcessed = 2
		LIMIT  ip_NoOfTickets; 
    
		SET vr_FromID = (SELECT MIN(TransID) FROM Temp_RemoveTrans);    

        #--===================================================================        
    END WHILE ;
    
   
    
END$$
DELIMITER ;
