DELIMITER $$

DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07$$

CREATE PROCEDURE DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07(IN ip_Batch INT)
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
    DECLARE vr_ArchiveID			TINYINT DEFAULT 1;
    DECLARE	vr_ScheduleTime			DATETIME;
	DECLARE	vr_ArchiveDate			DATETIME;
    

    SET vr_ScheduleTime = CURRENT_TIME();
	SET vr_ToDate = CURRENT_DATE() - 6;
    
    
    
    DROP TEMPORARY TABLE IF EXISTS ArchiveTrans07_DateTemp;
    CREATE TEMPORARY TABLE ArchiveTrans07_DateTemp
    (
		ArchivedDate	DATETIME
        , ScheduleTime 	DATETIME
        , LastTrans		BIGINT UNSIGNED
    );
        
    TRUNCATE TABLE ArchiveTrans07_DateTemp;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
    
    INSERT INTO DCS_DataCenter.ArchiveTrans07_DateTemp(ArchivedDate, ScheduleTime)
    SELECT 	DISTINCT CreatedDate, vr_ScheduleTime
    FROM 	DCS_DataCenter.Transaction07 
    WHERE 	CreatedDate < vr_ToDate; 
    
    INSERT INTO DCS_DataCenter.ArchiveHistory(ArchiveID, ArchivedDate, ScheduleTime, StartTime, Status)
    SELECT 	vr_ArchiveID
			, ArchivedDate
            , ScheduleTime
            , CURRENT_TIME()
            , 0 AS Status
    FROM 	DCS_DataCenter.ArchiveTrans07_DateTemp;

	SELECT 		ArchivedDate
    INTO		vr_ArchiveDate
    FROM		DCS_DataCenter.ArchiveTrans07_DateTemp
    ORDER BY	ArchivedDate ASC
    LIMIT		1;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
    #===========INSERT TO ArchiveHistory======================
    WHILE EXISTS (SELECT 1 FROM	DCS_DataCenter.ArchiveTrans07_DateTemp LIMIT 1)
    DO
        CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_MoveTrans(vr_ArchiveDate, ip_Batch);        
        
        UPDATE	DCS_DataCenter.ArchiveHistory
		SET		EndTime = CURRENT_TIME()
				, Status = 1
		WHERE 	ArchiveID 			= vr_ArchiveID
				AND	ArchivedDate 	= vr_ArchiveDate
				AND ScheduleTime 	= vr_ScheduleTime;	
		
        CALL DCS_DataCenter.DCS_DC_ArchiveData_FromTransaction07_DeleteTrans(vr_ArchiveDate, ip_Batch);
        
		UPDATE 	DCS_DataCenter.ArchiveStatus
		SET		LastArchivedDate = vr_ArchiveDate
				, UpdateTime = vr_ScheduleTime
		WHERE	ArchiveID = vr_ArchiveID; 
    
		UPDATE	DCS_DataCenter.ArchiveHistory
		SET		EndTime = CURRENT_TIME()
				, Status = 2
		WHERE 	ArchiveID 			= vr_ArchiveID
				AND	ArchivedDate 	= vr_ArchiveDate
				AND ScheduleTime 	= vr_ScheduleTime;	
                
		DELETE 	temp_atd
		FROM	ArchiveTrans07_DateTemp AS temp_atd
		WHERE	ArchivedDate = vr_ArchiveDate;	

		SELECT 		ArchivedDate
		INTO		vr_ArchiveDate
		FROM		DCS_DataCenter.ArchiveTrans07_DateTemp
		ORDER BY	ArchivedDate ASC
		LIMIT		1;
		
    END WHILE;    
  
END$$

DELIMITER ;
