DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_ArchiveData_FromTransaction07_Planning`(IN ip_MoveDate DATETIME, IN ip_Batch INT, IN ip_HistoryId INT)
BEGIN
	/*
	Created: 20200415@Terry.Nguyen
	Task : Archive Data From Transaction07 to Transaction_BK01
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/

    DECLARE	v_minId		BIGINT DEFAULT 0;
    DECLARE	v_maxId		BIGINT DEFAULT 1;
    
    #========================================================= 
    CREATE TABLE IF NOT EXISTS DCS_DataCenter.ArchiveTransLog
    (
		Id 			INT PRIMARY KEY AUTO_INCREMENT,
		FromTransId BIGINT NOT NULL,
        ToTransId 	BIGINT NOT NULL,
        MaxTransId 	BIGINT NOT NULL,
        Moved 		BOOLEAN,
        Deleted 	BOOLEAN,
        MovedDate 	DATETIME,
        INDEX IX_ArchiveTransLog_FromTransId_ToTransId (FromTransId, ToTransId) 
    );
    
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    WHILE v_maxId is not null && v_maxId != 0 DO  
				                
		SELECT Min(a.TransId), Max(a.TransId) INTO v_minId, v_maxId 
			FROM (SELECT TransId 
					FROM DCS_DataCenter.Transaction07 a 
                    WHERE CreatedDate = ip_MoveDate AND TransId > v_maxId ORDER BY TransId LIMIT ip_Batch) as a;
	   
		IF v_minId IS NOT NULL && v_maxId IS NOT NULL THEN
			INSERT INTO DCS_DataCenter.ArchiveTransLog(FromTransId, ToTransId, MaxTransId, Moved, Deleted, MovedDate)
			VALUES(v_minId, v_maxId, v_maxId, false, false, ip_MoveDate);	
		END IF;                
                
	END WHILE;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
    UPDATE	DCS_DataCenter.ArchiveHistory
		SET		EndTime = NOW() 
				, Status = 1
	WHERE 	Id 	= ip_HistoryId;
END$$
DELIMITER ;
