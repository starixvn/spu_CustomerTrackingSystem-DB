/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ST_TransformData_GetPackage`

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ST_TransformData_GetPackage` (
        IN ip_IsProcessed TINYINT
    ,   IN ip_NoOfTickets INT
    ,   IN ip_NoOfBatch INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20190730@Casey.Huynh
	    Task : GET Transaction To Transform
	    DB: DCS_RawTransaction(Staging)
	    Original:

	    Revisions:
		    - 20201006@CaseyHuynh: Move New Server Phase 1, Move table RawTransaction from DB "DCS_RawTransaction" to "DCS_DataCenter" [Redmine ID: #143011]
		    - 20201006@Bobby:Move New Server Phase 2, Enhance Performance [Redmine ID: #143011]
			- 20210510@Aries.Nguyen: Remove insert log dba_SP_PerformanceStats [Redmine ID: #154792]	 
            
	    Param's Explanation (filtered by):
	*/

	DECLARE		vrTotalRecord		    INT UNSIGNED DEFAULT 0;
	DECLARE		vrRateBatch			    DECIMAL(4,2);
    DECLARE 	vrFromTransID		    BIGINT;
    DECLARE		vrGroupLookup		    VARCHAR(128);
    DECLARE		vrKeyLookup			    VARCHAR(128);
    DECLARE		vrSysMinCreatedDate	 	DATETIME;
     # Perf stats
	DECLARE 	sch_name	varchar(128);
    DECLARE 	sp_name		varchar(128);
    DECLARE 	call_time   timestamp(4);
    DECLARE 	start_time  timestamp(4);
    DECLARE 	rowCount    INT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_PerformanceStats;
    #==============================================
    
    SET sch_name = 'DCS_RawTransaction';
    SET sp_name = 'DCS_ST_TransformData_GetPackage';
    
    CREATE TEMPORARY TABLE Temp_PerformanceStats(
		step_id INT SIGNED AUTO_INCREMENT PRIMARY KEY,
        step_name varchar(100),
		start_time timestamp(4),
        diff_time int,
        stats varchar(1000)
    ) ENGINE = MEMORY;
    
    CREATE TEMPORARY TABLE Temp_Transaction(		
		    MinTransID			BIGINT UNSIGNED
        ,   MaxTransID			BIGINT UNSIGNED
        ,   BatchCount		INT
    ) ENGINE = MEMORY; 
	
    #SET call_time = CURRENT_TIMESTAMP(4);

    SET vrTotalRecord 	= ip_NoOfTickets*ip_NoOfBatch;
    SET vrGroupLookup 	= 'DCS_RawTrans_Transform';
    SET vrKeyLookup	 		= 'MinRawTransId';
    SET vrFromTransID 	= IFNULL((SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE VGroup=vrGroupLookup AND VName=vrKeyLookup	), 0);
	SET vrSysMinCreatedDate	 = (SELECT DATE(VValue) FROM DCS_DataCenter.SystemSetting WHERE VGroup = "DCS_Device_Transform" AND VName = "MinCreatedDate");

    #SET start_time = CURRENT_TIMESTAMP(4);
    SET vrTotalRecord = ip_NoOfTickets * ip_NoOfBatch;
	set @RowId = 0;
    
    INSERT INTO Temp_Transaction (MinTransID, MaxTransID, BatchCount)
    SELECT min(TransID) AS MinTransID, max(TransID) AS MaxTransID, SUM(1) AS BatchCount
	FROM (
		SELECT	@RowId := @RowId+1
			,   rt.TransID	
			,   ceil(@RowId/ip_NoOfTickets) as batchID
		FROM 	DCS_DataCenter.RawTransaction AS rt
		WHERE	rt.TransID >= vrFromTransID
				AND rt.IsProcessed = ip_IsProcessed
                AND rt.CreatedDate >= vrSysMinCreatedDate
		LIMIT	 vrTotalRecord
	) AS t
	GROUP BY batchID;
    
    #SET rowCount = (SELECT SUM(BatchCount) FROM Temp_Transaction);
    #INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    #WITH CTE_Stats AS (
	#	SELECT 'GET_DATA' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    #)
    #SELECT step_name, start_time, diff_time, stats FROM CTE_Stats;
    
    #UPDATE back vrFromTransID
    #SET start_time = CURRENT_TIMESTAMP(4);
    SET vrFromTransID = IFNULL((SELECT MIN(MinTransID) FROM Temp_Transaction), vrFromTransID);
    INSERT INTO DCS_DataCenter.SystemSetting (VGroup, VName, VValue, UpdatedTime)
    SELECT VGroup, VName, VValue, UpdatedTime
    FROM (
    SELECT vrGroupLookup AS VGroup
		, vrKeyLookup	 AS VName
		, CONCAT('', vrFromTransID) AS VValue
        , current_timestamp() AS UpdatedTime
	) as t
	ON DUPLICATE KEY UPDATE  VValue = t.VValue
		                    ,UpdatedTime = t.UpdatedTime;

    #GET DIAGNOSTICS rowCount = ROW_COUNT;
    #INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    #WITH CTE_Stats AS (
	#	SELECT 'UPDATE_SystemSetting' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount) as stats
    #)
    #SELECT step_name, start_time, diff_time, stats FROM CTE_Stats;
    
	#RETURN OUTPUT
    SELECT	tmpTT.MinTransID
			, tmpTT.MaxTransID
	FROM	Temp_Transaction AS tmpTT;

	# INSERT perf counter
    #INSERT INTO MonDB.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
	#SELECT sch_name, sp_name, step_id, step_name, st.start_time, diff_time, stats, call_time, CURRENT_TIMESTAMP(4) as end_time
	#FROM Temp_PerformanceStats st;
END$$
DELIMITER ;
