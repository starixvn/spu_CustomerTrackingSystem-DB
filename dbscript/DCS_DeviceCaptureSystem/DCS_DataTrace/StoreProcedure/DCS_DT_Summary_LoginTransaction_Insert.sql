/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DT_Summary_LoginTransaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DT_Summary_LoginTransaction_Insert`(
    IN ip_Size INT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231003@Jonathan.Doan
	Task : Insert data into LoginTransaction
	DB: DCS_DataTrace
	Original:

	Revisions:
		- 20231003@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Summary_LoginTransaction_Insert(10);
	*/
    DECLARE CONST_SUMMARY_TRANSID INT DEFAULT 1;
    DECLARE lv_MaxTransID  BIGINT UNSIGNED;
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_SUMMARY_TRANSID);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans07;
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TotalTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotTrans;
    
	CREATE TEMPORARY TABLE Temp_Trans07(
			TransID								BIGINT UNSIGNED NOT NULL PRIMARY KEY
		, 	TransDate							DATETIME NOT NULL
		, 	SubscriberID						INT UNSIGNED DEFAULT NULL
		, 	AccountID							BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID							BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged								SMALLINT DEFAULT NULL
		, 	TransTime							DATETIME DEFAULT NULL
		,	KEY `IX_Temp_Trans07_TransDate_SubscriberID` (`TransDate`, `SubscriberID`)
	);
    
	CREATE TEMPORARY TABLE Temp_LoginTrans(
			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID					BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged						SMALLINT DEFAULT NULL
		, 	FirstLoginTransTime			DATETIME DEFAULT NULL
		, 	LastLoginTransTime			DATETIME DEFAULT NULL
		, 	TotalTrans					INT UNSIGNED DEFAULT 0
		, 	IsUpdate					BIT DEFAULT 0
		,	KEY `IX_Temp_LoginTrans_Group` (`TransDate`, `SubscriberID`)
	);
    
	CREATE TEMPORARY TABLE Temp_TotalTrans(
			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	TotalTrans					INT UNSIGNED DEFAULT 0
		, 	IsUpdate					BIT DEFAULT 0
		,	KEY `IX_Temp_TotalTrans` (`TransDate`, `SubscriberID`)
	);
    
	CREATE TEMPORARY TABLE Temp_RobotTrans(
			ID							INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	TotalInvalidBrowers			INT UNSIGNED DEFAULT 0
		, 	TotalBotTrans				INT UNSIGNED DEFAULT 0
		, 	IsUpdate					BIT DEFAULT 0
		,	KEY `IX_Temp_RobotTrans` (`TransDate`, `SubscriberID`)
	);
    
    INSERT INTO Temp_Trans07(TransID, TransDate, AccountID, SubscriberID, DeviceID, Flagged, TransTime)
    SELECT 	trans.TransID
		,	DATE(trans.TransTime) AS TransDate
		,	trans.AccountID
        ,	trans.SubscriberID
		,	trans.DeviceID
        ,	trans.Flagged
        ,	trans.TransTime
	FROM DCS_DataCenter.Transaction07 AS trans
    WHERE trans.TransID > lv_MaxTransID
    ORDER BY trans.TransID ASC
    LIMIT ip_Size;
    
    SET lv_MaxTransID = (SELECT MAX(TransID) FROM Temp_Trans07);
    
    /* == LoginTransaction == */
    INSERT INTO Temp_LoginTrans(TransDate, AccountID, SubscriberID, DeviceID, Flagged, FirstLoginTransTime, LastLoginTransTime, TotalTrans)
    SELECT 	TransDate
		,	AccountID
        ,	SubscriberID
		,	DeviceID
        ,	Flagged
        ,	MIN(TransTime) AS FirstLoginTransTime
        ,	MAX(TransTime) AS LastLoginTransTime
        ,	COUNT(1) AS TotalTrans
	FROM Temp_Trans07
    GROUP BY TransDate, SubscriberID, AccountID, DeviceID, Flagged;
    
    UPDATE DCS_DataTrace.LoginTransaction AS tl
		INNER JOIN Temp_LoginTrans AS tmp ON 	tl.TransDate = tmp.TransDate
											AND tl.SubscriberID = tmp.SubscriberID
											AND tl.AccountID = tmp.AccountID
											AND tl.DeviceID = tmp.DeviceID
											AND tl.Flagged = tmp.Flagged
	SET tl.TotalTrans = tl.TotalTrans + tmp.TotalTrans,
		tl.FirstLoginTransTime = tmp.FirstLoginTransTime,
		tl.LastLoginTransTime = tmp.LastLoginTransTime,
		tl.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataTrace.LoginTransaction(TransDate, AccountID, SubscriberID, DeviceID, Flagged, FirstLoginTransTime, LastLoginTransTime, TotalTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
		,	tmp.AccountID
        ,	tmp.SubscriberID
		,	tmp.DeviceID
        ,	tmp.Flagged
        ,	tmp.FirstLoginTransTime
        ,	tmp.LastLoginTransTime
        ,	tmp.TotalTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_LoginTrans AS tmp
    WHERE tmp.IsUpdate = 0;

    /* == DailyLoginTransactionMonitoring == */        
    INSERT INTO Temp_TotalTrans(TransDate, SubscriberID, TotalTrans)
    SELECT 	TransDate
        ,	SubscriberID
        ,	COUNT(1) AS TotalTrans
	FROM Temp_Trans07 AS tmp
    GROUP BY TransDate, SubscriberID;
    
    UPDATE DCS_DataTrace.DailyLoginTransactionMonitoring AS dt
		INNER JOIN Temp_TotalTrans AS tmp ON 	dt.TransDate = tmp.TransDate
											AND dt.SubscriberID = tmp.SubscriberID
	SET dt.TotalTrans = dt.TotalTrans + tmp.TotalTrans,
		dt.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataTrace.DailyLoginTransactionMonitoring(TransDate, SubscriberID, TotalTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
        ,	tmp.SubscriberID
        ,	tmp.TotalTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_TotalTrans AS tmp
    WHERE tmp.IsUpdate = 0;
    
    /* == DailyRobotMonitoring == */
    INSERT INTO Temp_RobotTrans(TransDate, SubscriberID, TotalInvalidBrowers, TotalBotTrans)
    SELECT 	TransDate
        ,	SubscriberID
        ,	SUM(CASE WHEN Flagged BETWEEN 2 AND 8 THEN 1 ELSE 0 END ) AS TotalInvalidBrowers
        ,	SUM(CASE WHEN Flagged > 8 THEN 1 ELSE 0 END ) AS TotalBotTrans
	FROM Temp_Trans07
    GROUP BY TransDate, SubscriberID;
    
    UPDATE DCS_DataTrace.DailyRobotMonitoring AS dt
		INNER JOIN Temp_RobotTrans AS tmp ON dt.TransDate = tmp.TransDate AND dt.SubscriberID = tmp.SubscriberID
	SET dt.TotalInvalidBrowers = dt.TotalInvalidBrowers + tmp.TotalInvalidBrowers,
		dt.TotalBotTrans = dt.TotalBotTrans + tmp.TotalBotTrans,
		dt.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataTrace.DailyRobotMonitoring(TransDate, SubscriberID, TotalInvalidBrowers, TotalBotTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
        ,	tmp.SubscriberID
        ,	tmp.TotalInvalidBrowers
        ,	tmp.TotalBotTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_RobotTrans AS tmp
    WHERE tmp.IsUpdate = 0
		AND (tmp.TotalInvalidBrowers > 0 OR tmp.TotalBotTrans > 0);
    
    IF(lv_MaxTransID IS NOT NULL AND lv_MaxTransID > 0) THEN
        UPDATE DCS_DataTrace.SystemSetting 
        SET VValue = lv_MaxTransID
        WHERE ID = CONST_SUMMARY_TRANSID;
    END IF;
END$$
DELIMITER ;
