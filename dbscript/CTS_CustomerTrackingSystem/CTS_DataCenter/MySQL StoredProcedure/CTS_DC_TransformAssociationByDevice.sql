/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociationByDevice$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE CTS_DataCenter.CTS_DC_TransformAssociationByDevice(IN ip_AssociationList JSON)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20191115@Terry.Nguyen
		Task:		Transform Association By Device from DCS.Assocation
		DB:			CTS_DataCenter
		Original:

		Revisions:
        #1. [20200506@CaseyHuynh][133486]: Retry Transform If > -4
        #2. [20200518@CaseyHuynh][133486]: Remove  code update IsCTSTransformed = -2 ELSE -1
        #3. [202010018@CaseyHuynh] LOG INSSUE
		#4. [20200518@CaseyHuynh] Remove Log Issue
        #5. [20201112@CaseyHuynh][145271]:
            + GET Lastest Code Move Server P3, update Permission and Add Meta data
            + Change Log table to DB Log
            + Enhance  Transform Retry
		Param's Explanation (filtered by):
                
	*/    

    
    #=========================
    DECLARE code CHAR(5) DEFAULT '00000';
    DECLARE err_no int DEFAULT 0;
    DECLARE cod_name varchar(10) DEFAULT '';
	DECLARE err_message varchar(255);
    DECLARE info_no int;
    DECLARE info_message varchar(255);
	DECLARE sch_name varchar(128) DEFAULT 'CTS_DataCenter';
    DECLARE tab_name varchar(128) DEFAULT '';
    DECLARE col_name varchar(128) DEFAULT '';
    DECLARE sp_name varchar(128) DEFAULT 'CTS_DC_TransformAssociationByDevice';
	
    # STATS count
    DECLARE insertionTime TIMESTAMP(4);
	DECLARE	batchCount INT;
    DECLARE	rowCount INT;
    
    # Perf stats
    DECLARE call_time timestamp(4);
    DECLARE start_time timestamp(4);
    DECLARE batch_time timestamp(4);
    # ERROR handler
    DECLARE continue HANDLER FOR 1062
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			info_message = MESSAGE_TEXT
			,cod_name = RETURNED_SQLSTATE
            ,info_no = MYSQL_ERRNO;
		SELECT '1062',cod_name
        ;
    END;
    
    DECLARE continue HANDLER FOR SQLWARNING
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			info_message = MESSAGE_TEXT
			,cod_name = RETURNED_SQLSTATE
            ,info_no = MYSQL_ERRNO;
		SELECT cod_name, 'SQLWARNING'
        ;
    END;
    
    DECLARE exit HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			err_message = MESSAGE_TEXT
            ,err_no = MYSQL_ERRNO
            ,cod_name = RETURNED_SQLSTATE
            ,sch_name = SCHEMA_NAME
            ,tab_name = TABLE_NAME
            ,col_name = COLUMN_NAME;
		
		SELECT err_no, err_message;
        # Write error log
        #select * from Temp_PerformanceStats;
        
        INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
		WITH CTE_Stats AS (
			SELECT CONCAT('ERROR_',err_no) AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4) ) / 1000 as diff_time, JSON_OBJECT('err_message', err_message, 'sch_name', sch_name, 'tab_name', tab_name, 'col_name', col_name) as stats
		)
        SELECT step_name, start_time, diff_time, stats
        FROM CTE_Stats;
        
        SET sch_name = IF(LENGTH(sch_name) > 0, sch_name, 'CTS_DataCenter');
        INSERT INTO CTS_Log.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
        SELECT sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, CURRENT_TIMESTAMP(4) as end_time
		FROM Temp_PerformanceStats;
        
	END;
	DROP TEMPORARY TABLE IF EXISTS Temp_PerformanceStats;
	CREATE TEMPORARY TABLE Temp_PerformanceStats(
		step_id INT SIGNED AUTO_INCREMENT PRIMARY KEY,
        step_name varchar(100),
		start_time timestamp(4),
        diff_time int,
        stats varchar(1000)
    ) ENGINE = MEMORY;   
    #===============================
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    
	CREATE TEMPORARY TABLE Temp_Association 
    (	AssociationID		BIGINT	UNSIGNED
		, AccountID			BIGINT	UNSIGNED
        , DeviceID			BIGINT	UNSIGNED
        , SubscriberID		INT
        , CreatedTime		TIMESTAMP(4)
        , CTSCustID			BIGINT	UNSIGNED
    ); 
	
    #call_time
     set call_time  = CURRENT_TIMESTAMP(4);
     set start_time  = CURRENT_TIMESTAMP(4);
		
    INSERT INTO Temp_Association
				(
                AssociationID,
                AccountID,
				DeviceID,
				SubscriberID,
                CreatedTime)                
	SELECT 	
			tmpTable.AssociationID,
			tmpTable.AccountID, 
			tmpTable.DeviceID, 
			tmpTable.SubscriberID,
            tmpTable.CreatedTime
	FROM JSON_TABLE(ip_AssociationList,
		 "$[*]" COLUMNS(
			  AssociationID 			BIGINT 			PATH "$.AssociationId"
			, AccountID 				BIGINT 			PATH "$.AccountId"
			, DeviceID					BIGINT			PATH "$.DeviceId" 
			, SubscriberID				INT				PATH "$.SubscriberId"
            , CreatedTime				TIMESTAMP(4)	PATH "$.CreatedTime"
		 )) as tmpTable;   	
	GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'GET_DATA' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount,'info_message',info_message, 'err_message', err_message,'err_no',err_no) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
    
	IF rowCount = 0 then
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'ERROR: Does not exist trans to process', MYSQL_ERRNO = 1001;
    END IF;
       
    #=========GET CTSCustID IF Existing
    set start_time  = CURRENT_TIMESTAMP(4);
    
    UPDATE 		Temp_Association AS tmp_ass
    INNER JOIN	CTS_DataCenter.CustDCSAccount AS cus 
					ON tmp_ass.AccountID = cus.AccountID
	SET			tmp_ass.CTSCustID = cus.CTSCustID;
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'SEED_CTSCustID' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount,'info_message',info_message, 'err_message', err_message,'err_no',err_no) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
   
    #=======IF CTSCustID Existing 
    set start_time  = CURRENT_TIMESTAMP(4);
	INSERT IGNORE INTO 	CTS_DataCenter.AssociationByDevice(CTSCustID, DCSDeviceID, SubscriberID, CreatedTime, InsertTime)
	SELECT 		tmp_ass.CTSCustID 
				, tmp_ass.DeviceID
				, tmp_ass.SubscriberID
				, MIN(tmp_ass.CreatedTime)	
				, CURRENT_TIMESTAMP()	AS InsertTime
	FROM 		Temp_Association 	AS tmp_ass
    WHERE		tmp_ass.CTSCustID IS NOT NULL
    GROUP BY	tmp_ass.CTSCustID, tmp_ass.DeviceID, tmp_ass.SubscriberID; 
    GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'INSERT_AssociationByDevice' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount,'info_message',info_message, 'err_message', err_message,'err_no',err_no) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;
	
	set start_time  = CURRENT_TIMESTAMP(4);
    UPDATE 		DCS_DataCenter.Association	AS ass
    INNER JOIN	Temp_Association			AS tmp_ass
				ON	ass.AccountID 		= tmp_ass.AccountID 
                AND ass.DeviceID 		= tmp_ass.DeviceID
	LEFT JOIN 	CTS_DataCenter.AssociationByDevice AS asd
				ON asd.CTSCustID 	= tmp_ass.CTSCustID  
                AND asd.DCSDeviceID = ass.DeviceID
	SET			ass.IsCTSTransformed =	(CASE WHEN asd.CTSCustID IS NOT NULL THEN 1 ELSE -1 END);
    
	GET DIAGNOSTICS rowCount = ROW_COUNT;
    INSERT INTO Temp_PerformanceStats(step_name, start_time, diff_time, stats)
    WITH CTE_Stats AS (
		SELECT 'UPDATE_Association' AS step_name, start_time, TIMESTAMPDIFF(MICROSECOND, start_time, CURRENT_TIMESTAMP(4)) / 1000 as diff_time, JSON_OBJECT('rowCount', rowCount,'info_message',info_message, 'err_message', err_message,'err_no',err_no) as stats
    )
    SELECT step_name, start_time, diff_time, stats FROM CTE_Stats
    ;

	### PERFORMANCE
	INSERT INTO CTS_Log.dba_SP_PerformanceStats (sch_name, sp_name, step_id, step_name, start_time, diff_time, stats, call_time, end_time)
	SELECT sch_name, sp_name, step_id, step_name, st.start_time, diff_time, stats, call_time, CURRENT_TIMESTAMP(4) as end_time
	FROM Temp_PerformanceStats st;
    ### PERFORMANCE: END   
                          
END$$
DELIMITER ;
