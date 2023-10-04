/*<info serverAlias="CTSMain-DCS_DataWatch" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DW_Sumary_Transaction_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DW_Sumary_Transaction_Insert`(
    IN ip_Size INT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20231003@Jonathan.Doan
	Task : Insert data into TransactionLite
	DB: DCS_DataWatch
	Original:

	Revisions:
		- 20231003@Jonathan.Doan: Created [Redmine ID: 194933]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataWatch.DCS_DW_Sumary_Transaction_Insert(10);
	*/
    DECLARE lv_MaxTransID  BIGINT UNSIGNED;
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataWatch.SystemSetting WHERE ID = 1);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransLite;
	DROP TEMPORARY TABLE IF EXISTS Temp_TotalTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotTrans;
    
	CREATE TEMPORARY TABLE Temp_Trans(
			TransID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		, 	TransDate						DATETIME NOT NULL
		, 	SubscriberID					INT UNSIGNED DEFAULT NULL
		, 	AccountID						BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID						BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged							SMALLINT DEFAULT NULL
		, 	DailyTransactionMonitoringID	INT UNSIGNED DEFAULT NULL
		, 	CustID							INT UNSIGNED DEFAULT NULL
		, 	RoleID							TINYINT DEFAULT NULL
		,	KEY `IX_Temp_Trans_TransDate_SubscriberID` (`TransDate`, `SubscriberID`)
	);
    
	CREATE TEMPORARY TABLE Temp_TransLite(
			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID					BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged						SMALLINT DEFAULT NULL
		, 	TotalTrans					INT UNSIGNED DEFAULT 0
		, 	IsUpdate					BIT DEFAULT 0
		,	KEY `IX_Temp_TransLite` (`TransDate`, `SubscriberID`)
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
			DailyTransactionMonitoringID	INT UNSIGNED NOT NULL PRIMARY KEY 
		, 	TotalInvalidBrowers				INT UNSIGNED DEFAULT 0
		, 	TotalBotTrans					INT UNSIGNED DEFAULT 0
		, 	IsUpdate						BIT DEFAULT 0
	);
    
    INSERT INTO Temp_Trans(TransID, TransDate, AccountID, SubscriberID, DeviceID, Flagged)
    SELECT 	TransID
		,	CreatedDate AS TransDate
		,	AccountID
        ,	SubscriberID
		,	DeviceID
        ,	Flagged
	FROM DCS_DataCenter.Transaction07
    WHERE TransID > lv_MaxTransID
    LIMIT ip_Size;

    INSERT INTO Temp_TransLite(TransDate, AccountID, SubscriberID, DeviceID, Flagged, TotalTrans)
    SELECT 	TransDate
		,	AccountID
        ,	SubscriberID
		,	DeviceID
        ,	Flagged
        ,	COUNT(1) AS TotalTrans
	FROM Temp_Trans
    GROUP BY TransDate, SubscriberID, AccountID, DeviceID, Flagged;
    
    /* == TransactionLite == */
    UPDATE DCS_DataWatch.TransactionLite AS tl
	INNER JOIN Temp_TransLite AS tmp ON 	tl.TransDate = tmp.TransDate
										AND tl.SubscriberID = tmp.SubscriberID
										AND tl.AccountID = tmp.AccountID
										AND tl.DeviceID = tmp.DeviceID
										AND tl.Flagged = tmp.Flagged
	SET tl.TotalTrans = tl.TotalTrans + tmp.TotalTrans,
		tl.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataWatch.TransactionLite(TransDate, AccountID, SubscriberID, DeviceID, Flagged, TotalTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
		,	tmp.AccountID
        ,	tmp.SubscriberID
		,	tmp.DeviceID
        ,	tmp.Flagged
        ,	tmp.TotalTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_TransLite AS tmp
    WHERE tmp.IsUpdate = 0;

    /* == DailyTransactionMonitoring == */        
    INSERT INTO Temp_TotalTrans(TransDate, SubscriberID, TotalTrans)
    SELECT 	TransDate
        ,	SubscriberID
        ,	COUNT(1) AS TotalTrans
	FROM Temp_Trans AS tmp
    GROUP BY TransDate, SubscriberID;
    
    UPDATE DCS_DataWatch.DailyTransactionMonitoring AS dt
		INNER JOIN Temp_TotalTrans AS tmp ON 	dt.TransDate = tmp.TransDate
											AND dt.SubscriberID = tmp.SubscriberID
	SET dt.TotalTrans = dt.TotalTrans + tmp.TotalTrans,
		dt.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataWatch.DailyTransactionMonitoring(TransDate, SubscriberID, TotalTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
        ,	tmp.SubscriberID
        ,	tmp.TotalTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_TotalTrans AS tmp
    WHERE tmp.IsUpdate = 0;
    
    UPDATE Temp_Trans AS tmp
		INNER JOIN DCS_DataWatch.DailyTransactionMonitoring AS dt ON dt.TransDate = tmp.TransDate
																AND dt.SubscriberID = tmp.SubscriberID
	SET tmp.DailyTransactionMonitoringID = dt.ID;
    
    /* == DailyRobotMonitoring == */
    INSERT INTO Temp_RobotTrans(DailyTransactionMonitoringID, TotalInvalidBrowers, TotalBotTrans)
    SELECT 	DailyTransactionMonitoringID
        ,	SUM(CASE WHEN Flagged BETWEEN 2 AND 8 THEN 1 ELSE 0 END ) AS TotalInvalidBrowers
        ,	SUM(CASE WHEN Flagged > 8 THEN 1 ELSE 0 END ) AS TotalBotTrans
	FROM Temp_Trans
    GROUP BY DailyTransactionMonitoringID;
    
    UPDATE DCS_DataWatch.DailyRobotMonitoring AS dt
		INNER JOIN Temp_RobotTrans AS tmp ON dt.DailyTransactionMonitoringID = tmp.DailyTransactionMonitoringID
	SET dt.TotalInvalidBrowers = dt.TotalInvalidBrowers + tmp.TotalInvalidBrowers,
		dt.TotalBotTrans = dt.TotalBotTrans + tmp.TotalBotTrans,
		dt.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataWatch.DailyRobotMonitoring(DailyTransactionMonitoringID, TotalInvalidBrowers, TotalBotTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.DailyTransactionMonitoringID
        ,	tmp.TotalInvalidBrowers
        ,	tmp.TotalBotTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_RobotTrans AS tmp
    WHERE tmp.IsUpdate = 0;
END$$
DELIMITER ;
