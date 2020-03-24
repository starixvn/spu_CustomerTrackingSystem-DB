DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_MoveTrans$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_MoveTrans(IN ip_MoveDate DATETIME, IN ip_Batch INT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Archive Data From Transaction07 to Transaction_BK01
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
	DECLARE vr_ArchiveID		TINYINT DEFAULT 1;
    DECLARE	vr_LastTrans		BIGINT DEFAULT 0;
    
    #========================================================= 
	TRUNCATE TABLE DCS_DataCenter.ArchiveTrans07_TransTemp;
    
    WHILE EXISTS (SELECT 1 FROM DCS_DataCenter.Transaction07  WHERE CreatedDate = ip_MoveDate AND TransID > vr_LastTrans LIMIT 1)
    DO
		SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
                
		INSERT IGNORE INTO DCS_DataCenter.ArchiveTrans07_TransTemp(TransID)
		SELECT	t07.TransID
		FROM	DCS_DataCenter.Transaction07 as t07
		WHERE	t07.CreatedDate = ip_MoveDate
				AND	t07.TransID > vr_LastTrans
		LIMIT	ip_Batch;      
        
        INSERT IGNORE INTO  DCS_DataCenter.Transaction_Casey(TransID, LoginName, TransTime, SubscriberID, AccountID
					, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
					, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)        
		SELECT 		ts07.TransID, ts07.LoginName, ts07.TransTime, ts07.SubscriberID, ts07.AccountID
					, ts07.URLID, ts07.DeviceCodeID, ts07.DeviceID, ts07.FirstDeviceCode, ts07.DeviceStatus, ts07.DeviceFingerprintID
					, ts07.UserAgentKey, ts07.IP, ts07.IPID, ts07.ActionResultID, ts07.Flagged, ts07.PluginID, ts07.TransStatus, ts07.CreatedDate, ts07.InsertTime
		FROM		DCS_DataCenter.Transaction07 AS ts07
		INNER JOIN	DCS_DataCenter.ArchiveTrans07_TransTemp	AS tmp_rm
					ON	ts07.TransID = tmp_rm.TransID
		WHERE 		tmp_rm.TransID > vr_LastTrans;
		
                    
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

        SET vr_LastTrans = (SELECT MAX(TransID) FROM DCS_DataCenter.ArchiveTrans07_TransTemp);
		
        SELECT 'Move', ip_MoveDate, vr_LastTrans;
    END WHILE;
    
   
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    	

END$$

DELIMITER ;
