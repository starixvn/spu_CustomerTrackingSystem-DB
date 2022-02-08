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
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Event_Schedule();
	*/
    DECLARE lv_CurUser			VARCHAR(50);
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
		CurUser		VARCHAR(100),
		DB			VARCHAR(100),
		EventName 	VARCHAR(100),
		`Status`	VARCHAR(15),
		PRIMARY KEY(EventName)
	) ENGINE=InnoDB;
	
    SELECT CURRENT_USER() INTO lv_CurUser;
    SET lv_NowGMT7 = DATE_ADD(NOW(), INTERVAL 11 HOUR);
	SET lv_CurDate = DATE(lv_NowGMT7);
	SET lv_CurTime = TIME(lv_NowGMT7);
	SET lv_DayOfWeek = WEEKDAY(lv_NowGMT7);
    #SELECT lv_NowGMT7, lv_CurDate, lv_CurTime, lv_DayOfWeek ;
    
	INSERT IGNORE INTO Temp_EventStatus(DB,EventName,`Status`,CurUser)
	SELECT 	EVENT_SCHEMA
		,	EVENT_NAME 
		,	`STATUS`
        ,	`DEFINER`
	FROM information_schema.events AS ev
    WHERE ev.EVENT_NAME IN (SELECT evst.EventName FROM MonDB.SystemEventStatus AS evst);
	
    IF EXISTS ( SELECT * 
				FROM MonDB.SystemEventSchedule
				WHERE EventName = 'UM' 
					AND DateUM = lv_CurDate
					AND lv_CurTime >= FromTime
					AND lv_CurTime <= ToTime) THEN     
        SELECT GROUP_CONCAT(EventName)
        INTO lv_ListEvent
        FROM Temp_EventStatus 
        WHERE `Status` = 'ENABLED';
        
        CALL MonDB.DBA_Event_SetStatus(lv_ListEvent, 'ENABLE');
        
        LEAVE sp;
	END IF;
	
    SELECT GROUP_CONCAT(sch.EventName) 
    INTO lv_ListEventStop
	FROM MonDB.SystemEventSchedule AS sch
	WHERE EXISTS (SELECT 1 FROM Temp_EventStatus AS ev WHERE sch.EventName = ev.EventName AND `Status` = 'ENABLED') 
		AND sch.FromTime >= lv_CurTime
		AND sch.ToTime <= lv_CurTime ;
	
    IF lv_ListEventStop IS NOT NULL THEN
		CALL MonDB.DBA_Event_SetStatus(lv_ListEvent, 'DISABLE');
    END IF;
	
    SELECT GROUP_CONCAT(sch.EventName) 
    INTO lv_ListEventStart
	FROM MonDB.SystemEventSchedule AS sch
	WHERE EXISTS (SELECT 1 FROM Temp_EventStatus AS ev WHERE sch.EventName = ev.EventName AND sch.`Status` = 'DISABLED' AND sch.`DEFINER` = lv_CurUser) 
		AND (sch.FromTime < lv_CurTime OR sch.ToTime > lv_CurTime);
    
    IF lv_ListEventStop IS NOT NULL THEN
		CALL MonDB.DBA_Event_SetStatus(lv_ListEventStart, 'ENABLE');
    END IF;
    
END$$
DELIMITER ;
