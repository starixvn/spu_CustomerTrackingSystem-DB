DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_ArchiveData_FromTransaction07_MoveTrans`(IN ip_MoveDate DATETIME, IN ip_HistoryId INT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Archive Data From Transaction07 to Transaction_BK01
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/

    DECLARE	v_minId		BIGINT DEFAULT 0;
    DECLARE	v_maxId		BIGINT DEFAULT 0;
    DECLARE v_id		INT DEFAULT 0;
    DECLARE v_moved 	BOOLEAN;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    WHILE EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveTransLog WHERE MovedDate = ip_MoveDate AND Moved = false LIMIT 1) DO  
		        
		SELECT FromTransId, ToTransId, ifnull(Id, 0) , Moved 
        INTO v_minId, v_maxId, v_id, v_moved
        FROM DCS_DataCenter.ArchiveTransLog 
        WHERE MovedDate = ip_MoveDate AND Moved = false LIMIT 1;
                
		IF v_id != 0 THEN			
			IF v_moved = false THEN
				 INSERT INTO  DCS_DataCenter.Transaction09(TransID, LoginName, TransTime, SubscriberID, AccountID
				, URLID, DeviceCodeID, DeviceID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID
				, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime)        
				SELECT 		ts07.TransID, ts07.LoginName, ts07.TransTime, ts07.SubscriberID, ts07.AccountID
				, ts07.URLID, ts07.DeviceCodeID, ts07.DeviceID, ts07.FirstDeviceCode, ts07.DeviceStatus, ts07.DeviceFingerprintID
				, ts07.UserAgentKey, ts07.IP, ts07.IPID, ts07.ActionResultID, ts07.Flagged, ts07.PluginID, ts07.TransStatus, ts07.CreatedDate, ts07.InsertTime
				FROM		DCS_DataCenter.Transaction07 AS ts07
				WHERE CreatedDate = ip_MoveDate AND (ts07.TransId BETWEEN v_minId AND v_maxId);  
				
                SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
				UPDATE DCS_DataCenter.ArchiveTransLog 
					SET Moved = true 
				WHERE Id = v_id;
            END IF;
		END IF; 
	END WHILE;    	
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;

	UPDATE	DCS_DataCenter.ArchiveHistory
		SET		EndTime = NOW() 
				, Status = 2
	WHERE 	Id 	= ip_HistoryId;	
    
    
END$$
DELIMITER ;
