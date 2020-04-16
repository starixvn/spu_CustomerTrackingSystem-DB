DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_ArchiveData_FromTransaction07_DeleteTrans`(IN ip_MoveDate DATETIME, IN ip_HistoryId INT)
BEGIN
	DECLARE	v_minId		BIGINT DEFAULT 0;
    DECLARE	v_maxId		BIGINT DEFAULT 1;
    DECLARE v_id		INT DEFAULT 1;  
    DECLARE v_delete	BOOLEAN;
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    WHILE EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveTransLog WHERE MovedDate = ip_MoveDate AND Deleted = false LIMIT 1) DO  
		 
		SELECT FromTransId, ToTransId, ifnull(Id, 0), Deleted 
        INTO v_minId, v_maxId, v_id, v_delete
        FROM DCS_DataCenter.ArchiveTransLog 
        WHERE MovedDate = ip_MoveDate AND Deleted = false 
        LIMIT 1;
        
		IF v_id != 0 THEN	
            IF v_delete = false THEN
					SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
					DELETE 		ts
					FROM		DCS_DataCenter.Transaction07 AS ts
					WHERE ts.CreatedDate = ip_MoveDate AND (ts.TransId BETWEEN v_minId AND v_maxId);		
					
					UPDATE DCS_DataCenter.ArchiveTransLog 
					SET Deleted = true 
					WHERE Id = v_Id;                   
			END IF;
		END IF; 
	END WHILE;    	
	
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
    SELECT ip_HistoryId;
	UPDATE	DCS_DataCenter.ArchiveHistory
		SET		EndTime = NOW() 
				, Status = 3
	WHERE 	Id 	= ip_HistoryId;	
END$$
DELIMITER ;
