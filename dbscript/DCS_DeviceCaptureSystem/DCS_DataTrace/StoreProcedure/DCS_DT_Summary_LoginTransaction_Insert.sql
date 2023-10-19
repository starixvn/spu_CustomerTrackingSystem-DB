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
    
	CREATE TEMPORARY TABLE Temp_Trans07(
			TransID						BIGINT UNSIGNED NOT NULL PRIMARY KEY
		, 	TransDate					DATETIME NOT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID					BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged						SMALLINT DEFAULT NULL
		, 	TransTime					DATETIME DEFAULT NULL
		,	KEY `IX_Temp_Trans07_TransDate_SubscriberID` (`TransDate`, `SubscriberID`)
	);
    
	CREATE TEMPORARY TABLE Temp_LoginTrans(
			ID							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	TransDate					DATETIME NOT NULL
		, 	TransWeek					INT UNSIGNED DEFAULT NULL
		, 	TransMonth					INT UNSIGNED DEFAULT NULL
		, 	SubscriberID				INT UNSIGNED DEFAULT NULL
		, 	SubscriberName				VARCHAR(50) DEFAULT NULL
		, 	AccountID					BIGINT UNSIGNED DEFAULT NULL
		, 	CTSCustID					BIGINT UNSIGNED DEFAULT NULL
		, 	LoginName					VARCHAR(100) DEFAULT NULL
		, 	DeviceID					BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged						SMALLINT DEFAULT NULL
		, 	FlaggedGroup				SMALLINT DEFAULT NULL
		, 	TotalTrans					INT UNSIGNED DEFAULT 0
		, 	FirstLoginTransTime			DATETIME DEFAULT NULL
		, 	LastLoginTransTime			DATETIME DEFAULT NULL
		, 	IsUpdate					BIT DEFAULT 0
		,	KEY `IX_Temp_LoginTrans_Group` (`TransDate`, `SubscriberID`, `AccountID`, `DeviceID`, `Flagged`)
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
    INSERT INTO Temp_LoginTrans(TransDate, SubscriberID, AccountID, DeviceID, Flagged, FirstLoginTransTime, LastLoginTransTime, TotalTrans)
    SELECT 	TransDate
        ,	SubscriberID
		,	AccountID
		,	DeviceID
        ,	Flagged
        ,	MIN(TransTime) AS FirstLoginTransTime
        ,	MAX(TransTime) AS LastLoginTransTime
        ,	COUNT(1) AS TotalTrans
	FROM Temp_Trans07 AS tmp
    GROUP BY TransDate, SubscriberID, AccountID, DeviceID, Flagged;
    
    UPDATE Temp_LoginTrans AS tmp
		LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = tmp.SubscriberID
		LEFT JOIN DCS_DataCenter.Account AS acc ON acc.AccountID = tmp.AccountID
		LEFT JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.AccountID = tmp.AccountID
		LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.ItemID = tmp.Flagged
	SET tmp.TransWeek = YEARWEEK(tmp.TransDate, 0),
		tmp.TransMonth = DATE_FORMAT(tmp.TransDate, '%Y%m'),
		tmp.SubscriberName = sub.SubscriberName,
		tmp.LoginName = acc.LoginName,
		tmp.CTSCustID = dcs.CTSCustID,
		tmp.FlaggedGroup = sl.GroupItem;
	
    UPDATE DCS_DataTrace.LoginTransactionSummary AS tl
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
    
    INSERT INTO DCS_DataTrace.LoginTransactionSummary(TransDate, TransWeek, TransMonth, SubscriberID, SubscriberName, AccountID, CTSCustID, LoginName, DeviceID, Flagged, FlaggedGroup, FirstLoginTransTime, LastLoginTransTime, TotalTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.TransDate
		,	tmp.TransWeek
		,	tmp.TransMonth
        ,	tmp.SubscriberID
        ,	tmp.SubscriberName
		,	tmp.AccountID
		,	tmp.CTSCustID
		,	tmp.LoginName
		,	tmp.DeviceID
        ,	tmp.Flagged
        ,	tmp.FlaggedGroup
        ,	tmp.FirstLoginTransTime
        ,	tmp.LastLoginTransTime
        ,	tmp.TotalTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_LoginTrans AS tmp
    WHERE tmp.IsUpdate = 0;
    
    IF(lv_MaxTransID IS NOT NULL AND lv_MaxTransID > 0) THEN
        UPDATE DCS_DataTrace.SystemSetting 
        SET VValue = lv_MaxTransID
        WHERE ID = CONST_SUMMARY_TRANSID;
    END IF;
END$$
DELIMITER ;
