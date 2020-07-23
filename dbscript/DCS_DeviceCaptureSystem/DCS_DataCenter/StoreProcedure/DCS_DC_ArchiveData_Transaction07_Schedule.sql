DELIMITER $$
DROP PROCEDURE IF EXISTS DCS_DataCenter.DCS_DC_ArchiveData_Transaction07_Schedule$$
CREATE DEFINER=`fps`@`%` PROCEDURE DCS_DataCenter.DCS_DC_ArchiveData_Transaction07_Schedule()
BEGIN
	/*
	Created: 	20200723@Casey.Huynh
	Task : 		Enhance Archive Data From Transaction07 to Transaction90
	DB: 		DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
	*/
	DECLARE	vr_FromDate				DATETIME;
	DECLARE	vr_ToDate				DATETIME;
    DECLARE	vr_MoveDate				DATETIME;
    DECLARE vr_Id					INT DEFAULT 0;
    DECLARE vr_ArchiveId			INT DEFAULT 1;
 	DECLARE	vr_ArchiveDate			DATETIME;
    DECLARE vr_Status				TINYINT; #0:Initial, 1: Move Done, 3: Delete Done;
	
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;    
    
	SET vr_FromDate = (SELECT MIN(CreatedDate) FROM DCS_DataCenter.Transaction07);
    SET vr_ToDate = DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY);   
    SET vr_ArchiveDate = NOW();
    
	INSERT IGNORE INTO DCS_DataCenter.ArchiveHistory(ArchivedDate, ScheduleTime, StartTime, Status, ArchiveID, FromTransID, ToTransID, TotalRecord)
	SELECT	CreatedDate, NOW(),NULL , 0, vr_ArchiveId
			, MIN(TransID) AS FromTransID
			, Max(TransID) AS ToTransID
			, COUNT(1) AS TotalRecord
	FROM 	DCS_DataCenter.Transaction07 AS ts07            
	WHERE 	ts07.CreatedDate >= vr_FromDate
	GROUP BY CreatedDate;
	
    SELECT 	ArchivedDate
    FROM 	DCS_DataCenter.ArchiveHistory
    WHERE 	Status < 2;
    
END$$
DELIMITER ;
