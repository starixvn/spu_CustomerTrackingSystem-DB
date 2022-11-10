/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Event_Schedule`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Event_Schedule`()
    SQL SECURITY INVOKER
sp:BEGIN
	/*
		Created:	20210816@Aries.Nguyen
		Task:		Grafana Monitor Table IO Metric 
		DB:			MonDB
		Original: 
 
		Revisions:
			- 20210127@Aries.Nguyen: Created [Redmine ID: #160195]
			- 20220315@Aries.Nguyen: Turn off events when the server is high load [Redmine ID: #169883]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Event_Schedule();
	*/
    DECLARE lv_IsHighLoad				BIT DEFAULT 0;
    DECLARE lv_UMScheduleID				INT UNSIGNED DEFAULT 0;
    DECLARE lv_TotalTransPending		BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_TotalMMLivePending		BIGINT UNSIGNED DEFAULT 0;
    
    DECLARE lv_SumTransBatchSize_Curr			INT;
    DECLARE lv_SumTransBatchSize_Min			INT DEFAULT 200;
	DECLARE lv_SumTransBatchSize_Max			INT DEFAULT 5000;
    DECLARE CONST_SysParaID_SumTransBatchSize	INT DEFAULT 12;
    
    DECLARE lv_NowGMT7			DATETIME;
    DECLARE lv_CurDate			DATE;
    DECLARE lv_CurTime			TIME;
    DECLARE lv_DayOfWeek		SMALLINT;
    DECLARE lv_HasUM			BIT DEFAULT 0;
    DECLARE lv_ListEvent		LONGTEXT;
    DECLARE lv_ListEventStop	LONGTEXT;
    DECLARE lv_ListEventStart	LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_EventStatus;
	CREATE TEMPORARY TABLE Temp_EventStatus (
		DB			VARCHAR(100),
		EventName 	VARCHAR(100),
		`Status`	VARCHAR(15),
		PRIMARY KEY(EventName)
	) ENGINE=InnoDB;
	
  
    SET lv_NowGMT7 = DATE_ADD(NOW(), INTERVAL 11 HOUR);
	SET lv_CurDate = DATE(lv_NowGMT7);
	SET lv_CurTime = TIME(lv_NowGMT7);
	SET lv_DayOfWeek = WEEKDAY(lv_NowGMT7);

    
	INSERT IGNORE INTO Temp_EventStatus(DB,EventName,`Status`)
	SELECT 	EVENT_SCHEMA
		,	EVENT_NAME 
		,	`STATUS`
	FROM information_schema.events AS ev
    WHERE ev.EVENT_NAME IN (SELECT evst.EventName FROM MonDB.MysqlEvent AS evst);
	
    SELECT ID 
    INTO lv_UMScheduleID
	FROM MonDB.SystemEventSchedule
	WHERE EventName = 'UM' 
		AND DateUM = lv_CurDate
		AND lv_CurTime >= FromTime
		AND lv_CurTime <= ToTime;
    
    SELECT  TABLE_ROWS 
    INTO lv_TotalMMLivePending
	FROM information_schema.tables 
	WHERE TABLE_SCHEMA = 'CTS_DataCenter' 
		AND TABLE_NAME = 'MatchMonitorStagingLive'
		AND TABLE_CATALOG = 'def';
        
	SELECT  TABLE_ROWS 
    INTO lv_TotalTransPending
	FROM information_schema.tables 
	WHERE TABLE_SCHEMA = 'DCS_DataCenter' 
		AND TABLE_NAME = 'Transaction'
        AND TABLE_CATALOG = 'def';
	
    SELECT VValue
    INTO lv_SumTransBatchSize_Curr
    FROM DCS_DataCenter.SystemSetting 
    WHERE ID = CONST_SysParaID_SumTransBatchSize;
        
    IF lv_UMScheduleID > 0 OR lv_TotalTransPending > 100000 OR lv_TotalMMLivePending > 100000 THEN     
        SET lv_IsHighLoad = 1;
	ELSE 
		IF lv_SumTransBatchSize_Curr < lv_SumTransBatchSize_Max THEN
			UPDATE DCS_DataCenter.SystemSetting 
			SET VValue = lv_SumTransBatchSize_Max 
			WHERE ID = CONST_SysParaID_SumTransBatchSize;
        END IF;
    END IF;
	
    SELECT GROUP_CONCAT(DISTINCT sch.EventName) 
    INTO lv_ListEventStop
	FROM MonDB.SystemEventSchedule AS sch
	WHERE EXISTS (SELECT 1 FROM Temp_EventStatus AS ev WHERE sch.EventName = ev.EventName AND `Status` = 'ENABLED') 
		AND sch.FromTime <= lv_CurTime
		AND sch.ToTime >= lv_CurTime ;
        
    IF lv_ListEventStop IS NOT NULL THEN
		CALL MonDB.DBA_Event_SetStatus(lv_ListEventStop, 'DISABLE');
    END IF;
	
    SELECT GROUP_CONCAT(DISTINCT sch.EventName) 
    INTO lv_ListEventStart
	FROM MonDB.SystemEventSchedule AS sch
	WHERE EXISTS (SELECT 1 FROM Temp_EventStatus AS ev WHERE sch.EventName = ev.EventName AND ev.`Status` = 'DISABLED') 
		AND (sch.FromTime > lv_CurTime OR sch.ToTime < lv_CurTime);
    
    IF lv_ListEventStart IS NOT NULL AND lv_IsHighLoad = 0 THEN
		CALL MonDB.DBA_Event_SetStatus(lv_ListEventStart, 'ENABLE');
    END IF;
    
    SELECT GROUP_CONCAT(DISTINCT ev.EventName) 
    INTO lv_ListEvent
    FROM Temp_EventStatus AS ev;

    IF lv_IsHighLoad = 1 THEN
		CALL MonDB.DBA_Event_SetStatus(lv_ListEvent, 'DISABLE');
        
        UPDATE DCS_DataCenter.SystemSetting 
        SET VValue = lv_SumTransBatchSize_Min 
        WHERE ID = CONST_SysParaID_SumTransBatchSize;
    END IF;
    
END$$
DELIMITER ;
