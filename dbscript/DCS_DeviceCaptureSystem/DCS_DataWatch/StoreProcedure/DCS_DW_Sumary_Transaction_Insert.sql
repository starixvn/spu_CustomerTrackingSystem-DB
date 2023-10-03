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
		- CALL DCS_DataWatch.DCS_DW_Sumary_Transaction_Insert(10);
	*/
    DECLARE lv_MaxTransID  BIGINT UNSIGNED;
    DECLARE lv_CurrentDatetime DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    SET lv_MaxTransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataWatch.SystemSetting WHERE ID = 1);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Trans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TotalTrans;
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_Trans(
			TransID				BIGINT UNSIGNED NOT NULL PRIMARY KEY
		, 	CreatedDate			DATETIME NOT NULL
		, 	AccountID			BIGINT UNSIGNED DEFAULT NULL
		, 	SubscriberID		BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID			BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged				SMALLINT DEFAULT NULL
	);
    
	#======GET DATA FROM RAW TRANSACTION===========================
	CREATE TEMPORARY TABLE Temp_TotalTrans(
			ID					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
		, 	CreatedDate			DATETIME NOT NULL
		, 	AccountID			BIGINT UNSIGNED DEFAULT NULL
		, 	SubscriberID		BIGINT UNSIGNED DEFAULT NULL
		, 	DeviceID			BIGINT UNSIGNED DEFAULT NULL
		, 	Flagged				SMALLINT DEFAULT NULL
		, 	TotalTrans			INT UNSIGNED DEFAULT 0
		, 	IsUpdate			BIT DEFAULT 0
	);
    
    INSERT INTO Temp_Trans(TransID, CreatedDate, AccountID, SubscriberID, DeviceID, Flagged)
    SELECT 	TransID
		,	CreatedDate
		,	AccountID
        ,	SubscriberID
		,	DeviceID
        ,	Flagged
	FROM DCS_DataCenter.Transaction07
    WHERE TransID > lv_MaxTransID
    LIMIT ip_Size;

    INSERT INTO Temp_TotalTrans(CreatedDate, AccountID, SubscriberID, DeviceID, Flagged, TotalTrans)
    SELECT 	CreatedDate
		,	AccountID
        ,	SubscriberID
		,	DeviceID
        ,	Flagged
        ,	COUNT(1) AS TotalTrans
	FROM Temp_Trans
    GROUP BY CreatedDate, AccountID, SubscriberID, DeviceID, Flagged;
    
    UPDATE DCS_DataWatch.TransactionLite AS tl
	INNER JOIN Temp_TotalTrans AS tmp ON 	tl.ReportDate = tmp.CreatedDate
										AND tl.AccountID = tmp.AccountID
										AND tl.SubscriberID = tmp.SubscriberID
										AND tl.DeviceID = tmp.DeviceID
										AND tl.Flagged = tmp.Flagged
	SET tl.TotalTrans = tl.TotalTrans + tmp.TotalTrans,
		tl.ModifiedTime = lv_CurrentDatetime,
		tmp.IsUpdate = 1;
    
    INSERT INTO DCS_DataWatch.TransactionLite(ReportDate, AccountID, SubscriberID, DeviceID, Flagged, TotalTrans, CreatedTime, ModifiedTime)
    SELECT 	tmp.CreatedDate AS ReportDate
		,	tmp.AccountID
        ,	tmp.SubscriberID
		,	tmp.DeviceID
        ,	tmp.Flagged
        ,	tmp.TotalTrans
        ,	lv_CurrentDatetime AS CreatedTime
        ,	lv_CurrentDatetime AS ModifiedTime
	FROM Temp_TotalTrans AS tmp
    WHERE tmp.IsUpdate = 0;

END$$
DELIMITER ;
