DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_DC_ArchiveData_FromTransaction07`(IN ip_Batch INT)
BEGIN
	/*
	Created: 20190730@Casey.Huynh
	Task : Archive Data From Transaction07 to Transaction_BK01
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
	
	DECLARE	vr_ToDate				DATETIME;
    DECLARE	vr_MoveDate				DATETIME;
    DECLARE vr_Id					INT DEFAULT 1;
 	DECLARE	vr_ArchiveDate			DATETIME;
    DECLARE vr_Status				TINYINT;

	SET vr_ToDate = DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY);   
    SET vr_ArchiveDate = NOW();
    
    INSERT IGNORE INTO DCS_DataCenter.ArchiveHistory(ArchivedDate, ScheduleTime, StartTime, Status)
    SELECT 	 DISTINCT CreatedDate 
			, NOW()
            , NOW()
            , 0 AS Status
    FROM 	DCS_DataCenter.Transaction07
    WHERE CreatedDate < vr_ToDate; 
    
    #===========INSERT TO ArchiveHistory======================
    
    
    WHILE EXISTS(
		SELECT 1 FROM DCS_DataCenter.ArchiveHistory 
		WHERE 	Status < 3 
        ORDER BY ArchivedDate
        LIMIT 1)
    DO		 
		SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  		
		SELECT 	ArchivedDate, Id, Status 
        INTO 	vr_ArchiveDate, vr_Id, vr_Status 
		FROM	DCS_DataCenter.ArchiveHistory 
		WHERE 	Status < 3 
        ORDER BY ArchivedDate
        LIMIT 1;
        
        IF vr_Id IS NOT NULL  && vr_Id != 0 THEN
        
			SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
			UPDATE DCS_DataCenter.ArchiveHistory 
				SET StartTime = NOW() 
			WHERE Id = vr_Id;
			
            IF vr_Status = 0 THEN
				CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_Planning(vr_ArchiveDate, ip_Batch, vr_Id);
                
                SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
                SELECT Status INTO vr_Status 
                FROM DCS_DataCenter.ArchiveHistory
                WHERE Id = vr_Id;                
                IF vr_Status = 1 THEN
					CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_MoveTrans(vr_ArchiveDate, vr_Id); 
                END IF;
                
                SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
                SELECT Status INTO vr_Status 
                FROM DCS_DataCenter.ArchiveHistory
                WHERE Id = vr_Id; 
                 IF vr_Status = 2 THEN
					CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_DeleteTrans(vr_ArchiveDate, vr_Id);
                END IF;
			ELSEIF vr_Status = 1 THEN
				CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_MoveTrans(vr_ArchiveDate, vr_Id);
                
                SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
                SELECT Status INTO vr_Status 
                FROM DCS_DataCenter.ArchiveHistory
                WHERE Id = vr_Id; 
                 IF vr_Status = 2 THEN
					CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_DeleteTrans(vr_ArchiveDate, vr_Id);
                END IF;
			ELSE
				CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_DeleteTrans(vr_ArchiveDate, vr_Id);
			END IF;             
		END IF;   
        
    END WHILE;    
  
END$$
DELIMITER ;
