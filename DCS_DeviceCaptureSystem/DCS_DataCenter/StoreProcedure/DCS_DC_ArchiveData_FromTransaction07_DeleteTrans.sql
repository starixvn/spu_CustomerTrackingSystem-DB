DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_DeleteTrans$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_DeleteTrans(IN ip_MoveDate DATETIME, IN ip_Batch INT)
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
    
 
    WHILE EXISTS (SELECT 1 FROM DCS_DataCenter.ArchiveTrans07_TransTemp LIMIT 1)
    DO
		SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		
        SET vr_LastTrans = 	( SELECT MAX(TransID) 
							FROM (SELECT TransID FROM DCS_DataCenter.ArchiveTrans07_TransTemp LIMIT ip_Batch)
                            AS a) ;       
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        
        DELETE 		ts
        FROM		DCS_DataCenter.Transaction07 AS ts
        INNER JOIN	DCS_DataCenter.ArchiveTrans07_TransTemp AS temp_arc
					ON ts.TransID = temp_arc.TransID
		WHERE 		temp_arc.TransID <= vr_LastTrans;		
        
        DELETE	temp_arc
        FROM	DCS_DataCenter.ArchiveTrans07_TransTemp AS temp_arc
        WHERE 	temp_arc.TransID <= vr_LastTrans;	
        
    END WHILE;
    

END$$

DELIMITER ;
