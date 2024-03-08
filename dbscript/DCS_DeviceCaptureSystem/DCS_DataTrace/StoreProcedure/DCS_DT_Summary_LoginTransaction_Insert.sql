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
		- 20231026@Jonathan.Doan: Add FlaggedGroupID [Redmine ID: 195332]
		- 20240308@Jonathan.Doan: Add more field to monitoring botd [Redmine ID: 199295]
		
	Param's Explanation (filtered by):

	Example:
		SET sql_safe_updates = 0;
        CALL DCS_DataTrace.DCS_DT_Summary_LoginTransaction_Insert(10);
	*/
    DECLARE CONST_SUMMARY_TRANSID 					INT 		DEFAULT 1;
    DECLARE CONST_FLAGGEDGROUPID_INVALIDBROWSER		SMALLINT 	DEFAULT 2;
    DECLARE CONST_FLAGGEDGROUPID_BOTTRANS 			SMALLINT 	DEFAULT 3;
    
    DECLARE lv_MaxTransID  			BIGINT UNSIGNED;
    DECLARE lv_CurrentDatetime 		DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataTrace.SystemSetting WHERE ID = CONST_SUMMARY_TRANSID);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans07;
	DROP TEMPORARY TABLE IF EXISTS Temp_LoginTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TotalTrans;
    
	CREATE TEMPORARY TABLE Temp_Trans07(
			TransID						BIGINT UNSIGNED NOT NULL PRIMARY KEY
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
		, 	RawUserAgentID				BIGINT UNSIGNED DEFAULT NULL
		, 	NoDeviceID					INT DEFAULT NULL 
		, 	NoFPDeviceID				INT DEFAULT NULL
		, 	Flagged						SMALLINT DEFAULT NULL
		, 	FlaggedGroupID				SMALLINT DEFAULT NULL
		, 	TransTime					DATETIME DEFAULT NULL
		,	KEY `IX_Temp_Trans07_TransDate_SubscriberID` (`TransDate`, `SubscriberID`)
		,	KEY `IX_Temp_Trans07_Flagged` (`Flagged`)
	);
    
	CREATE TEMPORARY TABLE Temp_LoginTrans(
			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
		, 	RawUserAgentID				BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged						SMALLINT DEFAULT NULL
		, 	FlaggedGroupID				SMALLINT DEFAULT NULL
		, 	TotalTrans					INT UNSIGNED DEFAULT 0
		, 	TotalNoDeviceTrans			INT UNSIGNED DEFAULT 0
		, 	TotalNoFPDeviceTrans		INT UNSIGNED DEFAULT 0
		, 	FirstLoginTransTime			DATETIME DEFAULT NULL
		, 	LastLoginTransTime			DATETIME DEFAULT NULL
		, 	IsUpdate					BIT DEFAULT 0
		,	KEY `IX_Temp_LoginTrans_Group` (`TransDate`, `SubscriberID`, `AccountID`, `RawUserAgentID`, `Flagged`)
	);
    
	CREATE TEMPORARY TABLE Temp_TotalTrans(
			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	TotalTrans					INT UNSIGNED DEFAULT 0
		, 	TotalNoDeviceTrans			INT UNSIGNED DEFAULT 0
		, 	TotalNoFPDeviceTrans		INT UNSIGNED DEFAULT 0
		, 	TotalInvalidBrowers			INT UNSIGNED DEFAULT 0
		, 	TotalBotTrans				INT UNSIGNED DEFAULT 0
		, 	IsUpdate					BIT DEFAULT 0
	);
    
    INSERT INTO Temp_Trans07(TransID, TransDate, AccountID, SubscriberID, RawUserAgentID, Flagged, TransTime, NoDeviceID, NoFPDeviceID)
    SELECT 	trans.TransID
		,	DATE(trans.TransTime) AS TransDate
		,	IFNULL(trans.AccountID,0) AS AccountID
        ,	IFNULL(trans.SubscriberID,0) AS SubscriberID
		,	IFNULL(trans.RawUserAgentID,0) AS RawUserAgentID
        ,	IFNULL(trans.Flagged,0) AS Flagged
        ,	trans.TransTime
        ,	CASE WHEN IFNULL(trans.DeviceID,0) = 0 THEN 1 ELSE 0 END AS NoDeviceID
        ,	CASE WHEN IFNULL(trans.FPDeviceID,0) = 0 THEN 1 ELSE 0 END AS NoFPDeviceID
	FROM DCS_DataCenter.Transaction07 AS trans
    WHERE trans.TransID > lv_MaxTransID
    ORDER BY trans.TransID ASC
    LIMIT ip_Size;
    
    UPDATE Temp_Trans07 AS tmp
		LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.ItemID = tmp.Flagged
	SET tmp.FlaggedGroupID = sl.GroupID;
    
    SET lv_MaxTransID = (SELECT MAX(TransID) FROM Temp_Trans07);
    
    /* == LoginTransaction == */
    INSERT INTO Temp_LoginTrans(TransDate, SubscriberID, AccountID, RawUserAgentID, Flagged, FlaggedGroupID, FirstLoginTransTime, LastLoginTransTime, TotalTrans, TotalNoDeviceTrans, TotalNoFPDeviceTrans)
    SELECT 	TransDate
        ,	SubscriberID
		,	AccountID
		,	RawUserAgentID
        ,	Flagged
        ,	FlaggedGroupID
        ,	MIN(TransTime) AS FirstLoginTransTime
        ,	MAX(TransTime) AS LastLoginTransTime
        ,	COUNT(1) AS TotalTrans
        ,	SUM(NoDeviceID) AS TotalNoDeviceTrans
        ,	SUM(NoFPDeviceID) AS TotalNoFPDeviceTrans
	FROM Temp_Trans07
    GROUP BY TransDate, SubscriberID, AccountID, RawUserAgentID, Flagged, FlaggedGroupID;
	
    UPDATE DCS_DataTrace.LoginTransactionSummary_Daily AS lt
		INNER JOIN Temp_LoginTrans AS tmp ON 	lt.TransDate 		= tmp.TransDate
											AND lt.SubscriberID 	= tmp.SubscriberID
											AND lt.AccountID 		= tmp.AccountID
											AND lt.RawUserAgentID 	= tmp.RawUserAgentID
											AND lt.Flagged 			= tmp.Flagged
	SET lt.TotalTrans 			= lt.TotalTrans + tmp.TotalTrans,
		lt.TotalNoDeviceTrans 	= lt.TotalNoDeviceTrans + tmp.TotalNoDeviceTrans,
		lt.TotalNoFPDeviceTrans = lt.TotalNoFPDeviceTrans + tmp.TotalNoFPDeviceTrans,
		lt.FirstLoginTransTime 	= tmp.FirstLoginTransTime,
		lt.LastLoginTransTime 	= tmp.LastLoginTransTime,
		lt.ModifiedTime 		= lv_CurrentDatetime,
		tmp.IsUpdate 			= 1;
    
    INSERT INTO DCS_DataTrace.LoginTransactionSummary_Daily(TransDate, SubscriberID, AccountID, RawUserAgentID, Flagged, FlaggedGroupID, FirstLoginTransTime, LastLoginTransTime, TotalTrans, TotalNoDeviceTrans, TotalNoFPDeviceTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
        ,	tmp.SubscriberID
		,	tmp.AccountID
		,	tmp.RawUserAgentID
        ,	tmp.Flagged
        ,	tmp.FlaggedGroupID
        ,	tmp.FirstLoginTransTime
        ,	tmp.LastLoginTransTime
        ,	tmp.TotalTrans
        ,	tmp.TotalNoDeviceTrans
        ,	tmp.TotalNoFPDeviceTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_LoginTrans AS tmp
    WHERE tmp.IsUpdate = 0;

    /* == DailyLoginTransactionMonitoring == */        
    INSERT INTO Temp_TotalTrans(TransDate, SubscriberID, TotalTrans, TotalNoDeviceTrans, TotalNoFPDeviceTrans, TotalInvalidBrowers, TotalBotTrans)
    SELECT 	TransDate
        ,	SubscriberID
        ,	COUNT(1) AS TotalTrans
        ,	SUM(NoDeviceID) AS TotalNoDeviceTrans
        ,	SUM(NoFPDeviceID) AS TotalNoFPDeviceTrans
        ,	SUM(CASE WHEN FlaggedGroupID = CONST_FLAGGEDGROUPID_INVALIDBROWSER THEN 1 ELSE 0 END ) AS TotalInvalidBrowers
        ,	SUM(CASE WHEN FlaggedGroupID = CONST_FLAGGEDGROUPID_BOTTRANS THEN 1 ELSE 0 END ) AS TotalBotTrans
	FROM Temp_Trans07
    GROUP BY TransDate, SubscriberID;
    
    UPDATE DCS_DataTrace.LoginTransactionSummaryBySubscriber AS trans
		INNER JOIN Temp_TotalTrans AS tmp ON trans.TransDate = tmp.TransDate AND trans.SubscriberID = tmp.SubscriberID
	SET trans.TotalTrans 			= trans.TotalTrans 				+ tmp.TotalTrans,
		trans.TotalNoDeviceTrans 	= trans.TotalNoDeviceTrans 		+ tmp.TotalNoDeviceTrans,
		trans.TotalNoFPDeviceTrans 	= trans.TotalNoFPDeviceTrans 	+ tmp.TotalNoFPDeviceTrans,
		trans.TotalInvalidBrowers 	= trans.TotalInvalidBrowers 	+ tmp.TotalInvalidBrowers,
		trans.TotalBotTrans 		= trans.TotalBotTrans 			+ tmp.TotalBotTrans,
		trans.ModifiedTime 			= lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataTrace.LoginTransactionSummaryBySubscriber(TransDate, SubscriberID, TotalTrans, TotalNoDeviceTrans, TotalNoFPDeviceTrans, TotalInvalidBrowers, TotalBotTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
        ,	tmp.SubscriberID
        ,	tmp.TotalTrans
        ,	tmp.TotalNoDeviceTrans
        ,	tmp.TotalNoFPDeviceTrans
        ,	tmp.TotalInvalidBrowers
        ,	tmp.TotalBotTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_TotalTrans AS tmp
    WHERE tmp.IsUpdate = 0;
    
    IF(lv_MaxTransID IS NOT NULL AND lv_MaxTransID > 0) THEN
        UPDATE DCS_DataTrace.SystemSetting 
        SET VValue = lv_MaxTransID
        WHERE ID = CONST_SUMMARY_TRANSID;
    END IF;
END$$
DELIMITER ;
